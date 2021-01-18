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

using Posix;
using Linux;

public class moserial.SerialConnection : GLib.Object
{
    private bool connected;
    public ulong tx = 0;
    public ulong rx = 0;
    public ulong nonprintable = 0;
    public bool forced_hex_view = false;
    public bool lastRxCharWasCR = false;

    public string echoReference = "";
    public string echoCompare = "";

    private Posix.termios newtio;
    private int m_fd = -1;
    private GLib.IOChannel IOChannelFd;
    public signal void newData (uchar[] data, int size);
    public signal void onError();

    private int flags = 0;

    public enum LineEnd { CRLF, CR, LF, TAB, ESC, NONE }
    public const string[] LineEndStrings = { GLib.N_ ("CR+LF end"),
                                             GLib.N_ ("CR end"),
                                             GLib.N_ ("LF end"),
                                             GLib.N_ ("TAB end"),
                                             GLib.N_ ("ESC end"),
                                             GLib.N_ ("No end")
                                           };
    public const string[] LineEndValues = { "\r\n", "\r", "\n", "\t", "\x1b", "" };
    public const int max_buf_size = 128;


    uint ? sourceId;
    uint? sourceIdErr;
    uint? sourceIdHup;
    uint? sourceIdNval;
    bool localEcho;
    public bool doConnect (Settings settings)
    {

        if (settings.accessMode == Settings.AccessMode.READWRITE)
            flags = Posix.O_RDWR;
        else if (settings.accessMode == Settings.AccessMode.READONLY)
            flags = Posix.O_RDONLY;
        else
            flags = Posix.O_WRONLY;

        m_fd = Posix.open (settings.device, flags | Posix.O_NONBLOCK);
        if (m_fd < 0) {
            m_fd = -1;
            // TODO display error in gui
            return false;
        }
        Posix.tcflush (m_fd, Posix.TCIOFLUSH);

        applySettings (settings);
        tcsetattr (m_fd, Posix.TCSANOW, newtio);

        connected = true;

        IOChannelFd = new GLib.IOChannel.unix_new (m_fd);
        sourceId = IOChannelFd.add_watch (GLib.IOCondition.IN, this.readBytes);
        // G_IO_ERR is sometimes faster than G_IO_HUP when device is unplugged
        sourceIdErr = IOChannelFd.add_watch(GLib.IOCondition.ERR, this.onUnplugged);
        // G_IO_HUP is received when the serial port vanishes (unplugged USB)
        sourceIdHup = IOChannelFd.add_watch(GLib.IOCondition.HUP, this.onUnplugged);
        // G_IO_NVAL is the last resort when device is unplugged and you want to write
        sourceIdNval = IOChannelFd.add_watch(GLib.IOCondition.NVAL, this.onUnplugged);
        localEcho = settings.localEcho;
        return true;
    }

    public void sendByte (uchar byte)
    {
        if (connected) {
            uchar[] b = new uchar[1];
            b[0] = byte;
            size_t x = Posix.write (m_fd, b, 1);
            // Posix.tcdrain(m_fd);

            tx = tx + x;
        }
    }

    public void sendBytes (char[] bytes, size_t size)
    {
        if (connected) {
            size_t x = Posix.write (m_fd, bytes, size);
            Posix.tcdrain (m_fd);
            tx = tx + x;
        }
    }

    public void doDisconnect ()
    {
        if (connected) {
            GLib.Source.remove(sourceId);
            GLib.Source.remove(sourceIdHup);
            GLib.Source.remove(sourceIdErr);
            GLib.Source.remove(sourceIdNval);
            sourceId = null;
            sourceIdHup = null;
            sourceIdErr = null;
            sourceIdNval = null;
            try {
                IOChannelFd.shutdown (true);
            } catch (GLib.IOChannelError e) {
                warning ("%s", e.message);
            }
            IOChannelFd = null;
            connected = false;
            forced_hex_view = false;
            lastRxCharWasCR = false;
            tx = rx = nonprintable = 0;
            echoReference = "";
            echoCompare = "";
            tcsetattr (m_fd, Posix.TCSANOW, newtio);
            Posix.close (m_fd);
        }
    }

    public bool isConnected ()
    {
        return connected;
    }

    private bool onUnplugged(GLib.IOChannel source, GLib.IOCondition condition)
    {
        onError();
        return false;
    }

    private bool readBytes (GLib.IOChannel source, GLib.IOCondition condition)
    {
        uchar[] m_buf = new uchar[max_buf_size];
        int bytesRead = (int) Posix.read (m_fd, m_buf, max_buf_size);
        rx += (ulong) bytesRead;

        while (Gtk.events_pending () || Gdk.events_pending ())
            Gtk.main_iteration_do (false);

        if (bytesRead < 0)
            return false;

        uchar[] sized_buf = new uchar[bytesRead];
        for (int x = 0; x < bytesRead; x++) {
            sized_buf[x] = m_buf[x];
        }

        newData (sized_buf, bytesRead);
        if (localEcho)
            sendBytes ((char[]) sized_buf, bytesRead);
        return connected;
    }

