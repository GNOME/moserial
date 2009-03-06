using Gtk;
public class moserial.ReceiveProgressDialog : GLib.Object
{
        public Builder builder {get; construct;}
        private Dialog dialog;
        private Button cancelButton;
        private Gtk.Label status;
        private ProgressBar progressBar;
        signal void transferCanceled();
        public ReceiveProgressDialog(Builder builder) {
                this.builder=builder;
        }
        construct {
                dialog = (Dialog)builder.get_object("receive_progress_dialog");
                cancelButton = (Button)builder.get_object("receive_progress_cancel");
                cancelButton.clicked += this.cancel;
                status = (Gtk.Label)builder.get_object("receive_statusbox");
                progressBar = (ProgressBar)builder.get_object("receive_progressbar");
                dialog.delete_event += hide;

        }
        public void show() {
                dialog.show_all();
                status.set_text("");
        }

        public bool hide(GLib.Object o) {
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
