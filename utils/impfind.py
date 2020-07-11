'''
Created on 18 Haz 2020

@author: boogie
'''
import os
import re
import importlib

imps = []


def addimp(imp):
    if imp not in imps:
        try:
            mod = importlib.import_module(imp)
            if "dist-packages" in mod.__file__:
                imps.append(imp)
                print(imp)
        except:
            print("%s: not found" % imp)
            imps.append(imp)



base = os.path.realpath(".")

for root, _, fnames in os.walk(base):
    for fname in fnames:
        if fname.endswith(".py"):
            fcoont = None
            fpath = os.path.join(base, root, fname)
            with open(fpath) as f:
                fcont = f.read()
            for imp in re.findall(r"\n\s*?import\s+(.+)(?:\s|\r|\n)", fcont):
                addimp(imp)
            for imp in re.findall(r"\n\s*?from\s+(.+?)\s", fcont):
                imp = imp.split(".")[0]
                addimp(imp)
