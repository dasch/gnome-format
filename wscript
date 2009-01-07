#! /usr/bin/env python
# encoding: utf-8
# Jaap Haitsma, 2008
# Michael Kanis, 2008

import os
import intltool

# the following two variables are used by the target "waf dist"
VERSION='0.1.1'
APPNAME='gnome-format'

# these variables are mandatory ('/' are converted automatically)
srcdir = '.'
blddir = 'build'

def set_options(opt):
	opt.tool_options('compiler_cc')
	opt.add_option('--enable-maintainer-mode', action='store_true',
	               dest='maintainer', default=False,
	               help='Set correct paths to allow execution in src dir. [Default: False]')
	opt.add_option('--enable-debug-output', action='store_true',
	               dest='debug_output', default=False,
	               help='Enable debugging output. [Default: False]')

def configure(conf):
	import Options
	
	conf.check_tool('compiler_cc cc vala gnome intltool')
	conf.check_cfg(package='glib-2.0', uselib_store='GLIB', atleast_version='2.10.0', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='gtk+-2.0', uselib_store='GTK', atleast_version='2.10.0', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='dbus-glib-1', uselib_store='DBUS', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='gee-1.0', uselib_store='GEE', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='libglade-2.0', uselib_store='GLADE', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='gmodule-2.0', uselib_store='GMODULE', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='gio-unix-2.0', uselib_store='GIO_UNIX', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='libparted', uselib_store='PARTED', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='gthread-2.0', uselib_store='GTHREAD', mandatory=1, args='--cflags --libs')
	
	conf.define('PACKAGE_NAME', APPNAME)
	conf.define('GETTEXT_PACKAGE', APPNAME)
	conf.define('PACKAGE_VERSION', VERSION)
	conf.define('VERSION', VERSION)
	
	if Options.options.maintainer:
		conf.define('PACKAGE_DATADIR', 'data')
		conf.define('PACKAGE_LOCALEDIR', 'build/default/po')
	else:
		conf.define('PACKAGE_DATADIR', os.path.join(conf.env['PREFIX'], 'share', APPNAME)) 
		conf.define('PACKAGE_LOCALEDIR', os.path.join(conf.env['PREFIX'], 'share', 'locale'))
	
	if Options.options.debug_output:
		conf.define('DEBUG', 1)
	else:
		conf.define('DEBUG', 0)
	
	conf.write_config_header('config.h')

def build(bld):
	bld.add_subdirs('src')

	if bld.env['INTLTOOL']:
		bld.add_subdirs('po')

	bld.install_files('${PREFIX}/share/gnome-format', 'data/gnome-format.ui');
	bld.install_files('${PREFIX}/share/applications', 'data/gnome-format.desktop');
#	bld.install_files('${PREFIX}/share/locale', '.../*.mo');

def shutdown():
	pass
