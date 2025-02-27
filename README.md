# Solo's - Slack Export Viewer

1. [Our modifications to the slack export viewer](#Ourmodifications)
2. [How to run](#Howtorun)
3. [Backing up Slack Messages](#BackingupSlackMessages)
4. [Syncronizing Slack Users](#SyncronizingSlackUsers)
5. [Building the container image](#BuildingContainer)


##  1. <a name='Ourmodifications'></a>Our modifications

[slack-history.is.solo.io](https://slack-history.is.solo.io) Is a fork of [hfaran/slack-export-viewer](https://kandi.openweaver.com/python/hfaran/slack-export-viewer), for informations on how its pieces work check its readme.

We added: 
- Search capabilities, by adding indexing via meilisearch.
- Go to message, after searching an message.

##  2. <a name='Howtorun'></a>How to run

1. Run meilisearch:
```
docker run -it --rm -p 7700:7700 getmeili/meilisearch:latest
```

2. Download latest backup from: https://s3.console.aws.amazon.com/s3/object/solo-slack2?region=eu-west-1&prefix=slack.tgz

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

##  3. <a name='BackingupSlackMessages'></a>Backing up Slack Messages

The script to backup slack messages is located under ./scripts/slack-backup-messages. This is run as a CronJob.


To build a new image execute:
```
pushd scripts/slack-backup-messages

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

##  4. <a name='SyncronizingSlackUsers'></a>Syncronizing Slack Users

The script to syncronize slack users is located under ./scripts/slack-sync-users. This is run as a CronJob.


To build a new image execute:
```
pushd scripts/slack-sync-users

docker build -t rinormaloku/solo-sync-slack-users

popd
```

The container expects the following config map to mount the user ids
```

apiVersion: v1
kind: ConfigMap
metadata:
  name: slack-users
data:
  slack.left.corp: |

  slack.left.public: |

  slack.users.corp: |
    rinor.maloku

  slack.users.public: |
    rinor.maloku

```

After the messages are backed up and pushed to S3, you need to rollout a new deployment for the slack-viewer-exporter.


## 5. <a name='BuildingContainer'></a> Building the container

```
docker build -t rinormaloku/solo-slack-viewer:latest .
```
