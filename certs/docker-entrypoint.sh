#!/bin/sh
set -e

DOMAIN="getorganize.app"
DOMAIN_WWW="www.$DOMAIN"
EMAIL_ADDRESS="GetOrganizeApp@gmail.com"
WEBROOT_PATH="/var/www/certbot/"
cert_dir="/etc/letsencrypt/live/$DOMAIN"
cert_file="$cert_dir/fullchain.pem"
key_file="$cert_dir/privkey.pem"

set +e
2>/dev/null openssl x509 -in $cert_file -text -noout \
  | grep -q "Issuer: CN = $DOMAIN"
if [ $? -eq 0 ]; then
  echo "WARNING: Self-signed cert found at $cert_file"
  echo "Deleting the self-signed cert..."
  rm -f $cert_file
fi
set -e

if ! [ -e $cert_file ]; then
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

  # Waiting 40 seconds because Let's Encrypt has a rate limit of 300 certificate
  # requests every 3 hours or 1 certificate request every 36 seconds
  # For more info, see "New Orders" in https://letsencrypt.org/docs/rate-limits/
  echo "Waiting for web server to restart with self-signed certs..."
  sleep 40 # This seems to be enough but may need to be raised in the future

  echo "Removing self-signed certs..."
  rm -rf $cert_dir

  echo "Running certbot to get real certs..."
  certbot certonly \
    --agree-tos \
    --domain $DOMAIN \
    --domain $DOMAIN_WWW \
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
