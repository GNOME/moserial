using Gtk;

public class moserial.SerialStreamRecorder {
	private GLib.File? file;
	private string uri;
	private bool isOpen=false;
	private FileOutputStream? fos;
	public static enum Direction { INCOMING, OUTGOING, BOTH, NULL }
	private Direction direction;
	public void open (string filename, Direction direction) throws GLib.Error {
		try {
			file = File.new_for_path(filename);
			fos = file.replace(null, false, GLib.FileCreateFlags.NONE, null);
			isOpen=true;
			uri = file.get_uri();
			this.direction=direction;
		}
		catch(GLib.Error e) {
			isOpen=false;
			file=null;
			fos=null;
			throw e;
		}
	}
	private void write(uchar data) {
		if(isOpen) {
			uchar[] o = new uchar[1];
			o[0]=data;
			try {
				fos.write(o, 1, null);
			}
			catch(GLib.Error e) {
				stdout.printf(_("error: %s\n"), e.message);
				// What should be done here?
			}
		}
	
	}
	public void writeOutgoing(uchar data) {
		if(isOpen && (direction==Direction.OUTGOING || direction==Direction.BOTH))
			write(data);
	}
	public void writeIncoming(uchar data) {
		if(isOpen && (direction==Direction.INCOMING || direction==Direction.BOTH))
			write(data);
	}
	public void close (bool launch){
		if(isOpen) {
			try {
				fos.flush(null);
				fos.close(null);
			}
			catch(GLib.Error e) {
				stdout.printf(_("error: %s\n"), e.message);
				// Error closing the file?
			}

			/* TODO: allow this feature to be enabled / disabled */
			if(launch && (MoUtils.fileSize(uri)>0)) {
				try {
					show_uri(null, uri,  Gdk.CURRENT_TIME);
				} catch (GLib.Error e) {
					warning(_("Unable to launch %s: %s"), uri, e.message);
				}
			}
			fos=null;
			file = null;
			isOpen=false;
		}
	}
}
