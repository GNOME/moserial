AC_INIT([moserial],[3.0.21],[https://gitlab.gnome.org/GNOME/moserial/issues/])
dnl - also update data/moserial.appdata.xml.in
dnl - also update yaml file in the flathub repo

AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-xz tar-ustar no-dist-gzip])
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
LT_INIT

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_CONFIG_MACRO_DIR([m4])
YELP_HELP_INIT

AH_TEMPLATE([GETTEXT_PACKAGE], [Package name for gettext])
GETTEXT_PACKAGE=moserial
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE")
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.12.0
GTK_REQUIRED=3.2.0

AM_PROG_VALAC([0.48.5])

PKG_CHECK_MODULES(MOSERIAL, glib-2.0 >= $GLIB_REQUIRED
			    gobject-2.0 >= $GLIB_REQUIRED
			    gtk+-3.0 >= $GTK_REQUIRED
                            gio-2.0)
AC_SUBST(MOSERIAL_CFLAGS)
AC_SUBST(MOSERIAL_LIBS)

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

AC_CONFIG_FILES([
	Makefile
	po/Makefile.in
	data/Makefile
	data/icons/Makefile
	data/icons/scalable/Makefile
	data/icons/scalable/apps/Makefile
	doc/Makefile])

AC_OUTPUT
