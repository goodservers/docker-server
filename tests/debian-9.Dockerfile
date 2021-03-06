FROM debian:stretch

# create workdir
RUN mkdir -p /app

# set workdir
WORKDIR /app

# Copy the code
ADD . .

RUN chmod 777 /app/init_server.sh

RUN ./init_server.sh -t
