'''
Created on Dec 2, 2021

@author: boogie
'''

import argparse
import logging
import sys
import pathlib

import encodings.idna  # pylint: disable=unused-import

from tribler_common.logger import load_logger_config
from tribler_common.process_checker import ProcessChecker
from tribler_common.sentry_reporter.sentry_reporter import SentryReporter, SentryStrategy
from tribler_common.sentry_reporter.sentry_scrubber import SentryScrubber
from tribler_common.version_manager import VersionHistory
from tribler_core.check_os import should_kill_other_tribler_instances
from tribler_core import start_core


logger = logging.getLogger(__name__)


class RunTriblerArgsParser(argparse.ArgumentParser):
    def __init__(self, *args, **kwargs):
        kwargs['description'] = 'Run Tribler BitTorrent client'
        super().__init__(*args, **kwargs)
        self.add_argument('--statedir', '-s', default=None, help='Statedir', required=True)
        self.add_argument('--restapi', '-p', default=-1, type=int, help='Port for REST API', required=True)
        self.add_argument('--restkey', '-k', default=-1, type=str, help='Key for REST API', required=True)


def init_sentry_reporter():
    """ Initialise sentry reporter

    We use `sentry_url` as a URL for normal tribler mode and TRIBLER_TEST_SENTRY_URL
    as a URL for sending sentry's reports while a Tribler client running in
    test mode
    """
    from tribler_core.version import sentry_url, version_id
    test_sentry_url = SentryReporter.get_test_sentry_url()

    if not test_sentry_url:
        SentryReporter.init(sentry_url=sentry_url,
                            release_version=version_id,
                            scrubber=SentryScrubber(),
                            strategy=SentryStrategy.SEND_ALLOWED_WITH_CONFIRMATION)
        logger.info('Sentry has been initialised in normal mode')
    else:
        SentryReporter.init(sentry_url=test_sentry_url,
                            release_version=version_id,
                            scrubber=None,
                            strategy=SentryStrategy.SEND_ALLOWED)
        logger.info('Sentry has been initialised in debug mode')

def init_boot_logger():
    # this logger config will be used before Core and GUI
    #  set theirs configs explicitly
    logging.basicConfig(level=logging.INFO, stream=sys.stdout)


if __name__ == "__main__":
    init_boot_logger()
    init_sentry_reporter()

    parsed_args = RunTriblerArgsParser().parse_args()

    root_state_dir = pathlib.Path(parsed_args.statedir)
    api_port = parsed_args.restapi
    api_key = parsed_args.restkey

    should_kill_other_tribler_instances(root_state_dir)
    logger.info('Running Core')
    load_logger_config('tribler-core', root_state_dir)

    # Check if we are already running a Tribler instance
    process_checker = ProcessChecker(root_state_dir)
    if process_checker.already_running:
        logger.info('Core is already running, exiting')
        sys.exit(1)
    process_checker.create_lock_file()
    version_history = VersionHistory(root_state_dir)
    state_dir = version_history.code_version.directory
    try:
        start_core.start_tribler_core(api_port, api_key, state_dir)
    finally:
        logger.info('Remove lock file')
        process_checker.remove_lock_file()