set -e

action=$1

if [ "$action" = "build" ]; then
    docker build -t ecs-template .

elif [ "$action" = "run" ]; then
    docker run --rm ecs-template

fi