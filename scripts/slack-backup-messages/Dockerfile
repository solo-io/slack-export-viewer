FROM python:3.9.0-alpine3.12
RUN pip install awscli
RUN apk update
RUN apk add --update curl jq bash && \
    rm -rf /var/cache/apk/*
COPY * /
RUN chmod +x /run.sh
RUN chmod +x /run-corp.sh
RUN chmod +x /run-public.sh
RUN chmod +x /combine-backups.sh
