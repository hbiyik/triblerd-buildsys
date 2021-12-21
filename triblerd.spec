# -*- mode: python -*-
block_cipher = None
import imp
import os
import sys
import shutil

import aiohttp_apispec


root_dir = os.path.join(os.path.abspath(os.path.dirname(__name__)), "tribler")
src_dir = os.path.join(root_dir, "src")

from tribler_core.version import version_id
version_str = version_id.split('-')[0]

data_to_copy = [
    (os.path.join(src_dir, "tribler-common", "tribler_common"), 'tribler_source/tribler_common'),
    (os.path.join(src_dir, "tribler-core", "tribler_core"), 'tribler_source/tribler_core'),
    (os.path.dirname(aiohttp_apispec.__file__), 'aiohttp_apispec')
]

# Importing lib2to3 as hidden import does not import all the necessary files for some reason so had to import as data.
try:
    lib2to3_dir = imp.find_module('lib2to3')[1]
    data_to_copy += [(lib2to3_dir, 'lib2to3')]
except ImportError:
    pass


excluded_libs = ['wx', 'bitcoinlib', 'PyQt4', 'FixTk', 'tcl', 'tk', '_tkinter', 'tkinter', 'Tkinter', 'matplotlib']


a = Analysis([os.path.join(os.path.dirname(__name__), "triblerd.py")],
             pathex=[''],
             binaries=None,
             datas=data_to_copy,
             hiddenimports=['pony',
                            'pony.orm',
                            'pony.orm.dbproviders',
                            'pony.orm.dbproviders.sqlite',
                            'pkg_resources.py2_warn',
							'certifi'],
             hookspath=[],
             runtime_hooks=[],
             excludes=excluded_libs,
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)


if os.name == "nt":
	a.binaries += TOC([('libsodium.dll', 'C:\\windows\\system32\\libsodium.dll', 'BINARY'),])
	for f in os.listdir("Z:\\work\\python\\DLLs"):
		if f.endswith(".dll"):
			print(f)
			a.binaries += TOC([(f, 'Z:\\work\\python\\DLLs\\' + f, 'BINARY'),])
else:
	a.binaries += TOC([('libsodium.so', '/usr/lib/libsodium.so', 'BINARY'),])

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          bootloader_ignore_signals=False,
          name='triblerd',
          debug=True,
          strip=False,
          upx=False,
          console=True,
          icon=os.path.join(root_dir, "build", "win", "resources", "tribler.ico"))
