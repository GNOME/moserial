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
public class moserial.XmodemFilenameDialog : GLib.Object
{
    private Dialog dialog;
    private Gtk.Entry xmodemFilename;
    public string filename;

    public XmodemFilenameDialog (Window parent)
    {
        var builder = new Gtk.Builder.from_resource (Config.UIROOT + "xmodem_filename_dialog.ui");

        dialog = (Dialog) builder.get_object ("xmodem_filename_dialog");
        dialog.set_transient_for(parent);
        xmodemFilename = (Gtk.Entry)builder.get_object ("xmodem_filename");
        dialog.delete_event.connect (hide);
        dialog.response.connect (response);
    }
    public void show ()
    {
        dialog.run ();
    }

    public bool hide ()
    {
        dialog.hide ();
        return true;
    }

    private void response (Widget w, int r)
    {
        filename = xmodemFilename.get_text ();
        hide ();
        if (filename == "")
            filename = "xmodem.file";
    }
}
