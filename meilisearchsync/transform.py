import gc

def create_message(message, origin_type, name):
    """Helper function to create a message dictionary."""
    return {
        'id': message.client_msg_id,
        'id_time': message.id,
        'subtype': message.subtype,
        'username': message.username,
        'msg': message.msg,
        'origin_type': origin_type,
        'channel_groupname': name
    }

def reset_and_store_messages(ms, messages):
    """Helper function to store messages and reset the array."""
    if messages:
        print(messages)
        ms.createmessages(messages)
        messages.clear()
        print("Stored messages")
        print("Running garbage collection...")
        gc.collect()

def transform_and_store_messages(channels, groups, ms):
    messages = []
    already_added_keys = {}

    # Process channel messages
    for channelname, channel_messages in channels.items():
        for message in channel_messages:
            if message.subtype == "channel_join" or message.client_msg_id is None or message.client_msg_id in already_added_keys:
                continue
            already_added_keys[message.client_msg_id] = 1
            msmessage = create_message(message, 'CHANNEL', channelname)
            messages.append(msmessage)

            if len(messages) > 2000:
                reset_and_store_messages(ms, messages)

    # Process group messages
    for groupname, group_messages in groups.items():
        for message in group_messages:
            if message.subtype == "channel_join" or message.client_msg_id is None or message.client_msg_id in already_added_keys:
                continue
            already_added_keys[message.client_msg_id] = 1
            msmessage = create_message(message, 'GROUP', groupname)
            messages.append(msmessage)

            if len(messages) > 2000:
                reset_and_store_messages(ms, messages)

    # Store any remaining messages
    reset_and_store_messages(ms, messages)
