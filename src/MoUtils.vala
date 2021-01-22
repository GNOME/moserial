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

using GLib;
using Gtk;

public class MoUtils : GLib.Object
{
    public static GLib.File newFile (string path)
    {
        string uri;
        if ("://" in path)
            uri = path;
        else
            uri = "file://%s".printf (path);
        return File.new_for_uri (uri);
    }

    public static bool fileExists (string path)
    {
        GLib.File file = newFile (path);
        return file.query_exists (null);
    }

    public static int64 fileSize (string path)
    {
        GLib.File file = newFile (path);
        try {
            GLib.FileInfo info = file.query_info (FileAttribute.STANDARD_SIZE, 0, null);
            return info.get_size ();
        } catch (GLib.Error e) {
            warning ("%s", e.message);
        }
        return 0;
    }

    public static string getParentFolder (string path)
    {
        GLib.File file = newFile (path);
        GLib.File parent = file.get_parent ();
        return parent.get_parse_name ();
    }

    public static string ? getLastMessage (string ? messages)
    {
        string ? message = null;
        string ? escaped = messages.escape ("");
        escaped = InputParser.statusReplace (escaped);
        string[] splitMessages;
        splitMessages = escaped.split ("\\n", 20);
        for (int x = 0; x < GLib.strv_length (splitMessages); x++) {
            if (splitMessages[x].length > 5)
                message = splitMessages[x];
        }
        return message;
    }

    public static void populateComboBox (ComboBox Combo, string[] val_array, bool render_cell = true)
    {
        Gtk.ListStore Model = new Gtk.ListStore (1, typeof (string));
        foreach (string val_item in val_array) {
            TreeIter iter;
            Model.append (out iter);
            Model.set (iter, 0, _(val_item));
        }
        Combo.set_model (Model);
        // Make cell rendering optional
        // Required for standard ComboBox, but not for ComboBox/Entry combination.
        if (render_cell) {
            CellRenderer Cell = new CellRendererText ();
            Combo.pack_start (Cell, true);
            Combo.set_attributes (Cell, "text", 0);
        }
    }
}

