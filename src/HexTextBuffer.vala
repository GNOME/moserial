using Gtk;
using GLib;

public class moserial.HexTextBuffer : TextBuffer
{
	private TextMark nextHexMark;
        private TextMark nextCharMark;
        private TextTag addressTag;
        private TextTag oddTag;
        private int hexBytes;
        construct {
		setup();
     	        addressTag = this.create_tag("hex_address", "foreground", "#2020ff", null);
     	        oddTag = this.create_tag("hex_odd", "foreground", "#2020ff", null);
     	        
        }
        public void applyPreferences(Preferences preferences) {
        	addressTag.foreground=preferences.highlightColor;
	       	oddTag.foreground=preferences.highlightColor;
        }
        public void clear() {
        	this.delete_mark(nextHexMark);
        	this.delete_mark(nextCharMark);
		this.set_text("", 0);
		setup();
        }
        private void setup() {
		TextIter nextHexIter;
		TextIter nextCharIter;
	        this.get_end_iter(out nextHexIter);
	        nextHexMark = new TextMark("nextHex", true);
	        this.add_mark(nextHexMark, nextHexIter);
	        nextCharIter=nextHexIter;
	        nextCharMark = new TextMark("nextChar", true);
     	        this.add_mark(nextCharMark, nextCharIter);
     	        hexBytes=0;
        }
        public void add(uchar data) {
		TextIter nextHexIter;
        	TextIter nextCharIter;
        	string incomingHexBuffer = "";
        	if((hexBytes % 16)==0 ){
                                TextIter startIter;
	                        this.get_iter_at_mark(out nextCharIter, nextCharMark);
                        	TextMark startMark = new TextMark("startMark", true);
                        	this.add_mark(startMark, nextCharIter);
	                        this.insert(nextCharIter, "\n%08x".printf(hexBytes), 9);
	                        this.get_iter_at_mark(out startIter, startMark);
	                        this.apply_tag_by_name("hex_address", startIter, nextCharIter);
	                        this.delete_mark(startMark);
	                        this.insert(nextCharIter, " ", 1);
	                        this.delete_mark(nextHexMark);
	                        nextHexIter=nextCharIter;
				nextHexMark = new TextMark("nextHex", true);
	                        this.add_mark(nextHexMark, nextHexIter);
	                        this.insert(nextCharIter, "                                                   ", 51);
	                        this.delete_mark(nextCharMark);
	                        nextCharMark = new TextMark("nextChar", true);
	                        this.add_mark(nextCharMark, nextCharIter);
	                }
                        else if((hexBytes % 8)==0) {
	                        this.get_iter_at_mark(out nextHexIter, nextHexMark);
	                        this.insert(nextHexIter, "  ", 2);
	                        TextIter tempIter;
	                        //remove space to align chars
	                        tempIter = nextHexIter;
        	                tempIter.forward_chars(2);
        	                this.delete(nextHexIter, tempIter);
	                        this.delete_mark(nextHexMark);
	                        nextHexMark = new TextMark("nextHex", true);
	                        this.add_mark(nextHexMark, nextHexIter);
			}
			this.get_iter_at_mark(out nextHexIter, nextHexMark);
                        incomingHexBuffer+="%02X ".printf(data);
                        this.insert(nextHexIter, incomingHexBuffer, (int)incomingHexBuffer.length);
                        //remove space to align chars
                        TextIter tempIter;
                        tempIter = nextHexIter;
                        tempIter.forward_chars(3);
                        this.delete(nextHexIter, tempIter);
			//add odd coloring
			/*if(((hexBytes+1)%2)==0) {
	      	                tempIter.backward_chars(3);
	      	                this.apply_tag_by_name("hex_odd", tempIter, nextHexIter);
      	                }*/
                        incomingHexBuffer="";
                        hexBytes++;
                        this.delete_mark(nextHexMark);
                        nextHexMark = new TextMark("nextHex", true);
                        this.add_mark(nextHexMark, nextHexIter);
                        
                        this.get_iter_at_mark(out nextCharIter, nextCharMark);
                        unichar c = "%c".printf(data).get_char();
                        string s = "%c".printf(data);
                        if(s.validate() && c.isprint())
	                        this.insert(nextCharIter, s, (int)s.length);
                        else
	                        this.insert(nextCharIter, ".", 1);
			
			this.delete_mark(nextCharMark);
                        nextCharMark = new TextMark("nextChar", true);
                        this.add_mark(nextCharMark, nextCharIter);
        }
}
