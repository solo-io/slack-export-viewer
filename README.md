# Solo's - Slack Export Viewer

Is a fork of [hfaran/slack-export-viewer](https://kandi.openweaver.com/python/hfaran/slack-export-viewer), for informations on how its pieces work check its readme.

## Our modifications

We added: 
- Search capabilities, by adding indexing via meilisearch.
- Go to message, after searching an message.

## How to run

1. Run meilisearch:
```
docker run -it --rm -p 7700:7700 getmeili/meilisearch:latest
```

2. Download latest backup from: https://s3.console.aws.amazon.com/s3/object/solo-slack?region=eu-west-1&prefix=slack.tgz

3. Upack it to any dir
```
tar -xvf ~/Downloads/slack.tgz -C /tmp/
```

4. Load data into meilisearch
```
pip install -r requirements.txt
python3 synctomeili.py -d /tmp/slack -m http://localhost:7700
```

To checkout meili data open [http://localhost:7700](http://localhost:7700)

5. Run the application
```
python3 app.py -z /tmp/slack -p 8089 -m http://localhost:7700
```

To checkout the slack-viewer open [http://localhost:8089](http://localhost:8089)

## Backing up Slack Messages

The script to backup slack messages is located under ./scripts/slack-backup. This is run as a CronJob.


To build a new image execute:
```
pushd scripts/slack-backup

docker build -t rinormaloku/backup-slack-to-s3 .  

popd
```

The container expects the following env variables to be defined:
```
env:
- name: AWS_ACCESS_KEY_ID
  value: <REDACTED>
- name: AWS_SECRET_ACCESS_KEY
  value: <REDACTED>
- name: AWS_DEFAULT_REGION
  value: <REDACTED>
```

After the messages are backed up and pushed to S3, you need to rollout a new deployment for the slack-viewer-exporter.
