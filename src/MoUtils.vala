using GLib;
public class MoUtils : GLib.Object
{
	public static GLib.File newFile (string path) {
		string uri;
                if ("://" in path)
                	uri = path;
                else
                        uri = "file://%s".printf(path);
                return File.new_for_uri(uri);
	}

	public static bool fileExists (string path) {
		GLib.File file=newFile(path);
		return file.query_exists(null);
	}

	public static int64 fileSize (string path) {
		GLib.File file=newFile(path);
		try {
			GLib.FileInfo info=file.query_info(GLib.FILE_ATTRIBUTE_STANDARD_SIZE,0,null);
			return info.get_size();
                } catch (GLib.Error e) {
                        warning("%s", e.message);
                }
		return 0;
	}

        public static string getParentFolder (string path) {
                GLib.File file=newFile(path);
		GLib.File parent=file.get_parent();
		return parent.get_parse_name();
        }
	
	public static string? getKeyString (Profile profile, string group, string key) {
		string? result=null;
                try {
                        result = profile.keyFile.get_string(group, key);
                }
                catch (GLib.KeyFileError e) {
                        stdout.printf("%s\n", e.message);
                }
		return result;
	}

        public static int getKeyInteger (Profile profile, string group, string key, int default_val) {
                int result=default_val;
                try {
                        result = profile.keyFile.get_integer(group, key);
                }
                catch (GLib.KeyFileError e) {
                        stdout.printf("%s\n", e.message);
                }
		return result;
	}

        public static bool getKeyBoolean (Profile profile, string group, string key, bool default_val) {
                bool result=default_val;
                try {
                        result = profile.keyFile.get_boolean(group, key);
                }
                catch (GLib.KeyFileError e) {
                        stdout.printf("%s\n", e.message);
                }
		return result;
	}

	public static string? getLastMessage (string? messages) {
		string? message=null;
		string? escaped=messages.escape("");
		escaped=InputParser.statusReplace(escaped);
		string[] splitMessages;
		splitMessages = escaped.split("\\n", 20);
		for(int x=0; x<GLib.strv_length(splitMessages); x++) {
			if(splitMessages[x].length > 5)
				message=splitMessages[x];
		}
		return message;
	}
}

