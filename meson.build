project('moserial', [ 'vala', 'c' ],
  version: '3.0.12',
  license: 'GPL3+',
  meson_version: '>= 0.50',
)

prefix = get_option('prefix')
data_dir = join_paths(prefix, get_option('datadir'), meson.project_name())
locale_dir = join_paths(prefix, get_option('localedir'))
bin_dir = join_paths (prefix, get_option ('bindir'))

dependencies = [
    dependency('glib-2.0', version: '>=2.12'),
    dependency('gobject-2.0', version: '>=2.12'),
    dependency('gtk+-3.0', version: '>=3.0.0'),
    dependency('gio-2.0'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('vala').find_library('linux'),
]

sources = files()

# Generate config.h
# ==============================================================================
config_h = configuration_data()
config_h.set_quoted('VERSION', meson.project_version())
config_h.set_quoted('UIROOT', '/org/gnome/moserial/ui/')
config_h.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_h.set_quoted('PACKAGE_DATADIR', data_dir)
config_h.set_quoted('PACKAGE_LOCALEDIR', locale_dir)
config_h.set_quoted('PACKAGE_NAME', meson.project_name())
config_h.set_quoted('PACKAGE_VERSION', meson.project_version())
configure_file(output : 'config.h', configuration : config_h)

config_h_dir = include_directories('.')

vapi_dir = meson.source_root() / 'src'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

vala_args = [
  '--pkg', 'Config',
]

c_args = [
  '-include', 'config.h',
]

subdir('data')
subdir('src')

