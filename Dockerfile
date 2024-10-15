FROM python:3.9-slim-buster
RUN pip install awscli
ADD requirements-freeze.txt .
RUN pip install --no-cache-dir -r requirements-freeze.txt
ADD . /slack-export-viewer
WORKDIR /slack-export-viewer
