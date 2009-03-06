using Gtk;
public class moserial.XmodemFilenameDialog : GLib.Object
{
        public Builder builder {get; construct;}
        private Dialog dialog;
	private Gtk.Entry xmodemFilename;
	public string filename;
        public XmodemFilenameDialog(Builder builder) {
                this.builder=builder;
        }
	construct {
		dialog = (Dialog)builder.get_object("xmodem_filename_dialog");
		xmodemFilename = (Gtk.Entry)builder.get_object("xmodem_filename");
		dialog.delete_event += hide;
                dialog.response += response;
	}
	public void show() {
                dialog.run();
        }

        public bool hide(Widget w) {
                dialog.hide();
                return true;
        }
        
        private void response(Widget w, int r){
        	filename = xmodemFilename.get_text();
		hide(w);
		if(filename=="")
			filename="xmodem.file";
        }
}
