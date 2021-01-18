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

using Gtk;
public class moserial.PreferencesDialog : GLib.Object
{
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
    private CheckButton recordAutoName;
    private ComboBox recordAutoDirection;
    private Entry recordAutoExtension;
    private Widget recordAutoFolder;

    public signal void updatePreferences (Preferences preferences);

    public PreferencesDialog (Window parent)
    {
        var builder = new Gtk.Builder.from_resource (Config.UIROOT + "preferences.ui");

        dialog = (Dialog) builder.get_object ("preferences_dialog");
        dialog.set_transient_for(parent);
        okButton = (Button) builder.get_object ("preferences_ok");
        cancelButton = (Button) builder.get_object ("preferences_cancel");
        systemFont = (CheckButton) builder.get_object ("preferences_use_system_font");
        fontButton = (FontButton) builder.get_object ("preferences_font_button");
        fontColorButton = (ColorButton) builder.get_object ("preferences_font_color_button");
        backgroundColorButton = (ColorButton) builder.get_object ("preferences_background_color_button");
        highlightColorButton = (ColorButton) builder.get_object ("preferences_highlight_color_button");

        recordLaunch = (CheckButton) builder.get_object ("preferences_record_launch");
        recordLaunch.set_tooltip_text (_("If this option is enabled, a recorded file will be opened immediately after it is saved, using the default application for the file type. The default application is defined by the desktop environment."));

        enableTimeout = (CheckButton) builder.get_object ("preferences_record_enable_timeout");
        enableTimeout.set_tooltip_text (_("If this option is enabled, recording will be automatically stopped after an adjustable period of inactivity after receiving some data. Moserial will wait indefinitely to record the first data byte before activating the inactivity timer."));

        timeout = (SpinButton) builder.get_object ("preferences_record_timeout");
        timeout.adjustment.lower = 0;
        timeout.adjustment.upper = 600;
        timeout.adjustment.step_increment = 1;
        timeout.adjustment.page_increment = 60;

        recordAutoName = (CheckButton)builder.get_object("preferences_record_auto_name");
        recordAutoName.toggled.connect(this.recordAutoToggled);
        recordAutoDirection = (ComboBox)builder.get_object("preferences_record_auto_direction");
        MoUtils.populateComboBox (recordAutoDirection, SerialStreamRecorder.DirectionStrings);
        recordAutoDirection.set_active(SerialStreamRecorder.Direction.INCOMING);
        recordAutoExtension = (Entry)builder.get_object("preferences_record_auto_extension");
        recordAutoFolder = (Widget)builder.get_object("preferences_record_auto_folder");

        systemFont.toggled.connect (this.systemFontToggled);
        enableTimeout.toggled.connect (this.enableTimeoutToggled);
        okButton.clicked.connect (ok);
        cancelButton.clicked.connect (cancel);
        dialog.delete_event.connect (hide);
    }

    public void ok (Button button)
    {
        hide ();
        bool pSystemFont;
        string pFont;
        string pFontColor;
        string pBackgroundColor;
        string pHighlightColor;
        bool pRecordLaunch;
        bool pEnableTimeout;
        int pTimeout;
        bool pRecordAutoName;
        int pRecordAutoDirection;
        string pRecordAutoExtension;
        string pRecordAutoFolder;

        if (systemFont.get_active ())
            pSystemFont = true;
        else
            pSystemFont = false;
        pFont = fontButton.get_font ();
        Gdk.RGBA c = Gdk.RGBA ();
        c = fontColorButton.get_rgba();
        pFontColor = c.to_string ();
        c = backgroundColorButton.get_rgba ();
        pBackgroundColor = c.to_string ();
        c = highlightColorButton.get_rgba ();
        pHighlightColor = c.to_string ();
        if (recordLaunch.get_active ())
            pRecordLaunch = true;
        else
            pRecordLaunch = false;
        if (enableTimeout.get_active ())
            pEnableTimeout = true;
        else
            pEnableTimeout = false;
        pTimeout = (int) timeout.get_value ();
        if(recordAutoName.get_active())
            pRecordAutoName=true;
        else
            pRecordAutoName=false;
        pRecordAutoDirection = recordAutoDirection.get_active();
        pRecordAutoExtension = recordAutoExtension.get_text();

        pRecordAutoFolder = ((FileChooser)recordAutoFolder).get_filename ();

        Preferences preferences=new Preferences(
            pSystemFont, pFont, pFontColor, pBackgroundColor,
            pHighlightColor, pRecordLaunch, pEnableTimeout,
            pTimeout, pRecordAutoName, pRecordAutoDirection,
            pRecordAutoExtension, pRecordAutoFolder);

        this.updatePreferences (preferences);
    }

    public void show (Preferences preferences, bool recording)
    {
        if (preferences.useSystemMonospaceFont) {
            fontButton.set_sensitive (false);
            systemFont.set_active (true);
        } else {
            fontButton.set_sensitive (true);
            systemFont.set_active (false);
        }
        fontButton.set_font (preferences.font);
        fontColorButton.set_rgba (Preferences.getGdkRGBA (preferences.fontColor));
        backgroundColorButton.set_rgba(Preferences.getGdkRGBA (preferences.backgroundColor));
        highlightColorButton.set_rgba (Preferences.getGdkRGBA (preferences.highlightColor));
        if (preferences.recordLaunch)
            recordLaunch.set_active (true);
        else
            recordLaunch.set_active (false);
        if (preferences.enableTimeout) {
            enableTimeout.set_active (true);
            timeout.set_sensitive (true);
        } else {
            enableTimeout.set_active (false);
            timeout.set_sensitive (false);
        }
        if (recording) {
            enableTimeout.set_sensitive (false);
            timeout.set_sensitive (false);
        } else
            enableTimeout.set_sensitive (true);
        timeout.set_value (preferences.timeout);
        recordAutoName.set_active(preferences.recordAutoName);
        recordAutoDirection.set_active(preferences.recordAutoDirection);
        recordAutoExtension.set_text(preferences.recordAutoExtension);

        ((FileChooser)recordAutoFolder).set_current_folder(preferences.recordAutoFolder);

        dialog.show_all ();
    }

    public void cancel (Button button)
    {
        // currentPreferences=null;
        hide ();
    }

    public bool hide ()
    {
        dialog.hide ();
        return true;
    }

    public void systemFontToggled (ToggleButton button)
    {
        if (button.get_active ())
            fontButton.set_sensitive (false);
        else
            fontButton.set_sensitive (true);
    }

    public void enableTimeoutToggled (ToggleButton button)
    {
        if (button.get_active ())
            timeout.set_sensitive (true);
        else
            timeout.set_sensitive (false);
    }

    public void recordAutoToggled(ToggleButton button)
    {
        if (button.get_active()) {
            recordAutoExtension.set_sensitive(true);
            recordAutoDirection.set_sensitive(true);
            recordAutoFolder.set_sensitive(true);
        } else {
            recordAutoExtension.set_sensitive(false);
            recordAutoDirection.set_sensitive(false);
            recordAutoFolder.set_sensitive(false);
        }
    }
}
