from unittest import TestCase

from sync import Meilisearch

class TestMeilisearch(TestCase):
    
    def test_createindex(self):
        ms = Meilisearch()
        ms.createindex()
