import meilisearch

class QueryMeilisearch(object):
    def __init__(self, host='http://127.0.0.1:7700', masterkey=None):
        self.client = meilisearch.Client(host, masterkey)

    def search(self, query):
        index = self.client.index('messages')
        return index.search(query)
