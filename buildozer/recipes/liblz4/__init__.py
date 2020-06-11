from pythonforandroid.recipe import Recipe
from pythonforandroid.logger import shprint
from pythonforandroid.util import current_directory
from os.path import join
import sh


class Liblz4Recipe(Recipe):
    version = '1.9.2'
    url = 'https://github.com/lz4/lz4/archive/v{version}.tar.gz'
    built_libraries = {'liblz4.a': 'lib'}

    def build_arch(self, arch):
        env = self.get_recipe_env(arch)
        curdir = self.get_build_dir(arch.arch)

        with current_directory(curdir):
            bash = sh.Command('sh')
            shprint(sh.make, _env=env)


recipe = Liblz4Recipe()
