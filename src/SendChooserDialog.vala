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
public class moserial.SendChooserDialog : GLib.Object
{
        public Builder builder {get; construct;}
        private FileChooserDialog dialog;
        public ComboBox protocolCombo;
        signal void startTransfer();
        public string filename;
        public SendChooserDialog(Builder builder) {
                this.builder=builder;
        }
        construct {
                dialog = (FileChooserDialog)builder.get_object("send_chooser_dialog");
                protocolCombo = (ComboBox)builder.get_object("send_chooser_protocol");
                dialog.delete_event += hide;
                dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.ACCEPT, null);
                protocolCombo.set_active(2);
                dialog.response += response;
        }

        public void show(string? folder) {
                if ((folder != null) && MoUtils.fileExists(folder))
                        dialog.set_current_folder(folder);
                dialog.run();
        }

        public bool hide() {
                dialog.hide();
                return true;
        }

        private void response(Widget w, int r){
        	if(r == Gtk.ResponseType.CANCEL) {
        		hide();
	        }
	        else if(r == Gtk.ResponseType.ACCEPT) {
		        hide();
		        filename = dialog.get_filename();
		        startTransfer();
	        }
	        else {
		        //
	        }
        }
}
