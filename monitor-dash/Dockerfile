# check=skip=SecretsUsedInArgOrEnv

FROM grafana/grafana-oss:12.4.2

ENV GF_AUTH_ANONYMOUS_ENABLED="true" \
  GF_AUTH_ANONYMOUS_ORG_ROLE="Admin" \
  GF_AUTH_DISABLE_LOGIN_FORM="true"

COPY provisioning /etc/grafana/provisioning
