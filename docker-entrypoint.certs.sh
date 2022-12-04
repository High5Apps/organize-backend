#!/bin/sh
set -e

DOMAIN="getorganize.app"
EMAIL_ADDRESS="high5apps@gmail.com"
WEBROOT_PATH="/var/www/certbot/"
cert_dir="/etc/letsencrypt/live/$DOMAIN"
cert_file="$cert_dir/fullchain.pem"
key_file="$cert_dir/privkey.pem"

if ! [ -e $cert_file ] || [ "$SELF_SIGN" = true ]; then
  echo "Making a temporary self-signed certificate because nginx expects a cert"
  mkdir -p $cert_dir
  openssl req \
    -x509 \
    -newkey rsa:4096 \
    -sha256 \
    -nodes \
    -keyout $key_file \
    -out $cert_file \
    -subj "/CN=$DOMAIN" \
    -days 1

  if [ "$SELF_SIGN" = true ]; then
    exit 0
  fi

  echo "Waiting for web server to restart with self-signed certs..."
  sleep 10 # This seems to be enough but may need to be raised in the future

  echo "Removing self-signed certs..."
  rm -rf $cert_dir

  echo "Running certbot to get real certs..."
  certbot certonly \
    --agree-tos \
    --domain $DOMAIN \
    --email ${EMAIL_ADDRESS} \
    --non-interactive \
    --renew-by-default \
    --webroot \
    --webroot-path ${WEBROOT_PATH}
fi

trap exit TERM
while true; do
  echo "Waiting 24h until next renewal attempt..."
  sleep 24h &
  wait ${!}
  echo "Running certbot renew..."
  certbot renew
done
