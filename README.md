# Docker Gateway installation script
Setup: `wget https://gitlab.com/tomwagner/init-docker-server/raw/master/init_server.sh -O init_server.sh; chmod 700 ./init_server.sh;./init_server.sh;`

# Supported OS
* Debian 9.5
* Ubuntu latest

## Info
Simple docker and docker compose gateway for any kind of docker application. Automatic handles domains, letsencrypt certificates, nginx settings and containers health. No setup needed. Gateway consists of from 4 containers:
* [nginx reverse proxy](https://github.com/jwilder/nginx-proxy),
* [nginx settings generator](https://github.com/jwilder/docker-gen),
* [letsencrypt certificates handler](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion)
* [container health checker - zero downtime deployment](https://github.com/goodservers/docker-doctor).
