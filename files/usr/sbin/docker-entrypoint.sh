#!/bin/sh -e

TZ="${TZ:-UTC}"

# set the timezone
if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  cp "/usr/share/zoneinfo/$TZ" /etc/localtime
  echo "$TZ" >/etc/timezone
fi


# set default parameters
FTP_ROOT="${FTP_ROOT:-/srv/ftp}"
FTP_USER_NAME="${FTP_USER_NAME:-admin}"
FTP_USER_UID="${FTP_USER_UID:-999}"
PASV_ADDRESS="${PASV_ADDRESS:-$(ip route | awk '/default/ { print $3; exit }')}"
CERT_FILE="${CERT_FILE:-/etc/vsftpd/ssl/cert.pem}"
CERT_KEY_FILE="${CERT_KEY_FILE:-/etc/vsftpd/ssl/key.pem}"

if [ -z "${FTP_USER_PASS}" ]; then
  FTP_USER_PASS="$(tr -dc A-Z-a-z-0-9 </dev/urandom | head -c 20)"
  echo "Using generated password for FTP user ${FTP_USER_NAME}: ${FTP_USER_PASS}" >&2
fi

# create the user if it does not exists
getent passwd "${FTP_USER_NAME}" >/dev/null \
  || adduser -u "${FTP_USER_UID}" -h /srv/ftp \
       -D -s /sbin/nologin -G ftp -g "FTP user" ${FTP_USER_NAME}

# set the user password
echo "${FTP_USER_NAME}:${FTP_USER_PASS}" | chpasswd


if [ "${LOG_FILE}" == '/dev/stdout' ]; then
  LOG_FILE="/var/log/stdout.txt"
  touch "${LOG_FILE}"
  tail -F -n 0 "${LOG_FILE}" &
fi    

cat >> /etc/vsftpd/vsftpd.conf <<-EOF
allow_anon_ssl=${ALLOW_ANON:-NO}
anonymous_enable=${ALLOW_ANON:-NO}
file_open_mode=${FILE_OPEN_MODE:-0666}
local_umask=${LOCAL_UMASK:-022}
pasv_addr_resolve=${PASV_ADDR_RESOLVE:-NO}
pasv_address=${PASV_ADDRESS}
pasv_enable=${PASV_ENABLE:-YES}
pasv_max_port=${PASV_MAX_PORT:-21100}
pasv_min_port=${PASV_MIN_PORT:-21100}
rsa_cert_file=${CERT_FILE}
rsa_private_key_file=${CERT_KEY_FILE}
use_localtime=${USE_LOCALTIME:-YES}
vsftpd_log_file=${LOG_FILE}
write_enable=${WRITE_ENABLE:-YES}
EOF


if [ ! -f ${CERT_FILE} -o ! -f ${CERT_KEY_FILE} ]; then
  echo "generating certificate"
  openssl req -x509 -nodes -days 365 -newkey rsa:${CERT_KEY_SIZE:-4096} \
    -keyout "${CERT_KEY_FILE}" -out "${CERT_FILE}" \
    -subj "/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_LOCALITY}/O=${CERT_ORGA}/OU=${CERT_ORGA_UNIT}/CN=${CERT_CN:-${PASV_ADDRESS}}/emailAddress=${CERT_MAIL}/"
fi


# do not use exec... vsftpd will hang
$*
