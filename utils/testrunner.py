import os
import sys
import importlib
import traceback
from unittest import TestSuite, TestLoader, TextTestRunner
import logging
import argparse


logging.disable(logging.ERROR)
pathbackup = list(sys.path)


cases = []

    
def loadfile(path, fname, ex):
    mid = path + fname
    if mid in cases:
        return
    else:
        cases.append(mid)
        fpath = os.path.join(path, fname + ex)
        print("loading file %s" % fpath)
        if not path in sys.path:
            sys.path.append(path)
        try:
            loaded = importlib.import_module(fname)
            sys.path = list(pathbackup)
            return loaded
        except Exception:
            sys.path = list(pathbackup)
            print("ERROR: Cant load module %s" % fpath)
            print(traceback.format_exc())


def runtests(rootdir):
    ts = TestSuite()
    tl = TestLoader()
    tr = TextTestRunner(verbosity=2)
    for root, _, files in os.walk(rootdir):
        if not root.endswith("__pycache__"):
            for filename in files:
                filename, ext = os.path.splitext(filename)
                if filename.lower().startswith("test_") and ext.lower() in [".py", ".pyc", ".pyo"]:
                    module = loadfile(root, filename, ext)
                    if module and module not in cases:
                        tests = tl.loadTestsFromModule(module)
                        ts.addTests(tests)
    print("Total Tests Found %s" % ts.countTestCases())
    tr.run(ts)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--srcdir')
    args = parser.parse_args()
    if args.srcdir is not None:
        bases = [os.path.join(os.path.realpath(args.srcdir), "src", "tribler-core")]
    else:
        bases = ["%s/app/_python_bundle/site-packages/tribler_core" % os.environ["ANDROID_PRIVATE"]]   
    for base in bases:
        print("Running tests under: %s" % base)
        runtests(base)
