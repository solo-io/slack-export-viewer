FROM python:3.9.16-alpine
RUN pip install awscli
ADD requirements-freeze.txt .
RUN pip install -r requirements-freeze.txt
ADD . /slack-export-viewer
WORKDIR /slack-export-viewer
