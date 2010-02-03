/*
 *  Copyright (C) 2009-2010 Michael J. Chudobiak.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Street #330, Boston, MA 02111-1307, USA.
 */

using Gtk;
public class moserial.AutoScroll : GLib.Object
{
        public static void scroll (Gtk.Adjustment va)	{
                va.value=va.upper-va.page_size;
        }

        public static void doAutoScroll (Gtk.Adjustment va) {
                if (va.value==va.upper-va.page_size) 
                                va.changed+=scroll;
                else
                                va.changed-=scroll;        
               }

        public static void setup(Gtk.Adjustment incomingAsciiVerticalAdjuster, Gtk.Adjustment incomingHexVerticalAdjuster, Gtk.Adjustment outgoingAsciiVerticalAdjuster, Gtk.Adjustment outgoingHexVerticalAdjuster) {
                incomingAsciiVerticalAdjuster.changed+=scroll;
                incomingAsciiVerticalAdjuster.value_changed+=doAutoScroll;

                incomingHexVerticalAdjuster.changed+=scroll;
                incomingHexVerticalAdjuster.value_changed+=doAutoScroll;

                outgoingAsciiVerticalAdjuster.changed+=scroll;
                outgoingAsciiVerticalAdjuster.value_changed+=doAutoScroll;

                outgoingHexVerticalAdjuster.changed+=scroll;
                outgoingHexVerticalAdjuster.value_changed+=doAutoScroll;
        }
}
