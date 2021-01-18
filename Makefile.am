NULL = 

AUTOMAKE_OPTIONS = subdir-objects

ACLOCAL_AMFLAGS = --install -I m4

SUBDIRS = \
	data \
	doc \
	po \
	$(NULL)

INCLUDES = -DUIROOT=\""/org/gnome/moserial/ui/"\" -DPACKAGE_LOCALEDIR=\""$(datadir)/locale"\"

gresource_file = $(top_srcdir)/data/moserial.gresource.xml
AM_VALAFLAGS = --gresources $(gresource_file)

resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir)/data $(gresource_file))
src/resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(top_srcdir)/data --generate-source $<

AM_CPPFLAGS = \
	$(MOSERIAL_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = src/moserial.vala.stamp src/resources.c

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
	$(moserial_VALASOURCES:.vala=.c)	\
	src/resources.c				\
	$(NULL)

src/moserial.vala.stamp: $(moserial_VALASOURCES)
	$(VALAC) -C --pkg gtk+-3.0 --pkg gdk-3.0 --pkg gio-2.0 --pkg Config --pkg posix --pkg linux --vapidir src/ --basedir $(top_srcdir) $^
	touch $@

moserial_LDADD = \
	$(MOSERIAL_LIBS) \
	$(NULL)

EXTRA_DIST = \
	intltool-extract.in \
	intltool-update.in \
	intltool-merge.in \
	$(moserial_VALASOURCES) \
	src/Config.vapi		\
	src/moserial.vala.stamp \
        xmldocs.make            \
	ChangeLog.pre-git	\
	README \
	$(NULL)

CLEANFILES = \
	ChangeLog

DISTCLEANFILES = \
	intltool-extract \
	intltool-update \
	intltool-merge \
	po/.intltool-merge-cache \
	$(NULL)

# Build ChangeLog from GIT history
ChangeLog:
	@if test -d $(top_srcdir)/.git; then \
		GIT_DIR="$(top_srcdir)/.git" git log --stat > $@; \
	fi

dist: ChangeLog

.PHONY: ChangeLog
