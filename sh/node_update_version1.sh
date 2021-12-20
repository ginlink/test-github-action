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

# ssh $REMOTE_NAME@$REMOTE_HOST

# mkdir -p ./sh/version
# localpath=~/sh/version/version_history.txt
localpath=./version_history.txt
remotepath=~/sh/version/version_history.txt

# scp $REMOTE_NAME@$REMOTE_HOST:$remotepath ./version_history.txt
scp $REMOTE_NAME@$REMOTE_HOST:~/sh/version/version_history.txt ./version_history.txt

cat ./version_history.txt
# sed -i '$a\"$RELEASE_VERSION"' ./sh/version/version_history.txt

# echo $RELEASE_VERSION >> $localpath

# scp $localpath $REMOTE_NAME@$REMOTE_HOST:$remotepath

