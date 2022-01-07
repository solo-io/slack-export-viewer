
def transform_to_ms_messages(channels, groups):
    messages = []

    already_added_keys = {}
    for channelname in channels.keys():
        for message in channels[channelname]:
            if message.subtype == "channel_join" or message.client_msg_id is None or message.client_msg_id in already_added_keys:
                continue
            already_added_keys[message.client_msg_id] = 1
            msmessage = {'id': message.client_msg_id,
                         'id_time': message.id,
                         'subtype': message.subtype,
                         'username': message.username,
                         'msg': message.msg,
                         'origin_type': 'CHANNEL',
                         'channel_groupname': channelname
                         }
            messages.append(msmessage)

    for groupname in groups.keys():
        for message in groups[groupname]:
            if message.subtype == "channel_join" or message.client_msg_id is None or message.client_msg_id in already_added_keys:
                continue
            already_added_keys[message.client_msg_id] = 1
            msmessage = {'id': message.client_msg_id,
                         'id_time': message.id,
                         'subtype': message.subtype,
                         'username': message.username,
                         'msg': message.msg,
                         'origin_type': 'GROUP',
                         'channel_groupname': groupname
                         }
            messages.append(msmessage)

    print(messages)
    return messages
