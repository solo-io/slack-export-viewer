FROM python:3.9.0-alpine3.12
RUN pip install click flask emoji markdown2 awscli meilisearch
ADD . /slack-export-viewer
WORKDIR /slack-export-viewer
