FROM alpine:3.17

RUN apk add --no-cache bash aws-cli mysql-client doctl jq curl mariadb-connector-c-dev gzip \
    && wget -P / https://raw.githubusercontent.com/programic/bash-common/main/common.sh

COPY pipe /

RUN chmod a+x /*.sh

ENTRYPOINT ["/pipe.sh"]