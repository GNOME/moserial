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
public class moserial.RecordDialog : GLib.Object
{
        public Builder builder {get; construct;}
        private FileChooserDialog dialog;
        private Button cancelButton;
        private ComboBox streamCombo;
        public string fileName { get; private set;}
        public signal void startRecording(string fileName, SerialStreamRecorder.Direction direction);
        public signal void stopRecording();
        public SerialStreamRecorder.Direction direction;
        public RecordDialog(Builder builder) {
                this.builder=builder;
        }
        construct {
                dialog = (FileChooserDialog)builder.get_object("record_dialog");
                cancelButton = (Button)builder.get_object("record_cancel");
                streamCombo = (ComboBox)builder.get_object("record_stream");
                dialog.delete_event += hide;
                dialog.response += response;
                dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_SAVE, Gtk.ResponseType.ACCEPT, null);
                dialog.set_do_overwrite_confirmation(true);
		dialog.set_local_only(false);
                streamCombo.set_active(0);
                fileName=null;
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
        		fileName=null;
        		hide();
        		stopRecording();
	        }
	        else if(r == Gtk.ResponseType.ACCEPT) {
		        fileName=dialog.get_filename();
		        switch(streamCombo.get_active())
		        {
		        	case 0:
		        	default:
		        		direction=SerialStreamRecorder.Direction.INCOMING;
		        		break;
		        	case 1:
		        		direction=SerialStreamRecorder.Direction.OUTGOING;
		        		break;
		        	case 2:
		        		direction=SerialStreamRecorder.Direction.BOTH;
		        		break;
		        }
		        hide();
		        startRecording(this.fileName, direction);
	        }
	        else {
		        stopRecording();
	        }
        }
}
