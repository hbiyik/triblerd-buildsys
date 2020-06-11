import run_tribler_headless as triblerd
from asyncio import ensure_future, get_event_loop
from android.storage import app_storage_path

class options:
    restapi = 8085
    statedir = app_storage_path()
    ipv8 = -1
    libtorrent = -1
    ipv8_bootstrap_override = None
    testnet = False

service = triblerd.TriblerService()

loop = get_event_loop()
coro = service.start_tribler(options)
ensure_future(coro)
loop.run_forever()
