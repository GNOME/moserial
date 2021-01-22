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

public class Profile : GLib.Object
{
    public bool profileChanged {get; private set; default = false; }

    private KeyFile keyFile;
    construct {
        keyFile = new KeyFile ();
    }

    public string ? getString (string group, string key)
    {
        string ? result = null;
        try {
            result = keyFile.get_string (group, key);
        } catch (GLib.KeyFileError e) {
            stdout.printf ("%s\n", e.message);
        }
        return result;
    }

    public void setString (string group, string key, string new_val)
    {
        bool changed = (getString (group, key) != new_val);
        keyFile.set_string (group, key, new_val);
        if (changed) {
            profileChanged = true;
        }
    }

    public int getInteger (string group, string key, int default_val)
    {
        int result = default_val;
        try {
            result = keyFile.get_integer (group, key);
        } catch (GLib.KeyFileError e) {
            stdout.printf ("%s\n", e.message);
        }
        return result;
    }

    public void setInteger (string group, string key, int new_val)
    {
        bool changed = (getInteger (group, key, 0) != new_val);
        keyFile.set_integer (group, key, new_val);
        if (changed) {
            profileChanged = true;
        }
    }

    public bool getBoolean (string group, string key, bool default_val)
    {
        bool result = default_val;
        try {
            result = keyFile.get_boolean (group, key);
        } catch (GLib.KeyFileError e) {
            stdout.printf ("%s\n", e.message);
        }
        return result;
    }

    public void setBoolean (string group, string key, bool new_val)
    {
        bool changed = (getBoolean (group, key, false) != new_val);
        keyFile.set_boolean (group, key, new_val);
        if (changed) {
            profileChanged = true;
        }
    }

    public bool load (string ? filename, Gtk.Window window)
    {
        string f;
        bool default_profile = false;

        if (filename == null) {
            default_profile = true;
            f = "%s/moserial.conf".printf (GLib.Environment.get_user_config_dir ());
        } else
            f = filename;

        try {
            keyFile.load_from_file (f, GLib.KeyFileFlags.NONE);
            profileChanged = false;
            return true;
        } catch (GLib.KeyFileError e) {
            stdout.printf ("%s\n", e.message);
            /* try loading the non-broken parts of the profile - return true */
            profileChanged = false;
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

    public void toString ()
    {
        size_t s;
        stdout.printf ("%s\n", keyFile.to_data (out s));
    }

    public void save (string ? filename, Gtk.Window window)
    {
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
        profileChanged = false;
    }
}
