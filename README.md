# Docker Gateway installation script
`bash <(wget -o /dev/null --no-check-certificate -O - https://raw.githubusercontent.com/goodservers/docker-server/master/init_server.sh)`

# Supported OS
* Debian 10 (buster), LTS 9 (strech), 8 (jessie)
* Ubuntu 19.04 (disco), LTS 18.04 (bionic), 16.04 (xenial),

## Info
Simple docker and docker compose gateway for any kind of docker application. Automatic handles domains, letsencrypt certificates, nginx settings and containers health. No setup needed. Gateway consists of from 4 containers:
* [nginx reverse proxy](https://github.com/jwilder/nginx-proxy),
* [nginx settings generator](https://github.com/jwilder/docker-gen),
* [letsencrypt certificates handler](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion)
* [container health checker - zero downtime deployment](https://github.com/goodservers/docker-doctor).
