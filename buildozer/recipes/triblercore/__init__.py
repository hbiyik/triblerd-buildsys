
from pythonforandroid.recipe import PythonRecipe
from pythonforandroid.logger import info, shprint
from pythonforandroid.util import current_directory
import shutil
import os
import sh

packages = ("pyipv8", "tribler-common", "anydex", "tribler-core")


def copytree(src, dst, symlinks=False, ignore=None):
    for item in os.listdir(src):
        s = os.path.join(src, item)
        d = os.path.join(dst, item)
        if os.path.isdir(s) and not item.startswith(".git"):
            if os.path.exists(d):
                shutil.rmtree(d)
            shutil.copytree(s, d, symlinks, ignore)
        elif item.endswith(".py") or item.endswith(".pyo") or item.endswith(".pyc"):
            shutil.copy2(s, d)


class TriblerCoreRecipe(PythonRecipe):
    name = 'triblercore'
    version = '7.5'
    depends = ["triblerdeps"]

    def install_python_package(self, arch, name=None, env=None, is_dir=True):
        for package in packages:
            #srcdir = os.path.join(self.get_recipe_dir(), "..", "..", "..", "..", "tribler", "src", package)
            srcdir = os.path.join("/work/tribler/src", package)
            info('Installing {} into site-packages'.format(package))
            copytree(srcdir, self.ctx.get_python_install_dir())

recipe = TriblerCoreRecipe()
