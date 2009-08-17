using Gtk;
public class moserial.ReceiveChooserDialog : GLib.Object
{
        public Builder builder {get; construct;}
        private FileChooserDialog dialog;
        public ComboBox protocolCombo;
        signal void startTransfer();
        public string path;
        public ReceiveChooserDialog(Builder builder) {
                this.builder=builder;
        }

        construct {
                dialog = (FileChooserDialog)builder.get_object("receive_chooser_dialog");
                protocolCombo = (ComboBox)builder.get_object("receive_chooser_protocol");
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
		        path = dialog.get_current_folder();
		        startTransfer();
	        }
	        else {
		        //
	        }	        	
        }
}
