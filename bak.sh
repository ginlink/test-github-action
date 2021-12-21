
# scp file
scp ./sh/node_remote_deploy.sh root@110.42.130.99:~/sh/node_remote_deploy.sh

scp ./sh/action_rollback_remote.sh root@110.42.130.99:~/sh/action_rollback_remote.sh

scp ./docker-compose-dev.yml  root@110.42.130.99:~/sh/docker/docker-compose-dev.yml

sed -i "s/example\\/example-image:tag/ginlink\\/test-rollback:1.0.10/g" /root/sh/docker/docker-compose-dev.yml
