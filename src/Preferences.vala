using GLib;
public class Preferences : GLib.Object
{
	public static bool DEFAULT_USE_SYSTEM_MONOSPACE_FONT=true;
	public static string DEFAULT_FONT="Monospace 10";
	public static string DEFAULT_FONT_COLOR="black";
	public static string DEFAULT_BACKGROUND_COLOR="white";
	public static string DEFAULT_HIGHLIGHT_COLOR="#2020ff";
	public static bool DEFAULT_RECORD_LAUNCH=true;
	
	public bool useSystemMonospaceFont {get; construct;}
	public string? font {get; construct;}
	public string? fontColor {get; construct;}
	public string? backgroundColor {get; construct;}
	public string? highlightColor {get; construct;}
	public bool recordLaunch {get; construct;}
	public bool enableTimeout {get; construct;}
	public int timeout {get; construct;}
	
	public Preferences (bool useSystemMonospaceFont, string? font, string? fontColor,string? backgroundColor,string? highlightColor, bool recordLaunch, bool enableTimeout, int timeout) {
		this.useSystemMonospaceFont=useSystemMonospaceFont;
		this.font=font;
		this.recordLaunch=recordLaunch;
		this.fontColor=fontColor;
		this.backgroundColor=backgroundColor;
		this.highlightColor=highlightColor;
		this.enableTimeout=enableTimeout;
		this.timeout=timeout;
	}
	construct {
		if(font==null)
			font=DEFAULT_FONT;
		if(fontColor==null)
			fontColor=DEFAULT_FONT_COLOR;
		if(backgroundColor==null)
			backgroundColor=DEFAULT_BACKGROUND_COLOR;
		if(highlightColor==null)
			highlightColor=DEFAULT_HIGHLIGHT_COLOR;
	}
	public static string getSystemDefaultMonospaceFont() {
		string value = "";

                var gc = GConf.Client.get_default ();
                try {
                        value = gc.get_string("/desktop/gnome/interface/monospace_font_name");
                } catch (GLib.Error e) {
                        warning(_("Unable to retrieve gconf key: %s"), e.message);
                        value = "Monospace 10";
                }
                return value;
	}
	public static Gdk.Color getGdkColor(string color) {
		Gdk.Color c;
		Gdk.Color.parse(color, out c);
		return c;
	}
	public void toString() {
		stdout.printf("useSystemMonospaceFont: ");
		if(useSystemMonospaceFont)
			stdout.printf("true\n");
		else
			stdout.printf("false\n");
		stdout.printf("font: %s\n", font);
		stdout.printf("fontColor: %s\n", fontColor);
		stdout.printf("backgroundColor: %s\n", backgroundColor);
		stdout.printf("highlightColor: %s\n", highlightColor);
		stdout.printf("recordLaunch: ");
		if(recordLaunch)
			stdout.printf("true\n");
		else
			stdout.printf("false\n");
		
	}
	public void saveToProfile(Profile profile) {
		profile.keyFile.set_boolean("preferences", "use_system_monospace_font", useSystemMonospaceFont);
		profile.keyFile.set_string("preferences", "font", font);
		profile.keyFile.set_string("preferences", "font_color", fontColor);
		profile.keyFile.set_string("preferences", "background_color", backgroundColor);
		profile.keyFile.set_string("preferences", "highlight_color", highlightColor);
		profile.keyFile.set_boolean("preferences", "record_launch", recordLaunch);
		profile.keyFile.set_boolean("preferences", "enable_timeout", enableTimeout);
		profile.keyFile.set_integer("preferences", "timeout", timeout);
	}
	public static Preferences loadFromProfile(Profile profile) {
		bool useSystemMonospaceFont;
		string? font=null;
		string? fontColor=null;
		string? backgroundColor=null;
		string? highlightColor=null;
		bool recordLaunch;
		bool enableTimeout;
		int timeout;

		useSystemMonospaceFont = MoUtils.getKeyBoolean(profile, "preferences", "use_system_monospace_font", Preferences.DEFAULT_USE_SYSTEM_MONOSPACE_FONT);
		font = MoUtils.getKeyString(profile, "preferences", "font");	
		fontColor = MoUtils.getKeyString(profile, "preferences", "font_color");
		backgroundColor = MoUtils.getKeyString(profile, "preferences", "background_color");
		highlightColor = MoUtils.getKeyString(profile, "preferences", "highlight_color");
		recordLaunch = MoUtils.getKeyBoolean(profile, "preferences", "record_launch", true);
		enableTimeout = MoUtils.getKeyBoolean(profile, "preferences", "enable_timeout", false);
		timeout = MoUtils.getKeyInteger(profile, "preferences", "timeout", 30);
		return new Preferences (useSystemMonospaceFont, font, fontColor, backgroundColor, highlightColor, recordLaunch, enableTimeout, timeout);
	
	}
}
