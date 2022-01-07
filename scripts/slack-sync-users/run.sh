#!/bin/bash

function recursive {
    echo "[]" > ./slack/tmp1.json
    cursor=
    while true; do
        echo $cursor
        eval $1 > ./slack/tmp.json
        cat ./slack/tmp.json | jq .$2 > ./slack/tmp2.json
        jq -s add ./slack/tmp1.json ./slack/tmp2.json > ./slack/tmp3.json
        mv ./slack/tmp3.json ./slack/tmp1.json
        cursor=$(cat ./slack/tmp.json | jq -r .response_metadata.next_cursor | sed 's/=/%3D/g')
        echo $cursor
        if [[ "$cursor" == "" ]] || [[ "$cursor" == "null" ]]; then
            break   
        fi 
        sleep 1
    done
    mv ./slack/tmp1.json $3
    rm -f ./slack/tmp2.json
}

rm -rf slack
mkdir slack

token=$TOKEN_PUBLIC

recursive 'curl "https://slack.com/api/users.list?token=$token&cursor=$cursor"' members ./slack/users.json

echo > /tmp/userids.txt
cat ./slack/users.json |  jq -r ".[] | [.name,.id] | @tsv" | while read name id; do
  echo $name $id >> /tmp/userids.txt
done

recursive 'curl "https://slack.com/api/conversations.list?token=$token&types=private_channel&exclude_archived=true&cursor=$cursor"' channels /tmp/groups.json

cat /tmp/groups.json | jq -r ".[] | [.name,.id] | @tsv" | while read name id; do
  echo Processing the $name channel
  curl -s "https://slack.com/api/conversations.members?token=$token&channel=$id" | jq -r '.members[]' > /tmp/groupmembers.txt
  cat /data/slack.users.public | while read username; do
    userid=$(grep -i "^$username\s" /tmp/userids.txt | awk '{ print $2 }')
    if ! grep --quiet $userid /tmp/groupmembers.txt; then
      echo Adding $username to $name
      curl -s "https://slack.com/api/conversations.invite?token=$token&channel=$id&users=$userid"
      echo
      echo
    fi
  done
  cat /data/slack.left.public | while read username; do
    userid=$(grep -i "^$username\s" /tmp/userids.txt | awk '{ print $2 }')
    if grep --quiet $userid /tmp/groupmembers.txt; then
      echo Removing $username from $name
      curl -s "https://slack.com/api/conversations.kick?token=$token&channel=$id&users=$userid"
      echo
      echo
    fi
  done
done

rm -rf slack
mkdir slack

token=$TOKEN_CORP

recursive 'curl -H "Authorization: Bearer $token" "https://slack.com/api/users.list?cursor=$cursor"' members ./slack/users.json

echo > /tmp/userids.txt
cat ./slack/users.json |  jq -r ".[] | [.name,.id] | @tsv" | while read name id; do
  echo $name $id >> /tmp/userids.txt
done

recursive 'curl -H "Authorization: Bearer $token" "https://slack.com/api/conversations.list?types=private_channel&cursor=$cursor"' channels /tmp/groups.json

cat /tmp/groups.json | jq -r ".[] | [.name,.id] | @tsv" | while read name id; do
  echo Processing the $name channel
  curl -s -H "Authorization: Bearer $token" "https://slack.com/api/conversations.members?channel=$id" | jq -r '.members[]' > /tmp/groupmembers.txt
  cat /data/slack.users.corp | while read username; do
    userid=$(grep -i "^$username\s" /tmp/userids.txt | awk '{ print $2 }')
    if ! grep --quiet $userid /tmp/groupmembers.txt; then
      echo Adding $username to $name
      curl -s -H "Authorization: Bearer $token" "https://slack.com/api/conversations.invite?channel=$id&users=$userid"
      echo
      echo
    fi
  done
  cat /data/slack.left.corp | while read username; do
    userid=$(grep -i "^$username\s" /tmp/userids.txt | awk '{ print $2 }')
    if grep --quiet $userid /tmp/groupmembers.txt; then
      echo Removing $username from $name
      curl -s -H "Authorization: Bearer $token" "https://slack.com/api/conversations.kick?channel=$id&users=$userid"
      echo
      echo
    fi
  done
done