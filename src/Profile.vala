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

public class Profile : GLib.Object {
    public KeyFile keyFile;
    construct {
        keyFile = new KeyFile ();
    }
    public void saveWindowSize (int w, int h) {
        if (w > 0)
            keyFile.set_integer ("window", "width", w);
        if (h > 0)
            keyFile.set_integer ("window", "height", h);
    }

    public void saveWindowPanedPosition (int pos) {
        keyFile.set_integer ("window", "paned_pos", pos);
    }

    public int getWindowPanedPosition () {
        try {
            return keyFile.get_integer ("window", "paned_pos");
        } catch (GLib.KeyFileError e) {
            return -1;
        }
    }

    public int getWindowWidth () {
        try {
            return keyFile.get_integer ("window", "width");
        } catch (GLib.KeyFileError e) {
            return -1;
        }
    }

    public int getWindowHeight () {
        try {
            return keyFile.get_integer ("window", "height");
        } catch (GLib.KeyFileError e) {
            return -1;
        }
    }

    public void setNotebookTab (bool outgoing, uint tab) {
        string n = "incoming_tab";
        if (outgoing) {
            n = "outgoing_tab";
        }

        if (tab != 0) {
            keyFile.set_integer ("window", n, 1);
        } else {
            keyFile.set_integer ("window", n, 0);
        }
    }

    public int getNotebookTab (bool outgoing) {
        string n = "incoming_tab";
        if (outgoing) {
            n = "outgoing_tab";
        }

        try {
            if (keyFile.get_integer ("window", n) != 0) {
                return 1;
            }
            return 0;
        } catch (GLib.KeyFileError e) {
            return 0;
        }
    }

    public bool load (string ? filename, Gtk.Window window) {
        string f;
        bool default_profile = false;

        if (filename == null) {
            default_profile = true;
            f = "%s/moserial.conf".printf (GLib.Environment.get_user_config_dir ());
        } else
            f = filename;
        try {
            keyFile.load_from_file (f, GLib.KeyFileFlags.NONE);
            return true;
        } catch (GLib.KeyFileError e) {
            stdout.printf ("%s\n", e.message);
            /* try loading the non-broken parts of the profile - return true */
            return true;
        } catch (GLib.FileError e) {
            if (!default_profile) {
                var errorDialog = new MessageDialog (window, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.CLOSE, "%s: %s\n%s", _("Error: Could not open file"), filename, e.message);
                errorDialog.run ();
                errorDialog.destroy ();
            }
            return false;
        }
    }

    public void toString () {
        size_t s;
        stdout.printf ("%s\n", keyFile.to_data (out s));
    }

    public void save (string ? filename, Gtk.Window window) {
        GLib.File ? file;
        FileOutputStream ? fos;
        string f;
        bool default_profile = false;
        if (filename == null) {
            default_profile = true;
            f = "%s/moserial.conf".printf (GLib.Environment.get_user_config_dir ());
        } else
            f = filename;
        file = File.new_for_path (f);
        try {
            size_t s;
            string data;
            fos = file.replace (null, false, GLib.FileCreateFlags.NONE, null);
            data = keyFile.to_data (out s);
            fos.write (data.data, null);
        } catch (GLib.Error e) {
            stdout.printf ("profile.save error: %s\n", e.message);
            if (!default_profile) {
                var errorDialog = new MessageDialog (window, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.CLOSE, "%s: %s\n%s", _("Error: Could not open file"), filename, e.message);
                errorDialog.run ();
                errorDialog.destroy ();
            }
        }
    }
}