    private void applySettings (Settings settings)
    {
        // BaudRate
        uint baudRate = 0;
        switch (settings.baudRate) {
        case 300:
            baudRate = Posix.B300;
            break;
        case 600:
            baudRate = Posix.B600;
            break;
        case 1200:
            baudRate = Posix.B1200;
            break;
        case 2400:
            baudRate = Posix.B2400;
            break;
        case 4800:
            baudRate = Posix.B4800;
            break;
        case 9600:
            baudRate = Posix.B9600;
            break;
        case 19200:
            baudRate = Posix.B19200;
            break;
        case 38400:
            baudRate = Posix.B38400;
            break;
        case 57600:
            baudRate = Posix.B57600;
            break;
        case 115200:
            baudRate = Posix.B115200;
            break;
        case 230400:
            baudRate = Posix.B230400;
            break;
        case 460800:
            baudRate = Linux.Termios.B460800;
            break;
        case 576000:
            baudRate = Linux.Termios.B576000;
            break;
        case 921600:
            baudRate = Linux.Termios.B921600;
            break;
        case 1000000:
            baudRate = Linux.Termios.B1000000;
            break;
        case 2000000:
            baudRate = Linux.Termios.B2000000;
            break;
        case 3000000:
            baudRate = Linux.Termios.B3000000;
            break;
        default:
            baudRate = settings.baudRate;
            break;
        }

        Posix.cfsetospeed (ref newtio, baudRate);
        Posix.cfsetispeed (ref newtio, baudRate);

        Posix.cfmakeraw(ref newtio);
        newtio.c_cc[Posix.VTIME]=0;
        newtio.c_cc[Posix.VMIN]=1;

        // DataBits
        int dataBits;
        dataBits = settings.dataBits;
        // We generate mark and space parity
        if (settings.dataBits == 7 && (settings.parity == Settings.Parity.MARK || settings.parity == Settings.Parity.SPACE))
            dataBits = 8;

        switch (dataBits) {
        case 5:
            newtio.c_cflag = (newtio.c_cflag & ~Posix.CSIZE) | Posix.CS5;
            break;
        case 6:
            newtio.c_cflag = (newtio.c_cflag & ~Posix.CSIZE) | Posix.CS6;
            break;
        case 7:
            newtio.c_cflag = (newtio.c_cflag & ~Posix.CSIZE) | Posix.CS7;
            break;
        case 8:
        default:
            newtio.c_cflag = (newtio.c_cflag & ~Posix.CSIZE) | Posix.CS8;
            break;
        }
        newtio.c_cflag |= Posix.CLOCAL | Posix.CREAD;

        // Parity
        newtio.c_cflag &= ~(Posix.PARENB | Posix.PARODD);
        if (settings.parity == Settings.Parity.EVEN)
            newtio.c_cflag |= Posix.PARENB;
        else if (settings.parity == Settings.Parity.ODD)
            newtio.c_cflag |= (Posix.PARENB | Posix.PARODD);

        // Stop Bits
        if (settings.stopBits == 2)
            newtio.c_cflag |= Posix.CSTOPB;
        else
            newtio.c_cflag &= ~Posix.CSTOPB;

        // Handshake
        if (settings.handshake == Settings.Handshake.SOFTWARE || settings.handshake == Settings.Handshake.BOTH)
            newtio.c_iflag |= Posix.IXON | Posix.IXOFF;
        else
            newtio.c_iflag &= ~(Posix.IXON | Posix.IXOFF | Posix.IXANY);

        if (settings.handshake == Settings.Handshake.HARDWARE || settings.handshake == Settings.Handshake.BOTH)
            newtio.c_cflag |= Linux.Termios.CRTSCTS;
        else
            newtio.c_cflag &= ~Linux.Termios.CRTSCTS;

        int mcs = 0;
        Posix.ioctl (m_fd, Linux.Termios.TIOCMGET, out mcs);
        mcs |= Linux.Termios.TIOCM_RTS | Linux.Termios.TIOCM_DTR;
        Posix.ioctl (m_fd, Linux.Termios.TIOCMSET, ref mcs);
    }

    public void controlDTR (bool y)
    {
        int mcs = 0;
        Posix.ioctl (m_fd, Linux.Termios.TIOCMGET, out mcs);
        if (y) {
            mcs |= Linux.Termios.TIOCM_DTR;
        } else {
            mcs &= ~Linux.Termios.TIOCM_DTR;
        }
        Posix.ioctl (m_fd, Linux.Termios.TIOCMSET, ref mcs);
    }

    public void controlRTS (bool y)
    {
        int mcs = 0;
        Posix.ioctl (m_fd, Linux.Termios.TIOCMGET, out mcs);
        if (y) {
            mcs |= Linux.Termios.TIOCM_RTS;
        } else {
            mcs &= ~Linux.Termios.TIOCM_RTS;
        }
        Posix.ioctl (m_fd, Linux.Termios.TIOCMSET, ref mcs);
    }

    public bool[] getStatus ()
    {
        bool mcs[6];
        int stat;
        Posix.ioctl (m_fd, Linux.Termios.TIOCMGET, out stat);
        // GLib.print("stat %x\r\n",stat);
        if ((stat & 0x080) == 0) // Linux.Termios.TIOCM_RI=0x080
            mcs[0] = false;
        else
            mcs[0] = true;
        if ((stat & Linux.Termios.TIOCM_DSR) == 0)
            mcs[1] = false;
        else
            mcs[1] = true;
        if ((stat & 0x040) == 0) // Linux.Termios.TIOCM_CD=0x040
            mcs[2] = false;
        else
            mcs[2] = true;
        if ((stat & Linux.Termios.TIOCM_CTS) == 0)
            mcs[3] = false;
        else
            mcs[3] = true;
        if ((stat & Linux.Termios.TIOCM_RTS) == 0)
            mcs[4] = false;
        else
            mcs[4] = true;
        if ((stat & Linux.Termios.TIOCM_DTR) == 0)
            mcs[5] = false;
        else
            mcs[5] = true;
        return mcs;
    }

    public string getBytecountbarString ()
    {
        string r;

        if (nonprintable > 0)
            r = _("TX: %lu, RX: %lu (%lu unprintable)").printf (tx, rx, nonprintable);
        else
            r = _("TX: %lu, RX: %lu").printf (tx, rx);
        return r;
    }
}
