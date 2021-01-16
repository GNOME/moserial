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

using Gtk;

public class moserial.SerialStreamRecorder
{
    private GLib.File ? file;
    private string uri;
    private bool isOpen = false;
    private FileOutputStream ? fos;

    public enum Direction { INCOMING, OUTGOING, BOTH }
    public const string[] DirectionStrings = { GLib.N_ ("Incoming"),
                                               GLib.N_ ("Outgoing"),
                                               GLib.N_ ("Incoming and Outgoing")
                                             };

    private Direction direction;
    public void open (string filename, Direction direction) throws GLib.Error {
        try
        {
            file = File.new_for_path (filename);
            fos = file.replace (null, false, GLib.FileCreateFlags.NONE, null);
            isOpen = true;
            uri = file.get_uri ();
            this.direction = direction;
        } catch (GLib.Error e)
        {
            isOpen = false;
            file = null;
            fos = null;
            throw e;
        }
    }

    private void write (uchar data)
    {
        if (isOpen) {
            uchar[] o = new uchar[1];
            o[0] = data;
            try {
                fos.write (o, null);
            } catch (GLib.Error e) {
                stdout.printf (_("error: %s\n"), e.message);
            }
        }
    }

    private void write_array (uchar[] data)
    {
        if (isOpen) {
            try {
                fos.write (data, null);
            } catch (GLib.Error e) {
                stdout.printf (_("error: %s\n"), e.message);
            }
        }
    }

    public void writeOutgoing (uchar data)
    {
        if (isOpen && (direction == Direction.OUTGOING || direction == Direction.BOTH))
            write (data);
    }

    public void writeIncoming (uchar[] data)
    {
        if (isOpen && (direction == Direction.INCOMING || direction == Direction.BOTH))
            write_array (data);
    }

    public void close (bool launch)
    {
        if (isOpen) {
            try {
                fos.flush (null);
                fos.close (null);
            } catch (GLib.Error e) {
                stdout.printf (_("error: %s\n"), e.message);
                // Error closing the file?
            }

            /* TODO: allow this feature to be enabled / disabled */
            if (launch && (MoUtils.fileSize (uri) > 0)) {
                try {
                    show_uri_on_window (null, uri, Gdk.CURRENT_TIME);
                } catch (GLib.Error e) {
                    warning (_("Unable to launch %s: %s"), uri, e.message);
                }
            }
            fos = null;
            file = null;
            isOpen = false;
        }
    }
}
