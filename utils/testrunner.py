import os
import sys
import importlib
import traceback
from unittest import TestSuite, TestLoader, TextTestRunner
import logging

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--srcdir')

args = parser.parse_args()

if args.srcdir is not None:
    bases = ["%s/src/anydex" % args.srcdir,
             "%s/src/tribler-core" % args.srcdir,
             ]
else:
    bases = ["%s/app/_python_bundle/site-packages/anydex" % os.environ["ANDROID_PRIVATE"],
             "%s/app/_python_bundle/site-packages/tribler_core" % os.environ["ANDROID_PRIVATE"]]   

logging.disable(logging.ERROR)
pathbackup = list(sys.path)

def loadfile(path, fname, ex):
    fpath = "%s/%s%s"% (path, fname, ex)
    print("loading file %s" % fpath)
    if not path in sys.path:
        sys.path.append(path)
    try:
        loaded = importlib.import_module(fname)
        sys.path = pathbackup
        return loaded
    except Exception:
        print("ERROR: Cant load module %s" % fpath)
        print(traceback.format_exc())


def runtests(rootdir):
    print("Running tests under: %s" % rootdir)
    ts = TestSuite()
    tl = TestLoader()
    tr = TextTestRunner(verbosity=2)
    for root, _, files in os.walk(rootdir):
        if not root.endswith("/__pycache__"):
            for filename in files:
                filename, ext = os.path.splitext(filename)
                if filename.lower().startswith("test_") and ext.lower() in [".py", ".pyc", ".pyo"]:
                    module = loadfile(root, filename, ext)
                    if module:
                        tests = tl.loadTestsFromModule(module)
                        ts.addTests(tests)
    print("Total Tests Found %s" % ts.countTestCases())
    tr.run(ts)
    

for base in bases:
    runtests(base)
