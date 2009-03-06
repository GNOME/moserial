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
