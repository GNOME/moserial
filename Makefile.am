NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	data \
	doc \
	po \
	$(NULL)

gladedir = $(datadir)/moserial/glade
INCLUDES = -DMOSERIAL_GLADEDIR=\""$(gladedir)"\" -DPACKAGE_LOCALEDIR=\""$(datadir)/locale"\"

AM_CPPFLAGS = \
	$(MOSERIAL_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = src/moserial.vala.stamp

bin_PROGRAMS = moserial

moserial_VALASOURCES = \
	src/MainWindow.vala \
	src/Main.vala \
	src/SettingsDialog.vala \
	src/Settings.vala \
	src/SendProgressDialog.vala \
	src/ReceiveChooserDialog.vala \
	src/ReceiveProgressDialog.vala \
	src/RecordDialog.vala \
	src/PreferencesDialog.vala \
	src/SerialConnection.vala \
	src/HexTextBuffer.vala \
	src/SerialStreamRecorder.vala \
	src/InputParser.vala \
	src/Rzwrapper.vala \
	src/XmodemFilenameDialog.vala \
	src/SendChooserDialog.vala \
	src/Szwrapper.vala \
	src/AutoScroll.vala \
	src/Preferences.vala \
	src/Profile.vala \
	src/DefaultPaths.vala \
	src/MoUtils.vala \
	$(NULL)

moserial_SOURCES = \
	$(moserial_VALASOURCES:.vala=.c) \
	$(NULL)

src/moserial.vala.stamp: $(moserial_VALASOURCES)
	$(VALAC) -C --pkg gtk+-2.0 --pkg gdk-2.0 --pkg Config --pkg posix --pkg gconf-2.0 --vapidir src/ --basedir $(top_srcdir) $^
	touch $@

moserial_LDADD = \
	$(MOSERIAL_LIBS) \
	$(NULL)

distcleancheck_listfiles = find . -type f -print | grep -v 'omf\.out'

distuninstallcheck_listfiles = find . -type f -print | grep -v '^\./var/scrollkeeper' | grep -v 'omf' | grep -v 'figures'

EXTRA_DIST = \
	intltool-extract.in \
	intltool-update.in \
	intltool-merge.in \
	$(moserial_VALASOURCES) \
	src/moserial.vala.stamp \
        omf.make                \
        xmldocs.make            \
        gnome-doc-utils.make	\
	MAINTAINERS		\
	ChangeLog.pre-git	\
	$(NULL)

CLEANFILES = \
	ChangeLog

DISTCLEANFILES = \
	intltool-extract \
	intltool-update \
	intltool-merge \
	po/.intltool-merge-cache \
        gnome-doc-utils.make	\
	$(NULL)

DISTCHECK_CONFIGURE_FLAGS = --disable-scrollkeeper


# Build ChangeLog from GIT history
ChangeLog:
	@if test -d $(top_srcdir)/.git; then \
		GIT_DIR="$(top_srcdir)/.git" git log --stat > $@; \
	fi

dist: ChangeLog

.PHONY: ChangeLog
