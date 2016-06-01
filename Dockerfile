FROM alpine:latest

RUN apk update
RUN apk add bash build-base wget vim openssl openssl-dev pcre pcre-dev perl \
                git unzip libuuid util-linux-dev dnsmasq
RUN mkdir -p /root/source && mkdir /opt && mkdir /kong
ENV PATH="/opt/luajit/bin:/opt/luarocks/bin:/opt/openresty/bin:/opt/openresty/nginx/sbin/:$PATH"

RUN cd /root/source && wget http://luajit.org/download/LuaJIT-2.1.0-beta2.tar.gz && \
        tar -xzf LuaJIT-*.tar.gz && \
        cd LuaJIT-* && \
        make PREFIX=/opt/luajit && \
        make install PREFIX=/opt/luajit

RUN ln -sf /opt/luajit/bin/luajit-2.1.0-beta2 /opt/luajit/bin/luajit && \
        ln -s /opt/luajit/include/luajit-*/* /opt/luajit/include/

RUN cd /root/source && wget http://keplerproject.github.io/luarocks/releases/luarocks-2.3.0.tar.gz && \
        tar -xzf luarocks-*.tar.gz && \
        cd luarocks-* && \
        ./configure --prefix=/opt/luarocks --sysconfdir=/kong/etc/luarocks --lua-suffix=jit --with-lua=/opt/luajit --force-config && \
        make build && \
        make install

RUN cd /root/source && wget https://openresty.org/download/openresty-1.9.7.4.tar.gz && \
        tar -xzf openresty-*.tar.gz && \
        cd openresty-* && \
        ./configure --prefix=/opt/openresty \
                --with-luajit=/opt/luajit \
                --with-pcre-jit \
                --with-ipv6 \
                --with-http_realip_module \
                --with-http_ssl_module \
                --with-http_stub_status_module \
                --conf-path=/kong/etc/nginx/nginx.conf \
                --error-log-path=/kong/logs/openresty.log \
                --pid-path=/kong/run/openresty.pid \
                --lock-path=/kong/run/openresty.lock \
                --http-log-path=/kong/logs/ \
                --http-client-body-temp-path=/kong/temp/http-client-body \
                --http-proxy-temp-path=/kong/temp/proxy \
                --http-fastcgi-temp-path=/kong/temp/fastcgi \
                --http-uwsgi-temp-path=/kong/temp/uwsgi \
                --http-scgi-temp-path=/kong/temp/scgi \
        && \
        make && \
        make install

RUN luarocks install kong

RUN sed -i 's#/etc/kong/#/kong/etc/#g' /opt/luarocks/share/lua/5.1/kong/constants.lua
ADD root/kong.yml /kong/etc/kong.yml

RUN echo -e "\n\nuser=root\n" >> /etc/dnsmasq.conf
RUN cd /root/source && wget https://releases.hashicorp.com/serf/0.7.0/serf_0.7.0_linux_amd64.zip && \
        unzip serf_*.zip && \
        cp -p serf /usr/local/bin/serf

RUN mkdir /kong/temp

ENV LUA_PATH='/opt/luarocks/share/lua/5.1/?.lua;/opt/luarocks/share/lua/5.1/?/init.lua;./?.lua;/opt/luajit/share/luajit-2.1.0-beta2/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/opt/luajit/share/lua/5.1/?.lua;/opt/luajit/share/lua/5.1/?/init.lua'
ENV LUA_CPATH='/opt/luarocks/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/opt/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so'

# Proxy ports
EXPOSE 8000:8000
EXPOSE 8443:8443

# Kong API port
EXPOSE 8001:8001

# serfdom ports
EXPOSE 7946:7946
EXPOSE 7946:7946/udp

RUN rm -rf /root/source

CMD kong start
