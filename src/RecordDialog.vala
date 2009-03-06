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

        public bool hide(Widget w) {
                dialog.hide();
                return true;
        }
        
        private void response(Widget w, int r){
        	if(r == Gtk.ResponseType.CANCEL) {
        		fileName=null;
        		hide(w);
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
		        hide(w);
		        startRecording(this.fileName, direction);
	        }
	        else {
		        stopRecording();
	        }
        }
}
