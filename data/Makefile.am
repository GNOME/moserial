SUBDIRS = icons

@INTLTOOL_DESKTOP_RULE@

desktopdir = $(datadir)/applications
desktop_in_files=moserial.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop) 

@INTLTOOL_XML_RULE@
appdatadir = $(datarootdir)/metainfo
appdata_DATA = $(appdata_in_files:.xml.in=.xml)
appdata_in_files = moserial.appdata.xml.in

man_MANS = moserial.1

gresource_file = moserial.gresource.xml
resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies $(gresource_file))

EXTRA_DIST = 			\
	$(desktop_in_files)	\
	$(desktop_DATA)		\
        $(appdata_in_files)     \
        $(appdata_DATA)         \
	$(man_MANS)		\
	$(gresource_file)	\
	$(resource_files)

DISTCLEANFILES =                \
	$(desktop_DATA)		\
	$(appdata_DATA)
