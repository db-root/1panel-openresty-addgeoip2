---
title: "1panel/openresty编译添加geoip2模块支持"
subitile: "1panel/openresty编译添加geoip2模块支持"
date: 2025-01-06T2:53:44+08:00
draft: false
categories: ["开源系列分享","建站相关"]
tags: ["开源","建站","nginx","1Panel","OpenResyt"]
slug: 1panel-openresty-addgeoip2-module
image: "https://typora.elisky.cn/typora/img/image-20250106025848398.png"
---
# 1panel/openresty编译添加geoip2模块支持

> 声明：该文档仅供学习讨论开源知识分享，不涉及任何商业利益。
>
> 若有侵权请联系[Eli](mailto:eli_luck@163.com)删除
>
> 转载请声明来源

基于1panel/openresty:1.21.4.3-3-3-focal镜像二次编译添加geoip2模块支持

废话：

之前使用的nginx-plus有对geoip2的支持，最近更换服务器，不希望折腾命令行，暂时也没有找到好用的nginx控制台，所以选择了1panel简单省事（主要看上了1panel的全容器化）。

但是1panel的网站管理只能使用openresty，之前从未用过，不过基于对新事物的热忱还是试用了一下。之前网站架构有集成geoip2来限制访问地区，以及查看访问日志等功能，1panel的openresty竟然没有geoip2模块，查看了下1panel的官方论坛，很潦草，只有一个回答：”有需要可以自己编译“，然后在帖子下面留了言，几天没有得到回复。名帖可以查看：[应用商店的openresty能否再安装geoip2模块 - 1Panel - 社区论坛 - FIT2CLOUD 飞致云](https://bbs.fit2cloud.com/t/topic/5924/7)

无奈，只能开源精神开源处理

## 编译准备

环境：

1panel版本：v1.10.22-lts

openresty版本：1.21.4.3-3-3-focal

前期准备：

使用1panel面板搭建的openresty之后可以使用命令 `docker inspect 1panel/openresty:1.21.4.3-3-3-focal` 查看下镜像之前的模块信息![image-20250106021351639](https://typora.elisky.cn/typora/img/image-20250106021351639.png)

可以复制”resty_config_options“参数做备用。

## 编译

从1panel官方仓库以及论坛没有找到他们镜像打包用到的Dockerfile，查看镜像内也没有找到打包用到的configure文件，所以只能依据1panel/openresty 镜像进行打包了

### 打包分析：

首先确认一点，打包时不能忽略原有的模块参数（之前尝试使用openresty官方的打包镜像替换到1panel，很遗憾报错了），在原有基础之上加入GeoIP2模块，同时GeoIP2模块依赖于libmaxminddb，所以也是需要打入包内的，有了以上分析就可以开始写Dockerfile了。

打包时，可能会因为网络问题导致curl GitHub相关文件时失败，错误代码为：35，如下图所示（可能是我的代理和本地网络问题，切换了之后没有这个问题了）

![image-20250106022143794](https://typora.elisky.cn/typora/img/image-20250106022143794.png)



### Dockerfile

如下图所示，可以将dockerfile内容另存一个新的文件，命名为：Dockerfile，之后使用命令：`docker build -t imagename:tag` 进行打包，文件中没有依赖文件夹，只有网络文件，所以无需准备提前环境。

```dockerfile
FROM 1panel/openresty:1.21.4.3-3-3-focal
## 官方仓库：https://github.com/openresty/openresty/releases/download/v1.21.4.3/openresty-1.21.4.3.tar.gz
RUN mkdir -p /root/addgeoip2 \
    && curl -L -o /root/addgeoip2/openresty-1.21.4.3.tar.gz https://github.com/openresty/openresty/releases/download/v1.21.4.3/openresty-1.21.4.3.tar.gz \
    && curl -L -o /root/addgeoip2/libmaxminddb-1.7.1.tar.gz https://github.com/maxmind/libmaxminddb/releases/download/1.7.1/libmaxminddb-1.7.1.tar.gz \
    && cd /root/addgeoip2 && tar -vxf openresty-1.21.4.3.tar.gz && tar -vxf libmaxminddb-1.7.1.tar.gz \
    && cd /root/addgeoip2/libmaxminddb-1.7.1 && ./configure && make && make install && echo "/usr/local/lib" >> /etc/ld.so.conf && ldconfig \
    && curl -L -o /root/addgeoip2/openresty-1.21.4.3/bundle/3.4.tar.gz https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/3.4.tar.gz \
    && cd /root/addgeoip2/openresty-1.21.4.3/bundle/ && tar -vxf 3.4.tar.gz \
    && cd /root/addgeoip2/openresty-1.21.4.3/ && ./configure --with-pcre --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' --with-compat --with-file-aio --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_xslt_module=dynamic --with-ipv6 --with-mail --with-mail_ssl_module --with-md5-asm --with-sha1-asm --with-stream --with-stream_ssl_module --with-threads --add-dynamic-module=/root/addgeoip2/openresty-1.21.4.3/bundle/ngx_http_geoip2_module-3.4 && make && make install
```



耐心的等待构建结束，大约需要2-3分钟（所需时间根据网络和服务器性能不同可能有所不同）

![image-20250106022435439](https://typora.elisky.cn/typora/img/image-20250106022435439.png)

出现提示：naming to docker.io/library/xxxxxx:tag 则是打包成功了

## 集成更换

做好镜像之后可以直接替换到1panel中，若是1panel服务器打包的话，可以忽略镜像传输过程，直接替换即可

复制打包完成的镜像名称，我这里是 1panel-openresty-addgeoip:v0.2 ，如下图所示

![image-20250106022723861](https://typora.elisky.cn/typora/img/image-20250106022723861.png)

复制备份

登录1Panel控制台，点击左侧的【容器】-【编排】-【编辑】

![image-20250106023129248](https://typora.elisky.cn/typora/img/image-20250106023129248.png)

然后修改image参数，并在valumes参数下添加一行关于geoip2的文件路径，如下图所示（我这里挂在到容器内的路径为：/usr/local/openresty/geoip2，这个路径要记住后续需要使用），编辑完成之后点击确认

![image-20250106023418544](https://typora.elisky.cn/typora/img/image-20250106023418544.png)

切换回容器页面，查看容器状态是否是运行中，如下图所示：

![image-20250106023540613](https://typora.elisky.cn/typora/img/image-20250106023540613.png)



这样替换就已经可以集成完成了，可以做一个简单的测试

## 结果测试

添加GeoIP2数据库：略，后续添加步骤

### 修改默认配置文件

在网站管理页面点击【设置】-【配置修改】，可以手动编辑添加相关配置，如下所示：

![image-20250106023818970](https://typora.elisky.cn/typora/img/image-20250106023818970.png)

```nginx
user  root;
worker_processes  auto;
error_log  /var/log/nginx/error.log notice;
error_log  /dev/stdout notice;
pid        /var/run/nginx.pid;
## 增加load_module参数，用于加载geoip2模块
load_module /usr/local/openresty/nginx/modules/ngx_http_geoip2_module.so;
load_module /usr/local/openresty/nginx/modules/ngx_stream_geoip2_module.so;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    ## 新增json日志格式用于后期集成loki或ELK，不用的话不影响配置
    log_format json escape=json '{'
					'"time_local": "$time_local", '
                    '"remote_addr": "$remote_addr", '
                    '"request_uri": "$request_uri", '
                    '"request_length": "$request_length", '
                    '"request_time": "$request_time", '
                    '"request_method": "$request_method", '                   
                    '"status": "$status", '
                    '"body_bytes_sent": "$body_bytes_sent", '
                    '"http_referer": "$http_referer", '
                    '"http_user_agent": "$http_user_agent", '
                    '"http_x_forwarded_for": "$http_x_forwarded_for", '
                    '"http_host": "$http_host", '
                    '"server_name": "$server_name", '
                    '"upstream": "$upstream_addr", '
                    '"upstream_response_time": "$upstream_response_time", '
                    '"upstream_status": "$upstream_status", '
                    '"geoip_country_code": "$geoip2_data_country_code", '
                    '"geoip_country_name": "$geoip2_data_country_name", '
                    '"geoip_city_name": "$geoip2_data_city_name"'
                    '}';
    server_tokens off;
    access_log  /var/log/nginx/access.log  main;
    access_log /dev/stdout main;
    sendfile        on;

    server_names_hash_bucket_size 512;
    client_header_buffer_size 32k;
    client_max_body_size 50m;
    keepalive_timeout 60;
    keepalive_requests 100000;

    gzip on;
    gzip_min_length  1k;
    gzip_buffers     4 16k;
    gzip_http_version 1.1;
    gzip_comp_level 2;
    gzip_types     text/plain application/javascript application/x-javascript text/javascript text/css application/xml;
    gzip_vary on;
    gzip_proxied   expired no-cache no-store private auth;
    gzip_disable   "MSIE [1-6]\.";

    limit_conn_zone $binary_remote_addr zone=perip:10m;
    limit_conn_zone $server_name zone=perserver:10m;
    ## 增加GeoIP2的数据库
    geoip2 /usr/local/openresty/geoip2/GeoLite2-City.mmdb {
        	auto_reload 5m;
			$geoip2_metadata_country_build metadata build_epoch;
        	$geoip2_data_country_code source=$remote_addr country iso_code; #字符显示国家
	        $geoip2_data_city_name source=$remote_addr city names zh-CN; #中文显示城市名
	        $geoip2_data_country_name source=$remote_addr country names zh-CN; #中文显示国家名
    }

    include /usr/local/openresty/nginx/conf/conf.d/*.conf;
    include /usr/local/openresty/1pwaf/data/conf/waf.conf;
}
```



添加完成之后点击保存，服务将会自动重新加载

![image-20250106023911690](https://typora.elisky.cn/typora/img/image-20250106023911690.png)

### 创建网站测试

我这里创建了一个测试网站，创建步骤没有什么特别的，重点在于创建好之后更改配置

![image-20250106023726194](https://typora.elisky.cn/typora/img/image-20250106023726194.png)

点击创建好的网站点击配置：

将之前的access_log参数后的main更改为json，应用之前的日志模板

![image-20250106024706926](https://typora.elisky.cn/typora/img/image-20250106024706926.png)

更改之后点击保存并重新加载

### 访问测试

我这里直接使用了公网IPv6访问，你们测试可以使用公网服务器测试，结果如下：

![image-20250106024913257](https://typora.elisky.cn/typora/img/image-20250106024913257.png)

可以查看到已经在日志中明确可以查看到有识别到访问来源

![image-20250106024938240](https://typora.elisky.cn/typora/img/image-20250106024938240.png)



完结撒花



> 相关参考：
>
> [Nginx GeoIP2 module仓库](https://github.com/leev/ngx_http_geoip2_module)
>
> [Openresyt官方仓库](https://github.com/openresty/openresty/releases/tag/v1.21.4.3)
>
> [maxmind/libmaxminddb仓库](https://github.com/maxmind/libmaxminddb)



