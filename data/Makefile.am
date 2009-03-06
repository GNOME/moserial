SUBDIRS = glade icons

@INTLTOOL_DESKTOP_RULE@

desktopdir = $(datadir)/applications
desktop_in_files=moserial.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop) 

EXTRA_DIST = 			\
	$(desktop_in_files)	\
	$(desktop_DATA)		

DISTCLEANFILES =                \
	$(desktop_DATA)
