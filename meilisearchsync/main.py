import click
import os
from slackviewer.reader import Reader
from .sync import Meilisearch

from .transform import *


@click.command()
@click.option("-m", "--meilisearch-server", type=click.STRING, required=True,
              default=os.environ.get('MEILISEARCH_SERVER', 'http://localhost:7700'),
              help="Meilisearch server to which the data is synchronized")
@click.option("-k", "--meilisearch-master-key", type=click.STRING, required=True,
              default=os.environ.get('MEILI_MASTER_KEY', ''),
              help="Meilisearch server to which the data is synchronized")
@click.option("-d", "--slack-directory", type=click.STRING, required=True,
              default=os.environ.get('SLACK_DIRECTORY', '../slack'),
              help="The slack directory to synchronize")
def main(meilisearch_server, meilisearch_master_key, slack_directory):
    print("Reading messages from: %s", slack_directory)
    reader = Reader(slack_directory)
    channels = reader.compile_channels({})
    groups = reader.compile_groups()

    print("Pushing to server: %s" % meilisearch_server)
    print()
    ms_messages = transform_to_ms_messages(channels, groups)
    ms = Meilisearch(host=meilisearch_server, masterkey=meilisearch_master_key)
    ms.createmessages(ms_messages)

    print()
