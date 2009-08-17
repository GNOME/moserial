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
