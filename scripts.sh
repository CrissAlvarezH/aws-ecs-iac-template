set -e

PROJECT_NAME="ecs-example"
CRON_EXECUTION_EXPRESSION="*/15 * * * ? *"
SUBNET_IDS="subnet-0960a7245ae53828e\,subnet-0bc8639c51c251489\,subnet-05de9ebbb19c04a7b\,subnet-0041d932d16af8ae6\,subnet-06a9d5ebfeeb6274d\,subnet-0b347f25cc5e1a05a"

action=$1

function latest_commit() {
    echo "$(git log --oneline -1 | awk '{print $1}')"
}

function log() {
  GREEN='\033[0;32m'
  YELLOW="\033[0;33m"
  COLOR_OFF="\033[0m"

  if [ "$2" = "warn" ]; then
    color="$YELLOW"
  else
    color="$GREEN"
  fi

  printf "\n${color}$1${COLOR_OFF}\n"
}

if [ "$action" = "setup-infra" ]; then
    aws cloudformation create-stack \
        --stack-name $PROJECT_NAME-stack \
        --template-body file://cloudformation.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
            ParameterKey=SubnetIds,ParameterValue="$SUBNET_IDS" \
            ParameterKey=CronExecutionExpression,ParameterValue="$CRON_EXECUTION_EXPRESSION" \
        --capabilities CAPABILITY_NAMED_IAM \
        | cat

elif [ "$action" = "update-infra" ]; then
    aws cloudformation update-stack \
        --stack-name $PROJECT_NAME-stack \
        --template-body file://cloudformation.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
            ParameterKey=SubnetIds,ParameterValue="$SUBNET_IDS" \
            ParameterKey=CronExecutionExpression,ParameterValue="$CRON_EXECUTION_EXPRESSION" \
        --capabilities CAPABILITY_NAMED_IAM \
        | cat

elif [ "$action" = "delete-ecr-img" ]; then
    aws ecr batch-delete-image \
        --repository-name "$PROJECT_NAME-repo" \
        --image-ids "imageTag=latest" \
        | cat

elif [ "$action" = "delete-infra" ]; then
    sh scripts.sh delete-ecr-img

    aws cloudformation delete-stack \
        --stack-name $PROJECT_NAME-stack \
        | cat

elif [ "$action" = "repo-uri" ]; then
    aws cloudformation describe-stacks \
        --stack-name $PROJECT_NAME-stack \
        --query "Stacks[0].Outputs[?OutputKey=='RepositoryUri'].OutputValue | [0]" \
        --output text \
        | cat

elif [ "$action" = "build" ]; then
    if [ $2 == "no-cache" ]; then
        docker build --no-cache -t $PROJECT_NAME .
    else
        docker build -t $PROJECT_NAME .
    fi

elif [ "$action" = "default-subnets" ]; then
    vpc=$(
        aws ec2 describe-vpcs \
        --filters Name=isDefault,Values=true \
        --query "Vpcs[0].VpcId" \
        --output text \
    )

    log "default vpc = $vpc"

    # replace tabs by \, because it's the valid way to pass a 
    # param value in cloudformation cli for 'setup-infra' command
    aws ec2 describe-subnets \
        --filters "Name=vpcId,Values=$vpc" \
        --query "Subnets[*].SubnetId" \
        --output text \
        | sed "s/\t/\\\,/g"

elif [ "$action" = "deploy" ]; then
    sh scripts.sh build no-cache

    REPO_URI=$(sh scripts.sh repo-uri)
    REPO_SERVER=$(echo $REPO_URI | awk -F / '{print $1}')

    log "REPO_URI: $REPO_URI"
    log "REPO_SERVER: $REPO_SERVER"

    aws ecr get-login-password --region us-east-1 \
        | docker login --username AWS --password-stdin $REPO_SERVER

    commit=$(latest_commit)

    docker tag $PROJECT_NAME:latest $REPO_URI:latest
    docker tag $PROJECT_NAME:latest "$REPO_URI:$commit"
    docker push "$REPO_URI:latest"
    docker push "$REPO_URI:$commit"

elif [ "$action" = "run" ]; then
    docker run --rm $PROJECT_NAME

else 
    log "action '$action' not found" "warn"
    exit 1
fi
