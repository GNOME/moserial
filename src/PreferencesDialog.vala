using Gtk;
public class moserial.PreferencesDialog : GLib.Object
{
        public Builder builder {get; construct;}
        private Dialog dialog;
        private Button cancelButton;
        private Button okButton;
        private CheckButton systemFont;
        private FontButton fontButton;
        private ColorButton fontColorButton;
        private ColorButton backgroundColorButton;
        private ColorButton highlightColorButton;
        private CheckButton recordLaunch;
        private CheckButton enableTimeout;
        private SpinButton timeout;
        public signal void updatePreferences(Preferences preferences);
        public PreferencesDialog(Builder builder) {
                this.builder=builder;
        }
        construct {
                dialog = (Dialog)builder.get_object("preferences_dialog");
                okButton = (Button)builder.get_object("preferences_ok");
                cancelButton = (Button)builder.get_object("preferences_cancel");
                systemFont = (CheckButton)builder.get_object("preferences_use_system_font");
                fontButton = (FontButton)builder.get_object("preferences_font_button");
                fontColorButton = (ColorButton)builder.get_object("preferences_font_color_button");
                backgroundColorButton = (ColorButton)builder.get_object("preferences_background_color_button");
                highlightColorButton = (ColorButton)builder.get_object("preferences_highlight_color_button");
                recordLaunch = (CheckButton)builder.get_object("preferences_record_launch");
                enableTimeout = (CheckButton)builder.get_object("preferences_record_enable_timeout");
                timeout = (SpinButton)builder.get_object("preferences_record_timeout");
                systemFont.toggled += this.systemFontToggled;
                enableTimeout.toggled += this.enableTimeoutToggled;
                okButton.clicked += ok;
                cancelButton.clicked += cancel;
                dialog.delete_event += hide;
        }
        public void ok(Button button) {
        	hide();
        	bool pSystemFont;
        	string pFont;
        	string pFontColor;
        	string pBackgroundColor;
        	string pHighlightColor;
        	bool pRecordLaunch;
        	bool pEnableTimeout;
        	int pTimeout;
		if(systemFont.get_active())
			pSystemFont=true;
		else
			pSystemFont=false;
		pFont=fontButton.get_font_name();
		Gdk.Color c;
		fontColorButton.get_color(out c);
		pFontColor=c.to_string();
		backgroundColorButton.get_color(out c);
		pBackgroundColor=c.to_string();
		highlightColorButton.get_color(out c);
		pHighlightColor=c.to_string();
		if(recordLaunch.get_active())
			pRecordLaunch=true;
		else
			pRecordLaunch=false;
		if(enableTimeout.get_active())
			pEnableTimeout=true;
		else
			pEnableTimeout=false;
		pTimeout=(int)timeout.get_value();
        	Preferences preferences=new Preferences(pSystemFont, pFont, pFontColor,pBackgroundColor,pHighlightColor, pRecordLaunch, pEnableTimeout, pTimeout);
		this.updatePreferences(preferences);
        }
        
        public void show(Preferences preferences, bool recording) {
         	if(preferences.useSystemMonospaceFont) {
        		fontButton.set_sensitive(false);
        		systemFont.set_active(true);
        	}
        	else {
        	 	fontButton.set_sensitive(true);
        		systemFont.set_active(false);
        	}
        	fontButton.set_font_name(preferences.font);
        	fontColorButton.set_color(Preferences.getGdkColor(preferences.fontColor));
        	backgroundColorButton.set_color(Preferences.getGdkColor(preferences.backgroundColor));
        	highlightColorButton.set_color(Preferences.getGdkColor(preferences.highlightColor));
        	if(preferences.recordLaunch)
        		recordLaunch.set_active(true);
        	else
	        	recordLaunch.set_active(false);
        	if(preferences.enableTimeout) {
        		enableTimeout.set_active(true);
        		timeout.set_sensitive(true);
        	}
        	else {
	        	enableTimeout.set_active(false);
        		timeout.set_sensitive(false);
	        }
       		if(recording) {
	        	enableTimeout.set_sensitive(false);
	        	timeout.set_sensitive(false);
	        }
	        else
		        enableTimeout.set_sensitive(true);
	        timeout.set_value(preferences.timeout); 		
                dialog.show_all();
        }
        public void cancel(Widget w) {
                //currentPreferences=null;
                hide();
        }
        public bool hide() {
                dialog.hide_all();
                return true;
        }
        public void systemFontToggled(CheckButton button)
        {
        	if(button.get_active())
        		fontButton.set_sensitive(false);
        	else
	        	fontButton.set_sensitive(true);
        }
        public void enableTimeoutToggled(CheckButton button)
        {
        	if(button.get_active())
        		timeout.set_sensitive(true);
        	else
	        	timeout.set_sensitive(false);
        }
}
