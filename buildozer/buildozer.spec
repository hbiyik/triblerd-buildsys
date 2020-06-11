[app]
title = triblerd
package.name = triblerd
package.domain = org.tudelf
source.dir = .
source.include_exts = py,png,jpg,kv,atlas
source.exclude_dirs = bin,dist
version = 0.1
requirements = triblercore
orientation = portrait
fullscreen = 0
no_compile_pyo = 1
android.permissions = INTERNET
android.private_storage = True
android.accept_sdk_license = True
android.logcat_filters = *:S python:V DEBUG:V
android.arch = armeabi-v7a
p4a.local_recipes = recipes
p4a.bootstrap = sdl2

[buildozer]
log_level = 2
warn_on_root = 1
bin_dir = ./dist

