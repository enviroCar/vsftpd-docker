FROM alpine:latest

ARG VSFTPD_VERSION=3.0.3-r6
ARG BUILD_DATE
ARG GIT_REVISION

LABEL maintainer="Christian Autermann <c.autermann@52north.org>" \
      org.opencontainers.image.authors="Christian Autermann <c.autermann@52north.org>" \
      org.opencontainers.image.url="https://github.com/enviroCar/vsftpd-docker" \
      org.opencontainers.image.source="https://github.com/enviroCar/vsftpd-docker.git" \
      org.opencontainers.image.version="${VSFTPD_VERSION}" \
      org.opencontainers.image.vendor="52°North GmbH" \
      org.opencontainers.image.description="vsftpd docker image." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.revision="${GIT_REVISION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.documentation="docker run -d -p [HOST PORT NUMBER]:21 -v [HOST FTP HOME]:/home/vsftpd vsftpd" 


RUN set -ex \
 && apk add --update --no-cache \
      iproute2 \
      openssl \
      tzdata  \
      vsftpd=${VSFTPD_VERSION}\
 && install -o ftp -g ftp -d /srv/ftp

# ftp settings
ENV FTP_USER_NAME=admin \
    FTP_USER_PASS= \
    FTP_USER_UID=999 \
    PASV_ADDRESS= \
    PASV_ADDR_RESOLVE=NO \
    PASV_ENABLE=YES \
    PASV_MIN_PORT=21100 \
    PASV_MAX_PORT=21110 \
    FILE_OPEN_MODE=0666 \
    LOCAL_UMASK=022 \
    ALLOW_ANON=NO \
    WRITE_ENABLE=YES \
    LOG_FILE=/dev/stdout \
    TZ=UTC \
    USE_LOCALTIME=YES

# certificate settings
ENV CERT_FILE=/etc/vsftpd/ssl/cert.pem \
    CERT_KEY_FILE=/etc/vsftpd/ssl/key.pem \
    CERT_KEY_SIZE=4096 \
    CERT_COUNTRY= \
    CERT_STATE= \
    CERT_LOCALITY= \
    CERT_ORGA= \
    CERT_ORGA_UNIT= \
    CERT_CN= \
    CERT_MAIL=

COPY files /

# data of the ftp daemon
VOLUME /var/lib/ftp 

# generated certificates
VOLUME /etc/vsftpd/ssl

# ftp data
VOLUME /srv/ftp

# standard ports
EXPOSE 20 21

# passive port range
EXPOSE $PASV_MIN_PORT-$PASV_MAX_PORT

# the script create the settings, user and certificate
ENTRYPOINT [ "/usr/sbin/docker-entrypoint.sh" ]

# default to start the FTP service
CMD [ "vsftpd", "/etc/vsftpd/vsftpd.conf" ]