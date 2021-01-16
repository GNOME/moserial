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
using GLib;

public class moserial.HexTextBuffer : TextBuffer
{
    private TextMark nextHexMark;
    private TextMark nextCharMark;
    private TextTag addressTag;
    private int hexBytes;
    construct {
        setup ();
        addressTag = this.create_tag ("hex_address", "foreground", "#2020ff", null);
    }
    public void applyPreferences (Preferences preferences)
    {
        addressTag.foreground = preferences.highlightColor;
    }

    public void clear ()
    {
        this.delete_mark (nextHexMark);
        this.delete_mark (nextCharMark);
        this.set_text ("", 0);
        setup ();
    }

    private void setup ()
    {
        TextIter nextHexIter;
        TextIter nextCharIter;
        this.get_end_iter (out nextHexIter);
        nextHexMark = new TextMark ("nextHex", true);
        this.add_mark (nextHexMark, nextHexIter);
        nextCharIter = nextHexIter;
        nextCharMark = new TextMark ("nextChar", true);
        this.add_mark (nextCharMark, nextCharIter);
        hexBytes = 0;
    }

    public void add (uchar data)
    {
        TextIter nextHexIter;
        TextIter nextCharIter;
        string incomingHexBuffer = "";

        // Every insert or delete operation invalidates TextIters and they must be recovered.

        if ((hexBytes % 16) == 0) {
            // Mark start
            TextIter startIter;
            this.get_iter_at_mark (out nextCharIter, nextCharMark);
            TextMark startMark = new TextMark ("startMark", true);
            this.add_mark (startMark, nextCharIter);

            // Insert offset info (hexBytes)
            this.insert (ref nextCharIter, "\n%08x".printf (hexBytes), 9);
            this.get_end_iter (out nextCharIter);

            // Format offset info
            this.get_iter_at_mark (out startIter, startMark);
            this.apply_tag_by_name ("hex_address", startIter, nextCharIter);
            this.delete_mark (startMark);

            // Blank space
            this.insert (ref nextCharIter, " ", 1);
            this.get_end_iter (out nextCharIter);

            // Save current position in nextHexMark
            this.delete_mark (nextHexMark);
            nextHexIter = nextCharIter;
            nextHexMark = new TextMark ("nextHex", true);
            this.add_mark (nextHexMark, nextHexIter);

            // Put 51 blank spaces
            this.insert (ref nextCharIter, "                                                   ", 51);
            this.get_end_iter (out nextCharIter);
            // Save current nextCharMark
            this.delete_mark (nextCharMark);
            nextCharMark = new TextMark ("nextChar", true);
            this.add_mark (nextCharMark, nextCharIter);
        } else if ((hexBytes % 8) == 0) {
            // Every 8 characters put a separation of 2 spaces
            this.get_iter_at_mark (out nextHexIter, nextHexMark);
            this.insert (ref nextHexIter, "  ", 2);
            this.get_iter_at_mark (out nextHexIter, nextHexMark);
            nextHexIter.forward_chars (2);
            // Save current nextHexMark
            this.delete_mark (nextHexMark);
            nextHexMark = new TextMark ("nextHex", true);
            this.add_mark (nextHexMark, nextHexIter);
            // Remove space to align chars
            TextIter tempIter;
            tempIter = nextHexIter;
            tempIter.forward_chars (2);
            this.delete (ref nextHexIter, ref tempIter);
        }
        // Put hex data at nextHexMark
        this.get_iter_at_mark (out nextHexIter, nextHexMark);
        incomingHexBuffer += "%02X ".printf (data);
        this.insert (ref nextHexIter, incomingHexBuffer, (int) incomingHexBuffer.length);

        this.get_iter_at_mark (out nextHexIter, nextHexMark);
        nextHexIter.forward_chars (incomingHexBuffer.length);
        // Save current nextHexMark
        this.delete_mark (nextHexMark);
        nextHexMark = new TextMark ("nextHex", true);
        this.add_mark (nextHexMark, nextHexIter);
        // Remove space to align chars
        TextIter tempIter;
        tempIter = nextHexIter;
        tempIter.forward_chars (3);
        this.delete (ref nextHexIter, ref tempIter);
        incomingHexBuffer = "";
        hexBytes++;

        // Place character at nextCharMark
        this.get_iter_at_mark (out nextCharIter, nextCharMark);
        unichar c = "%c".printf (data).get_char ();
        string s = "%c".printf (data);
        if (s.validate () && c.isprint ()) {
            this.insert (ref nextCharIter, s, (int) s.length);
            this.get_iter_at_mark (out nextCharIter, nextCharMark);
            nextCharIter.forward_chars (s.length);
        } else {
            this.insert (ref nextCharIter, ".", 1);
            this.get_iter_at_mark (out nextCharIter, nextCharMark);
            nextCharIter.forward_chars (1);
        }
        // Save current nextCharMark
        this.delete_mark (nextCharMark);
        nextCharMark = new TextMark ("nextChar", true);
        this.add_mark (nextCharMark, nextCharIter);
    }
}
