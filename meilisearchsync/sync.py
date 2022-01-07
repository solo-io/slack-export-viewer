import meilisearch


class Meilisearch(object):
    def __init__(self, host='http://127.0.0.1:7700', masterkey=None):
        self.client = meilisearch.Client(host, masterkey)

    def createmessages(self, ms_messages):
        index = self.client.index('messages')

        for i in range(0, len(ms_messages), 2000):
            slc = ms_messages[i:i + 2000]
            output = index.add_documents(slc)
            print("== ID: " + str(output))
