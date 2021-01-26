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

using GLib;

public class Settings : GLib.Object
{
    public enum Parity { NONE, ODD, EVEN, MARK, SPACE }
    public const string[] ParityModeStrings = { GLib.N_ ("None"),
                                                GLib.N_ ("Odd"),
                                                GLib.N_ ("Even"),
                                                GLib.N_ ("Mark"),
                                                GLib.N_ ("Space")
                                              };

    public enum Handshake { NONE, HARDWARE, SOFTWARE, BOTH }

    public enum AccessMode { READWRITE, READONLY, WRITEONLY }
    public const string[] AccessModeStrings = { GLib.N_ ("Read and Write"),
                                                GLib.N_ ("Read Only"),
                                                GLib.N_ ("Write Only")
                                              };

    public const string[] DataBitItems = { "5", "6", "7", "8" };
    public const string[] StopBitItems = { "1", "2" };
    public const string[] BaudRateItems = { "300", "600", "1200", "2400",
                                            "4800", "9600", "19200",
                                            "38400", "57600", "115200",
                                            "230400", "460800", "576000",
                                            "921600", "1000000", "2000000",
                                            "3000000"
                                          };

    public static string DEFAULT_DEVICEFILE = "/dev/ttyS0";
    public static int DEFAULT_BAUDRATE = 1200;
    public static int DEFAULT_DATABITS = 8;
    public static int DEFAULT_STOPBITS = 1;
    public static Parity DEFAULT_PARITY = Parity.NONE;
    public static Handshake DEFAULT_HANDSHAKE = Handshake.HARDWARE;
    public static AccessMode DEFAULT_ACCESSMODE = AccessMode.READWRITE;
    public static bool DEFAULT_LOCAL_ECHO = false;
    public static bool DEFAULT_AUTO_CONNECT = false;
    public string ? device { get; construct; }
    public int baudRate { get; construct; }
    public int dataBits { get; construct; }
    public int stopBits { get; construct; }
    public Parity parity { get; construct; }
    public Handshake handshake { get; construct; }
    public AccessMode accessMode { get; construct; }
    public bool localEcho { get; construct; }
    public bool autoConnect {get; construct; }
    public Settings (string ? device, int baudRate, int dataBits, int stopBits, Parity parity, Handshake handshake, AccessMode accessMode, bool localEcho, bool autoConnect)
    {
        GLib.Object (device: device,
                     baudRate: baudRate,
                     dataBits: dataBits,
                     stopBits: stopBits,
                     parity: parity,
                     handshake: handshake,
                     accessMode: accessMode,
                     localEcho: localEcho,
                     autoConnect: autoConnect);
    }

    construct {
        if (device == null)
            device = DEFAULT_DEVICEFILE;
        if (baudRate == 0)
            baudRate = DEFAULT_BAUDRATE;
        if (dataBits == 0)
            dataBits = DEFAULT_DATABITS;
        if (stopBits == 0)
            stopBits = DEFAULT_STOPBITS;
    }

    public string parityToChar ()
    {
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

    public string getStatusbarString (bool open)
    {
        string r;
        r = "%s".printf (device);
        if (open)
            r = r + " " + _("OPEN") + " ";
        else r = r + " " + _("CLOSED") + " ";
        r = r + "%i,%i%s%i".printf (baudRate, dataBits, parityToChar (), stopBits);
        return r;
    }

    public void saveToProfile (Profile profile)
    {
        profile.setString ("port_settings", "device", device);
        profile.setInteger ("port_settings", "baud_rate", baudRate);
        profile.setInteger ("port_settings", "data_bits", dataBits);
        profile.setInteger ("port_settings", "stop_bits", stopBits);
        profile.setInteger ("port_settings", "parity", parity);
        profile.setInteger ("port_settings", "handshake", handshake);
        profile.setInteger ("port_settings", "access_mode", accessMode);
        profile.setBoolean ("port_settings", "local_echo", localEcho);
        profile.setBoolean ("port_settings", "auto_connect", autoConnect);
    }

    public static Settings loadFromProfile (Profile profile)
    {
        string ? device = Settings.DEFAULT_DEVICEFILE;
        int baudRate;
        int dataBits;
        int stopBits;
        Parity parity;
        Handshake handshake;
        AccessMode accessMode;
        bool localEcho;
        bool autoConnect;

        device = profile.getString ("port_settings", "device");
        baudRate = profile.getInteger ("port_settings", "baud_rate", Settings.DEFAULT_BAUDRATE);
        dataBits = profile.getInteger ("port_settings", "data_bits", Settings.DEFAULT_DATABITS);
        stopBits = profile.getInteger ("port_settings", "stop_bits", Settings.DEFAULT_STOPBITS);
        parity = (Settings.Parity)profile.getInteger ("port_settings", "parity", Settings.DEFAULT_PARITY);
        handshake = (Settings.Handshake)profile.getInteger ("port_settings", "handshake", Settings.DEFAULT_HANDSHAKE);
        accessMode = (Settings.AccessMode)profile.getInteger ("port_settings", "access_mode", Settings.DEFAULT_ACCESSMODE);
        localEcho = profile.getBoolean ("port_settings", "local_echo", Settings.DEFAULT_LOCAL_ECHO);
        autoConnect = profile.getBoolean ("port_settings", "auto_connect", Settings.DEFAULT_AUTO_CONNECT);

        return new Settings (device, baudRate, dataBits, stopBits, parity, handshake, accessMode, localEcho, autoConnect);
    }
}
