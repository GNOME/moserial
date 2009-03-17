using Gtk;

class moserial.Main : GLib.Object
{
        static string profileFilename;
        const OptionEntry[] options = {
                { "profile", 'p', 0, OptionArg.FILENAME, out profileFilename, N_("Profile file to load"), "foo.conf" },
                { null }
        };
        public void run() {

                moserial.MainWindow mainWindow;
                Builder builder = new Builder();
                try {
                        builder.add_from_file(Config.MOSERIAL_GLADEDIR + "/moserial.ui");
                } catch (Error e) {
                        var msg = new MessageDialog (null, DialogFlags.MODAL, MessageType.ERROR, ButtonsType.CANCEL, _("Failed to load UI\n%s"), e.message);
                        msg.run ();
                }
                if(!(profileFilename==null) && (!GLib.Path.is_absolute(profileFilename)))
                		profileFilename=GLib.Path.build_filename(GLib.Environment.get_current_dir(), profileFilename);
                mainWindow = new moserial.MainWindow(builder, profileFilename);
                mainWindow.showWindow();
        }
        public static int main (string[] args) {
                Gtk.init (ref args);
                OptionContext context = new OptionContext(_("- moserial serial terminal"));
                context.add_main_entries (options, null);
                context.add_group (Gtk.get_option_group(true));
                try {
                        if (!context.parse (ref args)) {
                                stdout.printf (_("Run '%s --help' to see a full list of available command line options.\n"), args[0]);
                        } else {
                                Main app = new Main();
                                app.run();
                                Gtk.main ();
                        }
                } catch (GLib.OptionError e) {
                        stdout.printf ("%s\n", e.message);
                        stdout.printf (_("Run '%s --help' to see a full list of available command line options.\n"), args[0]);
                }
                return 0;
        }
}
