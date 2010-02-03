/*
 *  Copyright (C) 2009-2010 Michael J. Chudobiak.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Street #330, Boston, MA 02111-1307, USA.
 */

using Gtk;
public class moserial.SendProgressDialog : GLib.Object
{
        public Builder builder {get; construct;}
        private Dialog dialog;
        private Button cancelButton;
        private Gtk.Label status;
        private ProgressBar progressBar;
        signal void transferCanceled();
        public SendProgressDialog(Builder builder) {
                this.builder=builder;
        }
        construct {
                dialog = (Dialog)builder.get_object("send_progress_dialog");
                cancelButton = (Button)builder.get_object("send_progress_cancel");
                cancelButton.clicked += this.cancel;
                status = (Gtk.Label)builder.get_object("send_statusbox");
                progressBar = (ProgressBar)builder.get_object("send_progressbar");
                dialog.delete_event += hide;

        }
        public void show() {
                dialog.show_all();
                status.set_text(_("Waiting for remote host"));
        }

        public bool hide() {
                dialog.hide_all();
                return true;
        }
        
        public void updateStatus(GLib.Object o, string newStatus) {
        	status.set_text(newStatus);
        	progressBar.pulse();
        }
        
        public void cancel(GLib.Object o) {
        	//TODO: make canceling transfers actually work
        	transferCanceled();
        }
}
