# Dockerfile
ARG BASE_IMAGE_VERSION=1.27.1.2-0-1-focal
# ARG OPENRESTY_VERSION=1.27.1.2
# # ARG OPENRESTY_URL=https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz
# # ARG OPENRESTY_URL=https://github.com/openresty/openresty/releases/download/v$OPENRESTY_VERSION/openresty-${OPENRESTY_VERSION}.tar.gz
# ARG LIBMAXMINDDB_VERSION=1.12.2
# # ARG LIBMAXMINDDB_URL=https://github.com/maxmind/libmaxminddb/releases/download/${LIBMAXMINDDB_VERSION}/libmaxminddb-${LIBMAXMINDDB_VERSION}.tar.gz
# ARG GEOIP2_MODULE_VERSION=3.4
# # ARG GEOIP2_MODULE_URL=https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/${GEOIP2_MODULE_VERSION}.tar.gz
FROM 1panel/openresty:$BASE_IMAGE_VERSION
## 官方仓库：https://github.eli1.top/https://github.com/openresty/openresty/releases/download/v${OPENRESTY_VERSION}/openresty-${OPENRESTY_VERSION}.tar.gz
ENV OPENRESTY_VERSION=1.27.1.2 \
    LIBMAXMINDDB_VERSION=1.12.2 \
    GEOIP2_MODULE_VERSION=3.4

RUN sed -i 's#http://archive.ubuntu.com/#https://mirrors.aliyun.com/#g' /etc/apt/sources.list \
    && apt-get update >/dev/null && apt-get install -y build-essential libpcre3-dev zlib1g-dev libssl-dev libgeoip-dev >/dev/null && apt-get upgrade -y >/dev/null&& apt-get clean all >/dev/null\
    && mkdir -p /root/addgeoip2 \
    && curl -Ls -o /root/addgeoip2/openresty.tar.gz https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz \
    && curl -Ls -o /root/addgeoip2/libmaxminddb.tar.gz https://github.eli1.top/https://github.com/maxmind/libmaxminddb/releases/download/${LIBMAXMINDDB_VERSION}/libmaxminddb-${LIBMAXMINDDB_VERSION}.tar.gz \
    && cd /root/addgeoip2 && pwd && ls -lah&& echo https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz && echo https://github.eli1.top/https://github.com/maxmind/libmaxminddb/releases/download/${LIBMAXMINDDB_VERSION}/libmaxminddb-${LIBMAXMINDDB_VERSION}.tar.gz&&tar -zvxf openresty.tar.gz && tar -zvxf libmaxminddb.tar.gz \
    && cd /root/addgeoip2/libmaxminddb-$LIBMAXMINDDB_VERSION && ./configure && make && make install && echo "/usr/local/lib" >> /etc/ld.so.conf && ldconfig \
    && curl -Ls -o /root/addgeoip2/openresty-${OPENRESTY_VERSION}/bundle/geoip2.tar.gz https://github.eli1.top/https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/${GEOIP2_MODULE_VERSION}.tar.gz \
    && cd /root/addgeoip2/openresty-${OPENRESTY_VERSION}/bundle/ && tar -zvxf geoip2.tar.gz \
    && cd /root/addgeoip2/openresty-${OPENRESTY_VERSION}/ && ./configure --with-pcre --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' --with-compat --with-file-aio --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_xslt_module=dynamic --with-ipv6 --with-mail --with-mail_ssl_module --with-md5-asm --with-sha1-asm --with-stream --with-stream_ssl_module --with-threads --add-dynamic-module=/root/addgeoip2/openresty-${OPENRESTY_VERSION}/bundle/ngx_http_geoip2_module-${GEOIP2_MODULE_VERSION} && make && make install \
    && rm -rf /root/addgeoip2
