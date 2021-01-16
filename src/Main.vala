/*
 *  Copyright (C) 2009-2010 Michael J. Chudobiak.
 *
 *  This file is part of moserial.
 *
 *  moserial is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  moserial is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with moserial.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;

class moserial.Main : GLib.Object
{
    static string profileFilename;
    const OptionEntry[] options = {
        { "profile", 'p', 0, OptionArg.FILENAME, out profileFilename, N_ ("Profile file to load"), "foo.conf" },
        { null }
    };
    public void run ()
    {

        moserial.MainWindow mainWindow;
        if (!(profileFilename == null) && (!GLib.Path.is_absolute (profileFilename)))
            profileFilename = GLib.Path.build_filename (GLib.Environment.get_current_dir (), profileFilename);
        mainWindow = new moserial.MainWindow (profileFilename);
        mainWindow.showWindow ();
    }

    public static int main (string[] args)
    {
        OptionContext context;
        Gtk.init (ref args);

        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        context = new OptionContext (_("- moserial serial terminal"));
        context.add_main_entries (options, null);
        context.add_group (Gtk.get_option_group (true));
        try {
            if (!context.parse (ref args)) {
                stdout.printf (_("Run '%s --help' to see a full list of available command line options.\n"), args[0]);
            } else {
                Main app = new Main ();
                app.run ();
                Gtk.main ();
            }
        } catch (GLib.OptionError e) {
            stdout.printf ("%s\n", e.message);
            stdout.printf (_("Run '%s --help' to see a full list of available command line options.\n"), args[0]);
        }
        return 0;
    }
}
