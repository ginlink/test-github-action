#!/bin/sh
eval $(ssh-agent -s)

#将ssh private key 放入当前服务器，这样才可以登录远端服务器
echo "$PRIVATE_KEY" > deploy.key

mkdir -p ~/.ssh
chmod 0600 deploy.key
ssh-add deploy.key

echo "Host *\n\tStrictHostKeyChecking no\n\n" >> ~/.ssh/config

echo "[success] add private key"

scp ./sh/action_deploy_remote.sh  $REMOTE_NAME@$REMOTE_HOST:~/sh/action_deploy_remote.sh
scp ./docker-compose-example.yml  $REMOTE_NAME@$REMOTE_HOST:~/sh/docker-compose-example.yml

ssh -tt $REMOTE_NAME@$REMOTE_HOST "cd ~ && ./sh/action_deploy_remote.sh"
