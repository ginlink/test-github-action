
#删除原有镜像
docker rmi -f ginlink/test-rollback:dev
docker rmi -f coinflow/convert-dashboard-web:dev

#拉取服务器容器并启动
docker-compose  -f  docker-compose-dev.yml pull
docker-compose -f docker-compose-dev.yml down
docker-compose -f docker-compose-dev.yml up -d
