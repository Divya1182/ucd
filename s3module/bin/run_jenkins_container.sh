#!/usr/bin/env bash
#attach to running container or fire up a new one
if [ "$(docker ps -q -f name=terraform-aws-s3-build)" ]; then
  docker attach terraform-aws-s3-build
else
  docker run -it --rm \
    --entrypoint="bash" \
    --name terraform-aws-s3-build \
    --env-file env.list \
    -w /opt/devops/jenkins/workspace/s3 \
    -v ${PWD}:/opt/devops/jenkins/workspace/s3:rw,z \
    registry.cigna.com/enterprise-devops/aws-d-megatainer:1.0.7
fi

# source <(plz --completion_script)