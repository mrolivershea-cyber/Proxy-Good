# 3proxy configuration template for instance __INSTANCE__
# This template will be populated by deploy_3proxy_endpoints.sh

auth strong
users __USER__:CL:__PASSWORD__
socks -p__PUBLIC_PORT__ -a
parent 1000 socks5 127.0.0.1 __LOCAL_SOCKS__
