using GLib;

public class Settings : GLib.Object
{
        public enum Parity {NONE, ODD, EVEN, MARK, SPACE}
        public enum Handshake {NONE, HARDWARE, SOFTWARE, BOTH}
        public enum AccessMode {READWRITE, READONLY, WRITEONLY}
        public static string DEFAULT_DEVICEFILE = "/dev/ttyS0";
        public static int DEFAULT_BAUDRATE = 1200;
        public static int DEFAULT_DATABITS = 8;
        public static int DEFAULT_STOPBITS = 1;
        public static Parity DEFAULT_PARITY = Parity.NONE;
        public static Handshake DEFAULT_HANDSHAKE = Handshake.HARDWARE;
        public static AccessMode DEFAULT_ACCESSMODE = AccessMode.READWRITE;
        public static bool DEFAULT_LOCAL_ECHO = false;
        public string? device {get; construct;}
        public int baudRate {get; construct;}
        public int dataBits {get; construct;}
        public int stopBits {get; construct;}
        public Parity parity {get; construct;}
        public Handshake handshake {get; construct;}
        public AccessMode accessMode {get; construct;}
        public bool localEcho {get; construct;}
        public Settings(string? device, int baudRate, int dataBits, int stopBits, Parity parity, Handshake handshake, AccessMode accessMode, bool localEcho) {
                this.device = device;
                this.baudRate = baudRate;
                this.dataBits = dataBits;
                this.stopBits = stopBits;
                this.parity = parity;
                this.handshake = handshake;
                this.accessMode = accessMode;
                this.localEcho = localEcho;
        }
        construct {
                if (device==null)
                        device = DEFAULT_DEVICEFILE;
                if (baudRate==0)
                        baudRate = DEFAULT_BAUDRATE;
                if (dataBits==0)
                        dataBits = DEFAULT_DATABITS;
                if (stopBits==0)
                        stopBits = DEFAULT_STOPBITS;
        }

        public string parityToChar() {
                switch (parity) {
                case Parity.NONE: {
			/* TRANSLATORS: first letter of "None", a serial port parity setting */
                        return _("N");
                }
                case Parity.ODD: {
			/* TRANSLATORS: first letter of "Odd", a serial port parity setting */
                        return _("O");
                }
                case Parity.EVEN: {
			/* TRANSLATORS: first letter of "Even", a serial port parity setting */
                        return _("E");
                }
                case Parity.MARK: {
			/* TRANSLATORS: first letter of "Mark", a serial port parity setting */
                        return _("M");
                }
                case Parity.SPACE: {
			/* TRANSLATORS: first letter of "Space", a serial port parity setting */
                        return _("S");
                }
                }
                return "?";
        }

        public string getStatusbarString(bool open) {
                string r;
                r="%s".printf(device);
                if (open)
                        r=r+" "+_("OPEN")+" ";
                else r=r+" "+_("CLOSED")+" ";
                r=r+"%i,%i%s%i".printf(baudRate, dataBits, parityToChar(), stopBits);
                return r;
        }
        
        public void saveToProfile(Profile profile) {
        	profile.keyFile.set_string("port_settings", "device", device);
	       	profile.keyFile.set_integer("port_settings", "baud_rate", baudRate);
	       	profile.keyFile.set_integer("port_settings", "data_bits", dataBits);
	       	profile.keyFile.set_integer("port_settings", "stop_bits", stopBits);
	       	profile.keyFile.set_integer("port_settings", "parity", parity);
	       	profile.keyFile.set_integer("port_settings", "handshake", handshake);
	       	profile.keyFile.set_integer("port_settings", "access_mode", accessMode);
	       	profile.keyFile.set_boolean("port_settings", "local_echo", localEcho);
        }
        
        public static Settings loadFromProfile(Profile profile) {
       		string? device=Settings.DEFAULT_DEVICEFILE;
        	int baudRate;
        	int dataBits;
        	int stopBits;
        	Parity parity;
        	Handshake handshake;
        	AccessMode accessMode;
		bool localEcho;

		device = MoUtils.getKeyString(profile, "port_settings", "device");	
		baudRate = MoUtils.getKeyInteger(profile, "port_settings", "baud_rate", Settings.DEFAULT_BAUDRATE);
		dataBits = MoUtils.getKeyInteger(profile, "port_settings", "data_bits", Settings.DEFAULT_DATABITS);
		stopBits = MoUtils.getKeyInteger(profile, "port_settings", "stop_bits", Settings.DEFAULT_STOPBITS);
		parity = (Settings.Parity)MoUtils.getKeyInteger(profile, "port_settings", "parity", Settings.DEFAULT_PARITY);
		handshake = (Settings.Handshake)MoUtils.getKeyInteger(profile, "port_settings", "handshake", Settings.DEFAULT_HANDSHAKE);
		accessMode = (Settings.AccessMode)MoUtils.getKeyInteger(profile, "port_settings", "access_mode", Settings.DEFAULT_ACCESSMODE);
		localEcho = MoUtils.getKeyBoolean(profile, "port_settings", "local_echo", Settings.DEFAULT_LOCAL_ECHO);

		return new Settings(device, baudRate, dataBits, stopBits, parity, handshake, accessMode, localEcho);
	
	}
        
}
