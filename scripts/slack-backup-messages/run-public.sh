#!/bin/bash
set -x 

export token=$TOKEN_PUBLIC
rm -rf slack

aws s3 cp s3://solo-slack2/slack-public.tgz . && tar zxvf slack-public.tgz
mv slack-public slack

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

recursive 'curl "https://slack.com/api/users.list?token=$token&cursor=$cursor"' members ./slack/users.json

curl "https://slack.com/api/conversations.list?token=$token&types=public_channel" | jq .channels > ./slack/channels.json
recursive 'curl "https://slack.com/api/conversations.list?token=$token&types=private_channel&cursor=$cursor"' channels ./slack/groups.json


cat ./slack/channels.json ./slack/groups.json | jq -r ".[] | [.name,.id] | @tsv" | while read name id; do
    last_ts="$(( $(date +%s) - 180*24*60*60 )).000000"
    if [ -d "./slack/$name" ]; then
        last_ts=$(cat ./slack/$name/messages.json | jq -r 'sort_by(.ts) | .[].ts' | tail -1)
        recursive 'curl "https://slack.com/api/conversations.history?token=$token&channel=$id&oldest=${last_ts}&cursor=$cursor"' messages ./slack/$name/new_messages.json
        jq -s add ./slack/$name/messages.json ./slack/$name/new_messages.json > ./slack/$name/tmp1.json
        mv ./slack/$name/tmp1.json ./slack/$name/messages.json
        rm ./slack/$name/new_messages.json
    else
        mkdir ./slack/$name
        recursive 'curl "https://slack.com/api/conversations.history?token=$token&channel=$id&cursor=$cursor"' messages ./slack/$name/messages.json
    fi
    sleep 1
    if [ -d "./slack/$name" ]; then
        cp ./slack/$name/replies.json ./slack/$name/tmp1.json
    else
        echo "[]" > ./slack/$name/tmp1.json
    fi
    cat ./slack/$name/messages.json | jq -r '.[] | select(has("thread_ts")) | .thread_ts' | while read thread; do
        recursive 'curl "https://slack.com/api/conversations.replies?token=$token&channel=$id&ts=$thread&oldest=${last_ts}&cursor=$cursor"' messages ./slack/$name/tmp5.json
        cat ./slack/$name/tmp5.json | jq '.[] | select(.ts != .thread_ts)' | jq --slurp '.' > ./slack/$name/tmp2.json
        rm ./slack/$name/tmp5.json

        if [[ -z "$(cat ./slack/$name/tmp2.json)" ]];then
            if [[ "$(cat ./slack/$name/tmp2.json)" != "[]" ]];then
                jsonnew='{"replies": '$(cat ./slack/$name/tmp2.json  | jq '.[] |= {"user": .user, "ts": .ts}' | jq --arg ts $thread '.[] |= select(.ts != $ts)' | jq -c 'map(select( . != null and . != {} and .!= [] ))')'}'
                jsonreplace=$(cat ./slack/$name/tmp2.json  | jq '.[] |= {"user": .user, "ts": .ts}' | jq --arg ts $thread '.[] |= select(.ts != $ts)' | jq -c 'map(select( . != null and . != {} and .!= [] ))')
                cat ./slack/$name/messages.json | jq --arg ts $thread --argjson jsonnew $jsonnew --argjson jsonreplace $jsonreplace '.[] |= if .thread_ts == $ts then if has("replies") then .replies = $jsonreplace else . + $jsonnew end else . end' > ./slack/$name/tmp4.json
                mv ./slack/$name/tmp4.json ./slack/$name/messages.json
            fi
        fi

        jq -s add ./slack/$name/tmp1.json ./slack/$name/tmp2.json | jq '. | unique' > ./slack/$name/tmp3.json
        mv ./slack/$name/tmp3.json ./slack/$name/tmp1.json
        sleep 1
    done
    mv ./slack/$name/tmp1.json ./slack/$name/replies.json
    rm ./slack/$name/tmp2.json
done

mv slack slack-public
mv slack-public.tgz slack-public.tgz.`date +'%Y%m%d'`   
tar zcvf slack-public.tgz slack-public

aws s3 cp slack-public.tgz s3://solo-slack2/
