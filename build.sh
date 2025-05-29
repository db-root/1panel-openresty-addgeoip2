#!/bin/bash

# 读取 .env 文件
set -a
source .env
set +a

# # 构建参数转换为 --build-arg
# ARGS=()
# for var in $(grep -v '^#' .env | cut -d '=' -f1); do
#   ARGS+=("--build-arg" "$var=${!var}")
# done

# 执行构建
# docker build "${ARGS[@]}" -t  bin12121/1panel-openresty-addgeoip2:$BASE_IMAGE_VERSION .
docker build -t  bin12121/1panel-openresty-addgeoip2:$BASE_IMAGE_VERSION .
if [ $? -eq 0 ]; then
  # docker tag bin12121/1panel-openresty-addgeoip2:"$BASE_IMAGE_VERSION" bin12121/1panel-openresty-addgeoip2:latest
  docker push bin12121/1panel-openresty-addgeoip2:"$BASE_IMAGE_VERSION"
  # docker push bin12121/1panel-openresty-addgeoip2:latest
else
  echo "Build failed. Skipping push."
fi