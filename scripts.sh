set -e

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

function read_env_var() {
    name=$1
    echo "$(cat .env.infra | grep $name | awk -F \= '{print $2}' | sed 's/"//g')"
}

PROJECT_NAME=$(read_env_var "PROJECT_NAME")
CRON_EXECUTION_EXPRESSION=$(read_env_var "CRON_EXECUTION_EXPRESSION")
SUBNET_IDS=$(read_env_var "SUBNET_IDS")

action=$1

if [ "$action" = "setup-infra" ]; then
    log "PROJECT_NAME=$PROJECT_NAME"
    log "CRON_EXECUTION_EXPRESSION=$CRON_EXECUTION_EXPRESSION"
    log "SUBNET_IDS=$SUBNET_IDS"

    log "uploading .env.app in s3 bucket"

    env_file_arn=$(sh scripts.sh upload-env)

    log "env file arn: $env_file_arn"

    aws cloudformation create-stack \
        --stack-name $PROJECT_NAME-stack \
        --template-body file://cloudformation.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
            ParameterKey=SubnetIds,ParameterValue="$SUBNET_IDS" \
            ParameterKey=CronExecutionExpression,ParameterValue="$CRON_EXECUTION_EXPRESSION" \
            ParameterKey=EnvFileS3Arn,ParameterValue="$env_file_arn" \
        --capabilities CAPABILITY_NAMED_IAM \
        | cat

elif [ "$action" = "update-infra" ]; then
    log "uploading .env.app in s3 bucket"

    env_file_arn=$(sh scripts.sh upload-env)

    log "env file arn: $env_file_arn"

    aws cloudformation update-stack \
        --stack-name $PROJECT_NAME-stack \
        --template-body file://cloudformation.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
            ParameterKey=SubnetIds,ParameterValue="$SUBNET_IDS" \
            ParameterKey=CronExecutionExpression,ParameterValue="$CRON_EXECUTION_EXPRESSION" \
            ParameterKey=EnvFileS3Arn,ParameterValue="$env_file_arn" \
        --capabilities CAPABILITY_NAMED_IAM \
        | cat

elif [ "$action" = "delete-ecr-img" ]; then
    # TODO delete all images in repository

    aws ecr batch-delete-image \
        --repository-name "$PROJECT_NAME-repo" \
        --image-ids "imageTag=latest" \
        | cat

elif [ "$action" = "delete-infra" ]; then
    sh scripts.sh delete-ecr-img

    aws cloudformation delete-stack \
        --stack-name $PROJECT_NAME-stack \
        | cat

    bucket="$PROJECT_NAME-env-file-bucket"

    aws s3 rm s3://$bucket/.env \
        | cat

    aws s3api delete-bucket \
        --bucket $bucket \
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

    log "pushed image: $REPO_URI:latest"
    log "pushed image: $REPO_URI:$commit"

elif [ "$action" = "upload-env" ]; then
    bucket="$PROJECT_NAME-env-file-bucket"

    # if the bucket is already created it doens't have 
    # any problem, it just does nothing
    aws s3api create-bucket \
        --bucket $bucket \
        > /dev/null

    # if .env.app file does not exists it will be create because
    # it's necessary to the cloudformation template
    [ ! -f .env.app ] && touch .env.app

    aws s3 cp .env.app s3://$bucket/.env > /dev/null

    # WARNING: this arn s3 object structure is following this:
    # arn:PARTITION:s3:::NAME-OF-YOUR-BUCKET
    # where PARTITION is 'aws', 'aws-us-gov' o 'aws-cn' depending
    # on whether you're in general aws, GovCloud or Chine respectively.
    # so if you are in a diferent partition just change de arn structure
    echo "arn:aws:s3:::$bucket/.env"

elif [ "$action" = "run" ]; then
    docker run --rm $PROJECT_NAME

else 
    log "action '$action' not found" "warn"
    exit 1
fi
