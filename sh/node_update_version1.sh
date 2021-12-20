#!/bin/sh
eval $(ssh-agent -s)

#将ssh private key 放入当前服务器，这样才可以登录远端服务器
echo "$PRIVATE_KEY" > deploy.key

mkdir -p ~/.ssh
chmod 0600 deploy.key
ssh-add deploy.key

echo "Host *\n\tStrictHostKeyChecking no\n\n" >> ~/.ssh/config

echo "add private key success"
echo "11111111111111111111111"

scp $REMOTE_NAME@$REMOTE_HOST:~/sh/version/version_history.txt ./version_history.txt

echo '1.0.1' >> ./version_history.txt

scp ./version_history.txt $REMOTE_NAME@$REMOTE_HOST:~/sh/version/version_history.txt