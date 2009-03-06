glade_DATA = moserial.ui

gladedir = $(datadir)/moserial/glade

EXTRA_DIST = moserial.ui moserial.glade

moserial.ui: moserial.glade
	gtk-builder-convert moserial.glade moserial.ui
