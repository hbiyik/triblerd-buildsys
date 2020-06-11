from pythonforandroid.recipe import CompiledComponentsPythonRecipe


class Lz4Recipe(CompiledComponentsPythonRecipe):

    version = '3.0.2'

    url = 'https://files.pythonhosted.org/packages/source/l/lz4/lz4-{version}.tar.gz'

    depends = ['liblz4', 'setuptools']

    site_packages_name = 'lz4'

    call_hostpython_via_targetpython = False


recipe = Lz4Recipe()
