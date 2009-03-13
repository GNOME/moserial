public class moserial.SerialConnection : GLib.Object
{
        private bool connected;
	public ulong tx=0;
	public ulong rx=0;
	public ulong nonprintable=0;
	public bool forced_hex_view=false;
	public bool lastRxCharWasCR=false;

	public string echoReference="";
	public string echoCompare="";

        private POSIX.Termios newtio;
        private POSIX.Termios restoretio;
        private int m_fd=-1;
        private GLib.IOChannel IOChannelFd;
        signal void newData(uchar[100] data, int size);
        private  int flags=0;
	public enum LineEnd{ CRLF, CR, LF, TAB, NONE }
	uint? sourceId;
	bool localEcho;
        public bool doConnect (Settings settings) {

                if (settings.accessMode==Settings.AccessMode.READWRITE)
                        flags=POSIX.File.AccessMode.RDWR;
                else if (settings.accessMode==Settings.AccessMode.READONLY)
                        flags=POSIX.File.AccessMode.RDONLY;
                else
                        flags=POSIX.File.AccessMode.WRONLY;

                m_fd = POSIX.File.open(settings.device, flags | POSIX.File.FileStatus.NDELAY | POSIX.File.FileStatus.NONBLOCK);
                if (m_fd<0) {
                        m_fd=-1;
                        // TODO display error in gui
                        return false;
                }
                POSIX.Termios.flush(m_fd, POSIX.LineControl.IOFLUSH);
                int n = POSIX.File.fcntl(m_fd, POSIX.File.FDFlag.GETFL);
                POSIX.File.fcntl_with_arg(m_fd, POSIX.File.FDFlag.SETFL, n & ~POSIX.File.FileStatus.NDELAY);
		restoretio.get_attributes(m_fd);
                applySettings(settings);
                newtio.set_attribute(m_fd, POSIX.AttributeSelection.NOW);

                connected=true;

                IOChannelFd = new GLib.IOChannel.unix_new(m_fd);
                sourceId = IOChannelFd.add_watch(GLib.IOCondition.IN, this.readBytes);
                localEcho=settings.localEcho;
                return true;
        }
        
        public void sendByte(uchar byte)
        {
        	if(connected)
        	{
	        	uchar[] b = new uchar[1];
	        	b[0]=byte;
	        	size_t x = POSIX.File.write(m_fd, b, 1);
	        	//POSIX.Termios.drain(m_fd);
	        	
			tx=tx+x;
	        }
        }
        
        public void sendBytes(char[] bytes, size_t size)
        {
                if(connected)
        	{
        		size_t x = POSIX.File.write(m_fd, bytes, size);
	        	POSIX.Termios.drain(m_fd);
			tx=tx+x;
        	}
        }
	public string getLineEnd(int e)
	{
		string s;

		switch(e) {
			case LineEnd.CR: {
				s = "\r";
				break;
			}
                        case LineEnd.LF: {
                                s = "\n";
                                break;
                        }
                        case LineEnd.CRLF: {
                                s = "\r\n";
                                break;
                        }
                        case LineEnd.TAB: {
                                s = "\t";
                                break;
                        }
                        case LineEnd.NONE:
			default: {
				s = "";
                                break;
                        }
		}
		return s;
	}

        public void doDisconnect () {
        	if(connected) {
	        	GLib.Source.remove(sourceId);
	        	sourceId = null;
	        	try {
        		IOChannelFd.shutdown(true);
        		}
        		catch (GLib.IOChannelError e){
        			warning("%s", e.message);
        		}
	        	IOChannelFd=null;
	                connected=false;
			forced_hex_view=false;
			lastRxCharWasCR=false;
			tx=rx=nonprintable=0;
			echoReference="";
			echoCompare="";
        	        newtio.set_attribute(m_fd, POSIX.AttributeSelection.NOW);
        	        POSIX.File.close(m_fd);
        	}
        }

        private bool readBytes(GLib.IOChannel source, GLib.IOCondition condition) {
                uchar[1000] m_buf = new uchar[1000];
                int bytesRead=(int)POSIX.File.read(m_fd, m_buf, 1000);
		rx += (ulong) bytesRead;
                if (bytesRead<0)
                        return false;
                newData(m_buf, bytesRead);
                if(localEcho)
                	sendBytes((char[])m_buf, bytesRead);
                return connected;
        }
	
        private void applySettings(Settings settings) {
                //BaudRate
                uint baudRate = 0;
                switch (settings.baudRate) {
                case 300:
                        baudRate=POSIX.BaudRate.B300;
                        break;
                case 600:
                        baudRate=POSIX.BaudRate.B600;
                        break;
                case 1200:
                        baudRate=POSIX.BaudRate.B1200;
                        break;
                case 2400:
                        baudRate=POSIX.BaudRate.B2400;
                        break;
                case 4800:
                        baudRate=POSIX.BaudRate.B4800;
                        break;
                case 9600:
                        baudRate=POSIX.BaudRate.B9600;
                        break;
                case 19200:
                        baudRate=POSIX.BaudRate.B19200;
                        break;
                case 38400:
                        baudRate=POSIX.BaudRate.B38400;
                        break;
                case 57600:
                        baudRate=POSIX.BaudRate.B57600;
                        break;
                case 115200:
                        baudRate=POSIX.BaudRate.B115200;
                        break;
                case 230400:
                        baudRate=POSIX.BaudRate.B230400;
                        break;
                case 460800:
                        baudRate=POSIX.BaudRate.B460800;
                        break;
                case 576000:
                        baudRate=POSIX.BaudRate.B576000;
                        break;
                case 921600:
                        baudRate=POSIX.BaudRate.B921600;
                        break;
                }

                newtio.set_output_speed(baudRate);
                newtio.set_input_speed(baudRate);

                //DataBits
                int dataBits;
                dataBits = settings.dataBits;
                // We generate mark and space parity
                if (settings.dataBits == 7 && (settings.parity==Settings.Parity.MARK || settings.parity==Settings.Parity.SPACE))
                        dataBits=8;

                switch (dataBits) {
                case 5:
                        newtio.c_cflag = (newtio.c_cflag & ~POSIX.ControlMode.CSIZE) | POSIX.ControlMode.CS5;
                        break;
                case 6:
                        newtio.c_cflag = (newtio.c_cflag & ~POSIX.ControlMode.CSIZE) | POSIX.ControlMode.CS6;
                        break;
                case 7:
                        newtio.c_cflag = (newtio.c_cflag & ~POSIX.ControlMode.CSIZE) | POSIX.ControlMode.CS7;
                        break;
                case 8:
                default:
                        newtio.c_cflag = (newtio.c_cflag & ~POSIX.ControlMode.CSIZE) | POSIX.ControlMode.CS8;
                        break;
                }
                newtio.c_cflag |= POSIX.ControlMode.CLOCAL | POSIX.ControlMode.CREAD;

                //Parity
                newtio.c_cflag &= ~(POSIX.ControlMode.PARENB | POSIX.ControlMode.PARODD);
                if (settings.parity==Settings.Parity.EVEN)
                        newtio.c_cflag |= POSIX.ControlMode.PARENB;
                else if (settings.parity==Settings.Parity.ODD)
                        newtio.c_cflag |= (POSIX.ControlMode.PARENB | POSIX.ControlMode.PARODD);

                newtio.c_cflag &= ~POSIX.InputMode.CRTSCTS;


                //Stop Bits
                if (settings.stopBits==2)
                        newtio.c_cflag |= POSIX.ControlMode.CSTOPB;
                else
                        newtio.c_cflag &= ~POSIX.ControlMode.CSTOPB;

                //Input Settings
                newtio.c_iflag = POSIX.InputMode.IGNBRK;

                //Handshake
                if (settings.handshake==Settings.Handshake.SOFTWARE || settings.handshake == Settings.Handshake.BOTH)
                        newtio.c_iflag |= POSIX.InputMode.IXON | POSIX.InputMode.IXOFF;
                else
                        newtio.c_iflag &= ~(POSIX.InputMode.IXON | POSIX.InputMode.IXOFF | POSIX.InputMode.IXANY);

                newtio.c_lflag = 0;
                newtio.c_oflag = 0;

                newtio.c_cc[POSIX.Misc.VTIME]=1;
                newtio.c_cc[POSIX.Misc.VMIN]=1;
	
	
		//Some other port settings from minicom.
		
//		newtio.c_iflag &= ~(IGNBRK | IGNCR | INLCR | ICRNL | IUCLC | IXANY | IXON | IXOFF | INPCK | ISTRIP);
		//newtio.c_iflag &= ~(POSIX.InputMode.IGNBRK | POSIX.InputMode.IGNCR | POSIX.InputMode.INLCR | POSIX.InputMode.ICRNL | POSIX.InputMode.IXANY | POSIX.InputMode.IXON | POSIX.InputMode.IXOFF | POSIX.InputMode.INPCK | POSIX.InputMode.ISTRIP);
		//newtio.c_iflag |= (POSIX.InputMode.BRKINT | POSIX.InputMode.IGNPAR);
		//newtio.c_oflag &= ~POSIX.OutputMode.OPOST;
		//newtio.c_lflag &= ~(XCASE|ECHONL|NOFLSH);
		newtio.c_lflag &= ~(POSIX.LocalMode.ECHONL|POSIX.LocalMode.NOFLSH);
		//newtio.c_lflag &= ~(POSIX.LocalMode.ICANON | POSIX.LocalMode.ISIG | POSIX.LocalMode.ECHO);
		//newtio.c_cflag |= CREAD;
		//newtio.c_cc[VTIME] = 5;

                int mcs=0;
                POSIX.ioctl.ioctl(m_fd, POSIX.ioctl.TIOCMGET, out mcs);
                mcs |= POSIX.ioctl.TIOCM_RTS;
                POSIX.ioctl.ioctl(m_fd, POSIX.ioctl.TIOCMSET, out mcs);

                if (settings.handshake == Settings.Handshake.HARDWARE || settings.handshake == Settings.Handshake.BOTH)
                        newtio.c_cflag |= POSIX.InputMode.CRTSCTS;
                else
                        newtio.c_cflag &= ~POSIX.InputMode.CRTSCTS;
        }

        public string getBytecountbarString() {
                string r;

		if (nonprintable > 0)
			r = _("TX: %lu, RX: %lu (%lu unprintable)").printf(tx, rx, nonprintable);
		else
			r = _("TX: %lu, RX: %lu").printf(tx, rx);
                return r;
        }
}
