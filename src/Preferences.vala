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
public class Preferences : GLib.Object
{
    public static bool DEFAULT_USE_SYSTEM_MONOSPACE_FONT = true;
    public static string DEFAULT_FONT = "Monospace 10";
    public static string DEFAULT_FONT_COLOR = "black";
    public static string DEFAULT_BACKGROUND_COLOR = "white";
    public static string DEFAULT_HIGHLIGHT_COLOR = "#2020ff";
    public static bool DEFAULT_RECORD_LAUNCH = true;

    public bool useSystemMonospaceFont { get; construct; }
    public string ? font { get; construct; }
    public string ? fontColor { get; construct; }
    public string ? backgroundColor { get; construct; }
    public string ? highlightColor { get; construct; }
    public bool recordLaunch { get; construct; }
    public bool enableTimeout { get; construct; }
    public int timeout { get; construct; }
    public bool recordAutoName{get; construct;}
    public int recordAutoDirection{get; construct;}
    public string recordAutoExtension{get; construct;}
    public string recordAutoFolder{get; construct;}

    public Preferences (bool useSystemMonospaceFont, string? font,
                        string? fontColor,string? backgroundColor,
                        string? highlightColor, bool recordLaunch,
                        bool enableTimeout, int timeout,
                        bool recordAutoName, int recordAutoDirection,
                        string? recordAutoExtension,
                        string? recordAutoFolder)
    {
        GLib.Object (useSystemMonospaceFont: useSystemMonospaceFont,
                     font: font,
                     recordLaunch: recordLaunch,
                     fontColor: fontColor,
                     backgroundColor: backgroundColor,
                     highlightColor: highlightColor,
                     enableTimeout: enableTimeout,
                     timeout: timeout,
                     recordAutoName: recordAutoName,
                     recordAutoDirection: recordAutoDirection,
                     recordAutoExtension: recordAutoExtension,
                     recordAutoFolder: recordAutoFolder);
    }

    construct {
        if (font == null)
            font = DEFAULT_FONT;
        if (fontColor == null)
            fontColor = DEFAULT_FONT_COLOR;
        if (backgroundColor == null)
            backgroundColor = DEFAULT_BACKGROUND_COLOR;
        if (highlightColor == null)
            highlightColor = DEFAULT_HIGHLIGHT_COLOR;
        if(recordAutoExtension==null)
            recordAutoExtension="";
        if(recordAutoFolder==null)
            recordAutoFolder=Environment.get_home_dir ();
    }
    public static string getSystemDefaultMonospaceFont ()
    {

        var settings = new GLib.Settings ("org.gnome.desktop.interface");
        string value = settings.get_string ("monospace-font-name");

        if (value == "") {
            warning (_("Unable to retrieve system font setting"));
            value = DEFAULT_FONT;
        }

        return value;
    }

    public static Gdk.RGBA getGdkRGBA (string color)
    {
        Gdk.RGBA c = Gdk.RGBA ();
        c.parse (color);
        return c;
    }

    public void toString ()
    {
        stdout.printf ("useSystemMonospaceFont: ");
        if (useSystemMonospaceFont)
            stdout.printf ("true\n");
        else
            stdout.printf ("false\n");
        stdout.printf ("font: %s\n", font);
        stdout.printf ("fontColor: %s\n", fontColor);
        stdout.printf ("backgroundColor: %s\n", backgroundColor);
        stdout.printf ("highlightColor: %s\n", highlightColor);
        stdout.printf ("recordLaunch: ");
        if (recordLaunch)
            stdout.printf ("true\n");
        else
            stdout.printf ("false\n");
        stdout.printf("recordAutoName: ");
        if(recordAutoName)
            stdout.printf("true\n");
        else
            stdout.printf("false\n");
        stdout.printf("recordAutoDirection: %d\n", recordAutoDirection);
        stdout.printf("recordAutoExtension: %s\n", recordAutoExtension);
        stdout.printf("recordAutoFolder: %s\n", recordAutoFolder);
    }

    public void saveToProfile (Profile profile)
    {
        profile.setBoolean ("preferences", "use_system_monospace_font", useSystemMonospaceFont);
        profile.setString ("preferences", "font", font);
        profile.setString ("preferences", "font_color", fontColor);
        profile.setString ("preferences", "background_color", backgroundColor);
        profile.setString ("preferences", "highlight_color", highlightColor);
        profile.setBoolean ("preferences", "record_launch", recordLaunch);
        profile.setBoolean ("preferences", "enable_timeout", enableTimeout);
        profile.setInteger ("preferences", "timeout", timeout);
        profile.setBoolean("preferences", "record_auto_name", recordAutoName);
        profile.setInteger("preferences", "record_auto_direction", recordAutoDirection);
        profile.setString("preferences", "record_auto_extension", recordAutoExtension);
        profile.setString("preferences", "record_auto_folder", recordAutoFolder);
    }

    public static Preferences loadFromProfile (Profile profile)
    {
        bool useSystemMonospaceFont;
        string ? font = null;
        string ? fontColor = null;
        string ? backgroundColor = null;
        string ? highlightColor = null;
        bool recordLaunch;
        bool enableTimeout;
        int timeout;
        bool recordAutoName;
        int recordAutoDirection;
        string recordAutoExtension;
        string recordAutoFolder;

        useSystemMonospaceFont = profile.getBoolean ("preferences", "use_system_monospace_font", Preferences.DEFAULT_USE_SYSTEM_MONOSPACE_FONT);
        font = profile.getString ("preferences", "font");
        fontColor = profile.getString ("preferences", "font_color");
        backgroundColor = profile.getString ("preferences", "background_color");
        highlightColor = profile.getString ("preferences", "highlight_color");
        recordLaunch = profile.getBoolean ("preferences", "record_launch", true);
        enableTimeout = profile.getBoolean ("preferences", "enable_timeout", false);
        timeout = profile.getInteger ("preferences", "timeout", 30);
        recordAutoName = profile.getBoolean("preferences", "record_auto_name", false);
        recordAutoDirection = profile.getInteger("preferences", "record_auto_direction", 0);
        recordAutoExtension = profile.getString("preferences", "record_auto_extension");
        recordAutoFolder = profile.getString("preferences", "record_auto_folder");
        return new Preferences (useSystemMonospaceFont, font, fontColor,
                                backgroundColor, highlightColor, recordLaunch,
                                enableTimeout, timeout, recordAutoName,
                                recordAutoDirection, recordAutoExtension,
                                recordAutoFolder);
    }
}
