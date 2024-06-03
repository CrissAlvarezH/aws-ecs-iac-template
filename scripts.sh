set -e
PROJECT_NAME="ecs-example"

action=$1

if [ "$action" = "setup-infra" ]; then
    aws cloudformation create-stack \
        --stack-name $PROJECT_NAME-stack \
        --template-body file://cloudformation.yaml \
        --parameters ParameterKey=LambdaName,ParameterValue="$LAMBDA_NAME" ParameterKey=CronExecutionExpression,ParameterValue="$CRON_EXECUTION_EXPRESSION" \
        --capabilities CAPABILITY_NAMED_IAM \
        | cat

elif [ "$action" = "update-infra" ]; then
    aws cloudformation update-stack \
        --stack-name $PROJECT_NAME-stack \
        --template-body file://cloudformation.yaml \
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
    docker build --no-cache -t $PROJECT_NAME .

elif [ "$action" = "deploy" ]; then
    sh scripts.sh build

    REPO_URI=$(sh scripts.sh repo-uri)
    REPO_SERVER=$(echo $REPO_URI | awk -F / '{print $1}')

    echo "REPO_URI: $REPO_URI"
    echo "REPO_SERVER: $REPO_SERVER"

    aws ecr get-login-password --region us-east-1 \
        | docker login --username AWS --password-stdin $REPO_SERVER

    # TODO create tag with last commit hash
    docker tag $PROJECT_NAME:latest $REPO_URI:latest
    docker push $REPO_URI

elif [ "$action" = "run" ]; then
    docker run --rm $PROJECT_NAME

fi