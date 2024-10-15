import click
import os
from slackviewer.reader import Reader
import resource  # Unix-specific
from .sync import Meilisearch

from .transform import *

def limit_memory(max_memory_mb):
    """Limit the memory usage to max_memory_mb."""
    soft, hard = resource.getrlimit(resource.RLIMIT_AS)
    resource.setrlimit(resource.RLIMIT_AS, (max_memory_mb * 1024 * 1024, soft))


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
    # Limit memory usage to 2GB
    limit_memory(2048)

    print("Reading messages from: %s", slack_directory)
    reader = Reader(slack_directory)
    channels = reader.compile_channels({})
    groups = reader.compile_groups()

    print("Pushing to server: %s" % meilisearch_server)
    print()
    ms = Meilisearch(host=meilisearch_server, masterkey=meilisearch_master_key)
    transform_and_store_messages(channels, groups, ms)

    print()
