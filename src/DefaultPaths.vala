using GLib;
public class DefaultPaths : GLib.Object
{
        public string? recordTo { get; set; }
        public string? receiveTo {get; set; }
        public string? sendFrom {get; set; }

        public DefaultPaths (string? RecordTo, string? ReceiveTo, string? SendFrom) {
                this.recordTo=RecordTo;
                this.receiveTo=ReceiveTo;
                this.sendFrom=SendFrom;
        }

        public void saveToProfile(Profile profile) {
                if (recordTo != null)
                        profile.keyFile.set_string("paths", "last_record_path", recordTo);
                if (receiveTo != null)
                        profile.keyFile.set_string("paths", "last_receive_path", receiveTo);
                if (sendFrom != null)
                        profile.keyFile.set_string("paths", "last_send_path", sendFrom);
        }

        public static DefaultPaths loadFromProfile(Profile profile) {
                string? RecordTo = null;
                string? ReceiveTo = null;
                string? SendFrom = null;

                RecordTo = getPath (profile, "paths", "last_record_path");
                ReceiveTo = getPath (profile, "paths", "last_receive_path");
                SendFrom = getPath (profile, "paths", "last_send_path");

                return new DefaultPaths (RecordTo, ReceiveTo, SendFrom);
        }

        public static string? getPath (Profile profile, string group, string key) {
                string? path = null;
                try {
                        path = profile.keyFile.get_string(group, key);
                        if (!MoUtils.fileExists(path))
                                return null;
                } catch (GLib.KeyFileError e) {
                        //stdout.printf("%s\n", e.message);
                }
                return path;
        }
}

