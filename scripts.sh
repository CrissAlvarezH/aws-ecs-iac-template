set -e

action=$1

if [ "$action" = "setup-infra" ]; then
    aws cloudformation create-stack \
        --stack-name "example" \
        --template-body file://cloudformation.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        | cat

elif [ "$action" = "repo-uri" ]; then
    aws cloudformation describe-stacks \
        --stack-name example \
        --query "Stacks[0].Outputs[?OutputKey=='RepositoryUri'].OutputValue | [0]" \
        --output text \
        | cat

elif [ "$action" = "build" ]; then
    docker build --no-cache -t ecs-template .

elif [ "$action" = "deploy" ]; then
    sh scripts.sh build

    REPO_URI=$(sh scripts.sh repo-uri)
    REPO_SERVER=$(echo $REPO_URI | awk -F / '{print $1}')

    echo "REPO_URI: $REPO_URI"
    echo "REPO_SERVER: $REPO_SERVER"

    aws ecr get-login-password --region us-east-1 \
        | docker login --username AWS --password-stdin $REPO_SERVER
    docker tag ecs-template:latest $REPO_URI:latest
    docker push $REPO_URI

elif [ "$action" = "run" ]; then
    docker run --rm ecs-template

fi