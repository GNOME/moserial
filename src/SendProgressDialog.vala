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
public class moserial.SendProgressDialog : GLib.Object
{
    private Dialog dialog;
    private Button cancelButton;
    private Gtk.Label status;
    private ProgressBar progressBar;
    public signal void transferCanceled ();

    public SendProgressDialog (Window parent)
    {
        var builder = new Gtk.Builder.from_resource (Config.UIROOT + "send_progress_dialog.ui");

        dialog = (Dialog) builder.get_object ("send_progress_dialog");
        dialog.set_transient_for(parent);
        cancelButton = (Button) builder.get_object ("send_progress_cancel");
        cancelButton.clicked.connect (this.cancel);
        status = (Gtk.Label)builder.get_object ("send_statusbox");
        progressBar = (ProgressBar) builder.get_object ("send_progressbar");
        dialog.delete_event.connect (hide);
    }
    public void show ()
    {
        dialog.show_all ();
        status.set_text (_("Waiting for remote host"));
    }

    public bool hide ()
    {
        dialog.hide ();
        return true;
    }

    public void updateStatus (GLib.Object o, string newStatus)
    {
        status.set_text (newStatus);
        progressBar.pulse ();
    }

    public void cancel (GLib.Object o)
    {
        // TODO: make canceling transfers actually work
        transferCanceled ();
    }
}
