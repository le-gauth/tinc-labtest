FROM debian:stable

RUN apt-get update 
RUN apt-get install -y tinc iproute2

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]