/*
 *  Copyright (C) 2009-2010 Michael J. Chudobiak.
 *
 *  This file is part of moserial.
 *
 *  moserial is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  moserial is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with moserial.  If not, see <http://www.gnu.org/licenses/>.
 */

// Class for communicating with the sz program
public class moserial.Szwrapper : GLib.Object
{
    public enum Protocol { XMODEM, YMODEM, ZMODEM, RAW, NULL }
    public const string[] ProtocolStrings = { GLib.N_ ("Xmodem"),
                                              GLib.N_ ("Ymodem"),
                                              GLib.N_ ("Zmodem"),
                                              GLib.N_ ("None (straight binary)")
                                            };

    public Protocol protocol { get; construct; }
    public SerialConnection ? sc { get; construct; }
    private IOChannel IOChannelInput;
    private IOChannel IOChannelOutput;
    private IOChannel IOChannelError;
    // int inputChannelId;
    uint outputChannelId;
    uint errorChannelId;
    private GLib.Pid pid;
    public signal void transferComplete ();
    public signal void updateStatus (string newStatus);

    public bool running = false;

    public string filename { get; construct; }
    public Szwrapper (Protocol ? protocol, SerialConnection ? sc, string ? filename)
    {
        Protocol pro = protocol;
        GLib.Object (protocol: pro,
                     sc: sc,
                     filename: filename);
    }
    construct {
        if (protocol == Protocol.NULL || filename == null)
        {
            running = false;
        } else
        {
            string[] argv;
            if (protocol == Protocol.RAW) {
                argv = new string[2];
                argv[0] = "cat";
                argv[1] = filename;
            } else {
                argv = new string[4];
                argv[0] = "sz";
                switch (protocol) {
                case Protocol.XMODEM:
                    argv[1] = "--xmodem";
                    break;
                case Protocol.YMODEM:
                    argv[1] = "--ymodem";
                    break;
                case Protocol.ZMODEM:
                default:
                    argv[1] = "--zmodem";
                    break;
                }
                argv[2] = "-vv";
                argv[3] = filename;
            }
            int output;
            int error;
            int input;
            // size_t bytesRead=0;
            // char[1000] m_buf = new char[1000];

            try {
                Process.spawn_async_with_pipes (null, argv, null, SpawnFlags.SEARCH_PATH, null, out pid, out input, out output, out error);

                IOChannelOutput = new GLib.IOChannel.unix_new (output);
                IOChannelInput = new GLib.IOChannel.unix_new (input);
                IOChannelError = new GLib.IOChannel.unix_new (error);
                IOChannelOutput.set_encoding (null);
                IOChannelOutput.set_flags (GLib.IOFlags.NONBLOCK);
                IOChannelError.set_encoding (null);
                IOChannelError.set_flags (GLib.IOFlags.NONBLOCK);
                IOChannelInput.set_encoding (null);
                // IOChannelInput.set_flags(GLib.IOFlags.NONBLOCK);

                outputChannelId = IOChannelOutput.add_watch (GLib.IOCondition.IN, this.readBytes);
                errorChannelId = IOChannelError.add_watch (GLib.IOCondition.IN, this.readError);
                running = true;
            } catch (GLib.SpawnError e) {
                running = false;
                stdout.printf ("spawn error: %s\n", e.message);
                var errorDialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.DESTROY_WITH_PARENT, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "%s", e.message);
                errorDialog.run ();
                errorDialog.destroy ();
            } catch (GLib.IOChannelError e) {
                stdout.printf ("readError() %s\n", e.message);
            }
        }
    }
    public void writeChar (uchar byte)
    {
        if (running) {
            size_t bytesWritten;
            char[] b = new char[1];
            b[0] = (char) byte;
            try {
                if (running)
                    IOChannelInput.write_chars (b, out bytesWritten);
                if (running)
                    IOChannelInput.flush ();
            } catch (GLib.IOChannelError e) {
                shutdown ();
                stdout.printf ("writeChar() %s\n", e.message);
            } catch (GLib.ConvertError e) {
                stdout.printf ("%s\n", e.message);
            }
        }
    }

    private bool readError (GLib.IOChannel source, GLib.IOCondition condition)
    {
        while (Gtk.events_pending () || Gdk.events_pending ())
            Gtk.main_iteration_do (false);
        if (running) {

            char[] m_buf = new char[1000];
            string messages = "";
            string message = "";
            size_t bytesRead = 0;
            if (!(condition == IOCondition.IN))
                return true;
            try {
                source.read_chars (m_buf, out bytesRead);
            } catch (ConvertError e) {
                stdout.printf ("%s\n", e.message);
            } catch (GLib.IOChannelError e) {
                stdout.printf ("readError() %s\n", e.message);
            }
            for (int x = 0; x < bytesRead; x++) {
                unichar c = m_buf[x];
                if (c.isprint () || c.isspace ())
                    messages = messages + "%c".printf (m_buf[x]);
            }
            message = MoUtils.getLastMessage (messages);
            if (!(message == ""))
                updateStatus (message);
            if (messages.index_of ("Transfer complete", 0) >= 0) {
                GLib.Timeout.add (2000, shutdown_timeout);                // Wait 2 seconds for for the final remote packet to get ackd
                // shutdown();
            }
            if (messages.index_of ("Transfer incomplete", 0) >= 0) {
                shutdown ();
            }
            return true;
        } else
            return false;
    }

    public void transferCanceled (GLib.Object o)
    {
        // send cancel string to remote client and rz

        if (running) {
            updateStatus (_("canceled"));
            if (protocol == Protocol.XMODEM || protocol == Protocol.YMODEM || protocol == Protocol.ZMODEM) {
                for (int x = 0; x < 20; x++) {
                    if (protocol == Protocol.ZMODEM) {
                        sc.sendByte ('X' & 037);
                        writeChar ('X' & 037);
                    } else
                        sc.sendByte (0x18);
                }
            }
            if (protocol == Protocol.XMODEM || protocol == Protocol.YMODEM || protocol == Protocol.RAW)
                shutdown ();
        }
    }

    private bool shutdown_timeout ()
    {
        shutdown ();
        return false;
    }

    private void shutdown ()
    {
        if (running) {
            running = false;
            GLib.Source.remove (outputChannelId);
            GLib.Source.remove (errorChannelId);
            Process.close_pid (pid);
            transferComplete ();
        }
    }

    private bool readBytes (GLib.IOChannel source, GLib.IOCondition condition)
    {
        while (Gtk.events_pending () || Gdk.events_pending ())
            Gtk.main_iteration_do (false);
        if (running) {

            char[] m_buf = new char[1024];

            size_t bytesRead = 0;
            if (!(condition == IOCondition.IN))
                return true;
            try {
                source.read_chars (m_buf, out bytesRead);
            } catch (ConvertError e) {
                stdout.printf ("%s\n", e.message);
            } catch (GLib.IOChannelError e) {
                stdout.printf ("readError() %s\n", e.message);
            }
            sc.sendBytes (m_buf, bytesRead);
            return true;
        } else
            return false;
    }
}
