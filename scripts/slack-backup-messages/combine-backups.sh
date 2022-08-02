mkdir slack-combined

set -x

#aws s3 cp s3://solo-slack/slack-public.tgz . && tar zxvf slack-public.tgz
#mv slack slack-public

#aws s3 cp s3://solo-slack/slack-corp.tgz . && tar zxvf slack-corp.tgz
### wasn't needed
#mv slack slack-corp

mkdir slack-combined
## potentially we might need to get user profiles too from connections
jq -s add  slack-public/users.json slack-corp/users.json > slack-combined/users.json

for folder in $(find slack-corp/* -maxdepth 0 -type d); do
  folder_name=$(basename $folder)
  cp -R $folder "slack-combined/${folder_name}--corp"
done

## rename chanels and groups for corp
cat slack-corp/channels.json | jq -c 'map(.name |= "\(.)--corp")' | jq -r > ./slack-corp/channels-corp.json
cat slack-corp/groups.json | jq -c 'map(.name |= "\(.)--corp")' | jq -r > ./slack-corp/groups-corp.json

## combine channels and groups
jq -s add  slack-public/channels.json slack-corp/channels-corp.json > slack-combined/channels.json
jq -s add  slack-public/groups.json slack-corp/groups-corp.json > slack-combined/groups.json


## Copy all dirs from public without change
for folder in $(find slack-public/* -maxdepth 0 -type d); do
  folder_name=$(basename $folder)
  cp -R $folder "slack-combined/${folder_name}"
done

tar zcvf slack-combined.tgz slack-combined
aws s3 cp slack-combined.tgz s3://solo-slack/
