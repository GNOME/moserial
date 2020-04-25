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
using Gdk;

public class moserial.MainWindow : Gtk.Window // Have to extend Gtk.Winow to get signals working. Why?
{
    const string[] authors = {
        "Michael J. Chudobiak <mjc@svn.gnome.org>",
        "marlodavampire",
        null
    };
    const string translators = N_ ("translator-credits");
    const string[] license = {
        N_ ("moserial is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n"),
        N_ ("moserial is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.\n"),
        N_ ("You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.")
    };

    private Gtk.Window gtkWindow;
    private SettingsDialog settingsDialog;
    private ToolButton settingsButton;
    private ToggleToolButton recordButton;
    private Settings currentSettings;
    private Preferences currentPreferences;
    private DefaultPaths currentPaths;
    private Statusbar statusbar;
    private Statusbar bytecountbar;
    private uint statusbarContext;
    private uint bytecountbarContext;
    private ToolButton send;
    private SendProgressDialog sendProgressDialog;
    private SendChooserDialog sendChooserDialog;
    private ToolButton receive;
    private ReceiveProgressDialog receiveProgressDialog;
    private ReceiveChooserDialog receiveChooserDialog;
    private RecordDialog recordDialog;
    private PreferencesDialog preferencesDialog;
    private SerialConnection serialConnection = new SerialConnection ();
    private TextView incomingHexTextView;
    private TextView incomingAsciiTextView;
    private TextView outgoingHexTextView;
    private TextView outgoingAsciiTextView;

    private ComboBox inputModeCombo;
    private enum inputModeValues { ASCII, HEX }
    private const string[] inputModeStrings = { GLib.N_ ("ASCII"), GLib.N_ ("HEX") };

    private ComboBox lineEndModeCombo;

    private ToggleToolButton connectButton;
    private Label disconnectLabel;
    private Label connectLabel;
    private Label recordLabel;
    private Label stopRecordingLabel;
    private Paned paned;
    private Notebook incoming_notebook;
    private Notebook outgoing_notebook;
    private HexTextBuffer incomingHexTextBuffer;
    private HexTextBuffer outgoingHexTextBuffer;
    private TextBuffer incomingAsciiTextBuffer;
    private TextTag echoTag;
    private TextBuffer outgoingAsciiTextBuffer;
    private TextMark echoStartMark;
    private XmodemFilenameDialog xmodemFilenameDialog;
    private Gtk.Entry entry;
    private Button sendButton;
    private SerialStreamRecorder streamRecorder = new SerialStreamRecorder ();
    private bool recordDataReceived = false;
    private uint recordTimeoutID = 0;
    private Rzwrapper rz;
    private Szwrapper ? sz;
    private Profile profile;
    public string ? startupProfileFilename { get; construct; }
    private string profileFilename = null;
    private bool profileChanged = false;
    private Gtk.ImageMenuItem cutMenuItem;
    private Gtk.ImageMenuItem copyMenuItem;
    private Adjustment va1;
    private Adjustment va2;
    private Adjustment va3;
    private Adjustment va4;
    private Gtk.AccelGroup ag;

    private const string recentGroup = "moserial-configs";
    private Gtk.RecentData recentData;

    public MainWindow (string ? profileFilename) {
        GLib.Object (startupProfileFilename: profileFilename);
    }
    construct {
        var builder = new Gtk.Builder.from_resource (Config.UIROOT + "mainwindow.ui");

        // setup window
        gtkWindow = (Gtk.Window)builder.get_object ("window");
        ag = (Gtk.AccelGroup)builder.get_object ("accelgroup1");
        gtkWindow.add_accel_group (ag);

        gtkWindow.destroy.connect (quitSave);
        gtkWindow.delete_event.connect (deleteSaveSize);
        gtkWindow.key_press_event.connect (keyPress);

        // load defaults
        profile = new Profile ();
        profile.load (null, gtkWindow);
        currentSettings = Settings.loadFromProfile (profile);
        int width = profile.getWindowWidth ();
        int height = profile.getWindowHeight ();
        int panedPosition = profile.getWindowPanedPosition ();
        if ((width > 0) && (height > 0))
            gtkWindow.resize (width, height);

        // setup paned
        paned = (Paned) builder.get_object ("vpaned");
        if (panedPosition >= -1)
            paned.set_position (panedPosition);
        else
            paned.set_position (-1);

        // setup menu items
        Gtk.ImageMenuItem quit = (Gtk.ImageMenuItem)builder.get_object ("menubar_quit");
        quit.activate.connect (quitSizeSave);
        Gtk.ImageMenuItem saveAs = (Gtk.ImageMenuItem)builder.get_object ("menubar_save_settings_as");
        saveAs.activate.connect (saveProfileAs);
        Gtk.ImageMenuItem save = (Gtk.ImageMenuItem)builder.get_object ("menubar_save_settings");
        save.activate.connect (saveProfile);
        Gtk.ImageMenuItem open = (Gtk.ImageMenuItem)builder.get_object ("menubar_open_settings");
        open.activate.connect (loadProfile);
        copyMenuItem = (Gtk.ImageMenuItem)builder.get_object ("menubar_copy");
        copyMenuItem.activate.connect (this.copy);
        Gtk.MenuItem editMenuItem = (Gtk.MenuItem)builder.get_object ("menubar_edit");
        editMenuItem.activate.connect (this.editMenu);
        cutMenuItem = (Gtk.ImageMenuItem)builder.get_object ("menubar_cut");
        copyMenuItem.set_sensitive (false);
        cutMenuItem.set_sensitive (false);
        cutMenuItem.activate.connect (this.cut);
        Gtk.ImageMenuItem pasteMenuItem = (Gtk.ImageMenuItem)builder.get_object ("menubar_paste");
        pasteMenuItem.activate.connect (this.paste);
        Gtk.ImageMenuItem clearMenuItem = (Gtk.ImageMenuItem)builder.get_object ("menubar_clear");
        clearMenuItem.activate.connect (this.clear);

        // setup the Port Settings Dialog
        settingsDialog = new SettingsDialog ();
        settingsDialog.updateSettings.connect (this.updateSettings);
        settingsButton = (ToolButton) builder.get_object ("toolbar_settings");
        settingsButton.clicked.connect (this.showSettingsDialog);
        settingsButton.set_tooltip_text (_("Port configuration"));

        // setup the Help button
        ToolButton helpButton = (ToolButton) builder.get_object ("toolbar_help");
        helpButton.clicked.connect (showHelpButton);
        helpButton.set_tooltip_text (_("Read the manual"));

        // setup the statusbar
        statusbar = (Statusbar) builder.get_object ("statusbar");
        statusbarContext = statusbar.get_context_id ("moserial port status");
        statusbar.push (statusbarContext, currentSettings.getStatusbarString (false));

        // setup the byte count bar
        bytecountbar = (Statusbar) builder.get_object ("bytecountbar");
        bytecountbarContext = statusbar.get_context_id ("moserial byte counts");
        bytecountbar.push (bytecountbarContext, _("TX: 0, RX: 0"));

        // setup the about dialog
        Gtk.ImageMenuItem about = (Gtk.ImageMenuItem)builder.get_object ("menubar_about");
        about.activate.connect (showAboutDialog);

        // setup send
        sendProgressDialog = new SendProgressDialog ();
        sendChooserDialog = new SendChooserDialog ();
        send = (ToolButton) builder.get_object ("toolbar_send");
        send.clicked.connect (doSendChooser);
        send.set_tooltip_text (_("Send a file"));
        sendChooserDialog.startTransfer.connect (this.doSend);
        sz = new Szwrapper (Szwrapper.Protocol.NULL, null, null);

        // setup receive
        receiveProgressDialog = new ReceiveProgressDialog ();
        receiveChooserDialog = new ReceiveChooserDialog ();
        receive = (ToolButton) builder.get_object ("toolbar_receive");
        receive.clicked.connect (doReceiveChooser);
        receive.set_tooltip_text (_("Receive a file"));
        receiveChooserDialog.startTransfer.connect (this.doReceive);
        xmodemFilenameDialog = new XmodemFilenameDialog ();
        rz = new Rzwrapper (Rzwrapper.Protocol.NULL, null, null, null);


        // setup recording
        recordDialog = new RecordDialog ();
        recordButton = (ToggleToolButton) builder.get_object ("toolbar_logging");
        recordButton.toggled.connect (this.record);
        recordButton.set_tooltip_text (_("Record sent and/or received data"));
        recordDialog.stopRecording.connect (this.stopRecording);
        recordDialog.startRecording.connect (this.startRecording);
        recordLabel = (Label) builder.get_object ("record_label");
        stopRecordingLabel = (Label) builder.get_object ("stop_recording_label");

        // setup preferences
        preferencesDialog = new PreferencesDialog ();
        preferencesDialog.updatePreferences.connect (this.updatePreferences);
        ToolButton preferences = (ToolButton) builder.get_object ("toolbar_preferences");
        preferences.clicked.connect (this.showPreferencesDialog);
        preferences.set_tooltip_text (_("Other preferences"));

        // setup connectbutton
        connectButton = (ToggleToolButton) builder.get_object ("toolbar_connect");
        connectButton.toggled.connect (this.connectButtonClick);
        connectButton.set_tooltip_text (_("Open/close port"));
        disconnectLabel = (Label) builder.get_object ("disconnect_label");
        connectLabel = (Label) builder.get_object ("connect_label");

        // setup help
        Gtk.ImageMenuItem contents = (Gtk.ImageMenuItem)builder.get_object ("menubar_contents");
        contents.activate.connect (showHelpAction);

        // setup incoming notebook
        incoming_notebook = (Notebook) builder.get_object ("incoming_notebook");

        // setup outgoing notebook
        outgoing_notebook = (Notebook) builder.get_object ("outgoing_notebook");

        // setup textBuffers;
        incomingHexTextBuffer = new HexTextBuffer ();
        incomingAsciiTextBuffer = new TextBuffer (new TextTagTable ());
        outgoingHexTextBuffer = new HexTextBuffer ();
        outgoingAsciiTextBuffer = new TextBuffer (new TextTagTable ());

        echoTag = incomingAsciiTextBuffer.create_tag ("echo", null);

        incomingHexTextView = (TextView) builder.get_object ("incoming_hex_textview");
        incomingHexTextView.set_buffer (incomingHexTextBuffer);

        incomingAsciiTextView = (TextView) builder.get_object ("incoming_ascii_textview");
        incomingAsciiTextView.set_buffer (incomingAsciiTextBuffer);

        outgoingHexTextView = (TextView) builder.get_object ("outgoing_hex_textview");
        outgoingHexTextView.set_buffer (outgoingHexTextBuffer);

        outgoingAsciiTextView = (TextView) builder.get_object ("outgoing_ascii_textview");
        outgoingAsciiTextView.set_buffer (outgoingAsciiTextBuffer);

        // setup scrolling
        ScrolledWindow incomingAsciiScrolledWindow = (ScrolledWindow) builder.get_object ("incoming_ascii_scrolledwindow");
        va1 = incomingAsciiScrolledWindow.get_vadjustment ();
        ScrolledWindow incomingHexScrolledWindow = (ScrolledWindow) builder.get_object ("incoming_hex_scrolledwindow");
        va2 = incomingHexScrolledWindow.get_vadjustment ();
        ScrolledWindow outgoingAsciiScrolledWindow = (ScrolledWindow) builder.get_object ("outgoing_ascii_scrolledwindow");
        va3 = outgoingAsciiScrolledWindow.get_vadjustment ();
        ScrolledWindow outgoingHexScrolledWindow = (ScrolledWindow) builder.get_object ("outgoing_hex_scrolledwindow");
        va4 = outgoingHexScrolledWindow.get_vadjustment ();
        AutoScroll.setup (va1, va2, va3, va4);

        // setup entry
        sendButton = (Button) builder.get_object ("send");
        sendButton.clicked.connect (sendString);
        sendButton.set_tooltip_text (_("Send the outgoing data now."));
        entry = (Gtk.Entry)builder.get_object ("entry");
        entry.activate.connect (sendString);
        entry.set_tooltip_text (_("Type outgoing data here. Press Enter or Send to send it."));

        inputModeCombo = (ComboBox) builder.get_object ("input_mode");
        MoUtils.populateComboBox (inputModeCombo, inputModeStrings);
        inputModeCombo.set_active (inputModeValues.ASCII);
        inputModeCombo.changed.connect (inputModeChanged);

        lineEndModeCombo = (ComboBox) builder.get_object ("termination_mode");
        MoUtils.populateComboBox (lineEndModeCombo, serialConnection.LineEndStrings);
        lineEndModeCombo.set_active (SerialConnection.LineEnd.CRLF);

        // setup recent chooser
        recentData.groups = { recentGroup };
        recentData.app_name = GLib.Environment.get_application_name ();
        recentData.app_exec = GLib.Environment.get_prgname () + " %u";
        recentData.mime_type = "text/plain";

        RecentManager recentManager = RecentManager.get_default ();
        RecentChooserMenu recentChooserMenu = new Gtk.RecentChooserMenu.for_manager (recentManager);
        recentChooserMenu.item_activated.connect (recentItemOpen);
        RecentFilter filter = new RecentFilter ();
        filter.add_group (recentGroup);
        recentChooserMenu.add_filter (filter);
        recentChooserMenu.set_show_numbers (true);
        recentChooserMenu.show_not_found = false;
        Gtk.MenuItem recentFileItem = (Gtk.MenuItem)builder.get_object ("menubar_open_recent");
        recentFileItem.set_submenu (recentChooserMenu);

        // load and apply preferences
        currentPreferences = Preferences.loadFromProfile (profile);
        updatePreferences (null, currentPreferences);
        profileChanged = false;
        if (!(startupProfileFilename == null))
            loadProfileOnStartup (startupProfileFilename);

        currentPaths = DefaultPaths.loadFromProfile (profile);
    }

    private void applyProfile (string filename) {
        if (profile.load (filename, gtkWindow)) {
            profileFilename = filename;
            ensureDisconnected ();
            currentSettings = Settings.loadFromProfile (profile);
            currentPreferences = Preferences.loadFromProfile (profile);
            currentPaths = DefaultPaths.loadFromProfile (profile);
            updatePreferences (null, currentPreferences);
            statusbar.pop (statusbarContext);
            statusbar.push (statusbarContext, currentSettings.getStatusbarString (false));
            setWindowTitle (null);
            profileChanged = false;
            RecentManager recentManager = RecentManager.get_default ();
            try {
                recentManager.add_full (GLib.Filename.to_uri (filename), recentData);
            } catch (GLib.ConvertError e) {
                stdout.printf ("%s\n", e.message);
            }
        }
    }

    private void setWindowTitle (string ? recordingFilename) {
        var builder = new StringBuilder ();
        builder.append ("moserial");

        if (profileFilename != null) {
            builder.append (" - ");
            builder.append (GLib.Path.get_basename (profileFilename));
        }

        if (recordingFilename != null) {
            builder.append (" - ");
            builder.append (GLib.Path.get_basename (recordingFilename));
        }

        gtkWindow.set_title (builder.str);
    }

    private void recentItemOpen (RecentChooser r) {
        try {
            applyProfile (GLib.Filename.from_uri (r.get_current_uri ()));
        } catch (GLib.ConvertError e) {
            stdout.printf ("%s\n", e.message);
        }
    }

    private void insertBufferEnd (TextBuffer buf, string s) {
        TextIter iter;
        int i;
        var builder = new StringBuilder ();

        for (i = 0; i < s.length; i++) {
            unichar c = s.get_char ();
            if (c.isprint () || c.isspace ())
                builder.append_unichar (c);
            s = s.next_char ();
        }

        buf.get_end_iter (out iter);
        buf.insert (ref iter, builder.str, (int) builder.str.length);
    }

    public void sendString (Widget w) {

        if (!ensureConnected ())
            return;

        string s;
        s = entry.get_text ();
        serialConnection.echoReference = s;

        long len;
        if (inputModeCombo.get_active () == inputModeValues.ASCII) {
            len = s.length;

            for (int x = 0; x < len; x++) {
                serialConnection.sendByte ((uchar) s.get_char ());
                streamRecorder.writeOutgoing ((uchar) s.get_char ());
                outgoingHexTextBuffer.add ((uchar) s.get_char ());
                insertBufferEnd (outgoingAsciiTextBuffer, "%c".printf ((uchar) s.get_char ()));
                s = s.next_char ();
            }

            string t = serialConnection.LineEndValues[lineEndModeCombo.get_active ()];
            len = t.length;

            for (int x = 0; x < len; x++) {
                serialConnection.sendByte ((uchar) t.get_char ());
                streamRecorder.writeOutgoing ((uchar) t.get_char ());
                outgoingHexTextBuffer.add ((uchar) t.get_char ());

                /* Just display the first byte of the terminator in the ASCII window,
                   so that CRLF doesn't cause two line advances. */
                if (x == 0)
                    insertBufferEnd (outgoingAsciiTextBuffer, "%c".printf ((uchar) t.get_char ()));

                t = t.next_char ();
            }
        } else {
            try {
                uchar[] h = InputParser.parseHex (s);
                len = h.length;
                for (int x = 0; x < len; x++) {
                    serialConnection.sendByte (h[x]);
                    streamRecorder.writeOutgoing (h[x]);
                    outgoingHexTextBuffer.add (h[x]);
                    insertBufferEnd (outgoingAsciiTextBuffer, "%c".printf (h[x]));
                }
            } catch (HexParseError e) {
                var errorDialog = new MessageDialog (gtkWindow, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.CLOSE, "%s", e.message);
                errorDialog.run ();
                errorDialog.destroy ();
            }
        }
        bytecountbar.pop (bytecountbarContext);
        bytecountbar.push (bytecountbarContext, serialConnection.getBytecountbarString ());
        entry.set_text ("");

        /* Start listening for an echo */
        serialConnection.echoCompare = "";
        TextIter echoStartIter;
        incomingAsciiTextBuffer.get_end_iter (out echoStartIter);
        echoStartMark = incomingAsciiTextBuffer.create_mark ("echo", echoStartIter, true);
    }

    private void doSendChooser (ToolButton button) {
        if (!ensureConnected ())
            return;
        sendChooserDialog.show (currentPaths.sendFrom);
    }

    private void doSend (SendChooserDialog dialog) {
        Szwrapper.Protocol protocol;
        string filename;
        filename = dialog.filename;
        currentPaths.sendFrom = MoUtils.getParentFolder (filename);
        switch (dialog.protocolCombo.get_active ()) {
            case 0:
                protocol = Szwrapper.Protocol.XMODEM;
                break;
            case 1:
                protocol = Szwrapper.Protocol.YMODEM;
                break;
            case 2:
            default:
                protocol = Szwrapper.Protocol.ZMODEM;
                break;
            case 3:
                protocol = Szwrapper.Protocol.RAW;
                break;
        }
        sz = new Szwrapper (protocol, serialConnection, filename);
        if (sz.running) {
            sendProgressDialog.show ();
            sz.updateStatus.connect (sendProgressDialog.updateStatus);
            sendProgressDialog.transferCanceled.connect (sz.transferCanceled);
            sz.transferComplete.connect (this.sendComplete);
        }
    }

    public void sendComplete (GLib.Object o) {
        sz.updateStatus.disconnect (sendProgressDialog.updateStatus);
        sendProgressDialog.transferCanceled.disconnect (sz.transferCanceled);
        sendProgressDialog.hide ();
    }

    private void doReceiveChooser (ToolButton button) {
        if (!ensureConnected ())
            return;

        receiveChooserDialog.show (currentPaths.receiveTo);
    }

    private void doReceive (ReceiveChooserDialog dialog) {
        string filename = "";
        currentPaths.receiveTo = dialog.path;
        if (dialog.protocolCombo.get_active () == 0) { // get the filename for xmodem
            xmodemFilenameDialog.show ();
            filename = xmodemFilenameDialog.filename;
        }
        Rzwrapper.Protocol protocol;
        switch (dialog.protocolCombo.get_active ()) {
            case 0:
                protocol = Rzwrapper.Protocol.XMODEM;
                break;
            case 1:
                protocol = Rzwrapper.Protocol.YMODEM;
                break;
            case 2:
            default:
                protocol = Rzwrapper.Protocol.ZMODEM;
                break;
        }
        rz = new Rzwrapper (protocol, serialConnection, dialog.path, filename);
        if (rz.running) {
            receiveProgressDialog.show ();
            rz.updateStatus.connect (receiveProgressDialog.updateStatus);
            receiveProgressDialog.transferCanceled.connect (rz.transferCanceled);
            rz.transferComplete.connect (this.receiveComplete);
        }
    }

    public void receiveComplete (GLib.Object o) {
        rz.updateStatus.disconnect (receiveProgressDialog.updateStatus);
        receiveProgressDialog.transferCanceled.disconnect (rz.transferCanceled);
        receiveProgressDialog.hide ();
    }

    public void record (ToggleToolButton button) {
        if (button.get_active ()) {
            if (!ensureConnected ()) {
                button.set_active (false);
                return;
            }
            button.set_label_widget (stopRecordingLabel);
            recordDialog.show (currentPaths.recordTo);
        } else {
            streamRecorder.close (currentPreferences.recordLaunch);
            button.set_label_widget (recordLabel);
            setWindowTitle (null);
            if (recordTimeoutID > 0) {
                GLib.Source.remove (recordTimeoutID);
                recordTimeoutID = 0;
            }
        }
    }

    public void stopRecording (moserial.RecordDialog dialog) {
        recordButton.set_active (false); // this generates recordButton.clicked signal
    }

    public void startRecording (moserial.RecordDialog dialog, string filename, moserial.SerialStreamRecorder.Direction direction) {
        try {
            streamRecorder.open (filename, direction);
            currentPaths.recordTo = MoUtils.getParentFolder (filename);
            if (!ensureConnected ())
                stopRecording (dialog);
            setWindowTitle (filename);
        } catch (GLib.Error e) {
            var errorDialog = new MessageDialog (gtkWindow, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.CLOSE, "%s: %s\n%s", _("Error: Could not open file"), filename, e.message);
            errorDialog.run ();
            errorDialog.destroy ();
            stopRecording (dialog);
        }
    }

    public bool recordTimeout () {
        recordButton.set_active (false);
        return false;
    }

    public void showWindow () {
        gtkWindow.show_all ();
    }

    private void updateSettings (SettingsDialog d, Settings newSettings) {
        currentSettings = newSettings;
        statusbar.pop (statusbarContext);
        statusbar.push (statusbarContext, currentSettings.getStatusbarString (false));
        profileChanged = true;
    }

    private void updatePreferences (PreferencesDialog ? d, Preferences newPreferences) {
        currentPreferences = newPreferences;
        string font;
        if (currentPreferences.useSystemMonospaceFont)
            font = Preferences.getSystemDefaultMonospaceFont ();
        else
            font = currentPreferences.font;
        incomingAsciiTextView.modify_font (Pango.FontDescription.from_string (font));
        incomingAsciiTextView.modify_text (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.fontColor));
        incomingAsciiTextView.modify_base (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.backgroundColor));
        echoTag.foreground = currentPreferences.highlightColor;

        incomingHexTextView.modify_font (Pango.FontDescription.from_string (font));
        incomingHexTextView.modify_text (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.fontColor));
        incomingHexTextView.modify_base (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.backgroundColor));
        incomingHexTextBuffer.applyPreferences (currentPreferences);

        outgoingAsciiTextView.modify_font (Pango.FontDescription.from_string (font));
        outgoingAsciiTextView.modify_text (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.fontColor));
        outgoingAsciiTextView.modify_base (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.backgroundColor));

        outgoingHexTextView.modify_font (Pango.FontDescription.from_string (font));
        outgoingHexTextView.modify_text (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.fontColor));
        outgoingHexTextView.modify_base (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.backgroundColor));
        outgoingHexTextBuffer.applyPreferences (currentPreferences);

        entry.modify_font (Pango.FontDescription.from_string (font));
        entry.modify_text (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.fontColor));
        entry.modify_base (Gtk.StateType.NORMAL, Preferences.getGdkColor (currentPreferences.backgroundColor));

        profileChanged = true;
    }

    private void showSettingsDialog (GLib.Object o) {
        settingsDialog.show (currentSettings);
    }

    private void showPreferencesDialog (GLib.Object o) {
        preferencesDialog.show (currentPreferences, recordButton.get_active ());
    }

    public bool ensureConnected () {
        if (!connectButton.get_active ())
            connectButton.set_active (true);
        return connectButton.get_active ();
    }

    public void ensureDisconnected () {
        if (connectButton.get_active ())
            connectButton.set_active (false);
    }

    private bool startConnection () {
        if (!(serialConnection.doConnect (currentSettings))) {
            connectButton.set_active (false);
            var dialog = new MessageDialog (gtkWindow, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.CLOSE, "%s: %s", _("Error: Could not open device"), currentSettings.device);
            dialog.run ();
            dialog.destroy ();
            return false;
        }
        incomingHexTextBuffer.clear ();
        incomingAsciiTextBuffer.set_text ("", 0);
        outgoingHexTextBuffer.clear ();
        outgoingAsciiTextBuffer.set_text ("", 0);

        settingsButton.set_sensitive (false);
        statusbar.pop (statusbarContext);
        statusbar.push (statusbarContext, currentSettings.getStatusbarString (true));
        serialConnection.newData.connect (this.updateIncoming);
        connectButton.set_label_widget (disconnectLabel);
        return true;
    }

    private void connectButtonClick (ToggleToolButton button) {
        if (button.get_active ()) {
            startConnection ();
        } else {
            settingsButton.set_sensitive (true);
            serialConnection.doDisconnect ();
            serialConnection.newData.disconnect (this.updateIncoming);
            bytecountbar.pop (bytecountbarContext);
            bytecountbar.push (bytecountbarContext, serialConnection.getBytecountbarString ());
            // serialConnection = new SerialConnection();
            statusbar.pop (statusbarContext);
            statusbar.push (statusbarContext, currentSettings.getStatusbarString (false));
            button.set_label_widget (connectLabel);

            if (recordButton.get_active ())
                recordButton.set_active (false);
        }
    }

    private void updateIncoming (SerialConnection sc, uchar[] data, int size) {
        if (rz.running) {
            for (int x = 0; x < size; x++) {
                rz.writeChar (data[x]);
            }
            rz.flush ();
        } else if (sz.running) {
            for (int x = 0; x < size; x++) {
                sz.writeChar (data[x]);
            }
        } else {
            for (int x = 0; x < size; x++) {

                incomingHexTextBuffer.add (data[x]);

                unichar c = "%c".printf (data[x]).get_char ();
                string s = "%c".printf (data[x]);

                /* Keep a record of any possible echo */
                if (sc.echoCompare.length < sc.echoReference.length)
                    sc.echoCompare += s;

                if (s.validate () && (c.isprint () || c.isspace ())) {
                    /* Ignore LF if last char was CR (CRLF terminator) */
                    if (!(sc.lastRxCharWasCR && (c == '\n'))) {
                        insertBufferEnd (incomingAsciiTextBuffer, s);
                    }
                } else
                    ++sc.nonprintable;

                sc.lastRxCharWasCR = (c == '\r');

                /* Highlight any text that is an exact echo of the last transmission */
                if (sc.echoCompare.length > 0 && (sc.echoCompare.length == sc.echoReference.length)) {
                    if (sc.echoCompare == sc.echoReference) {
                        TextIter echoStartIter;
                        TextIter echoStopIter;
                        incomingAsciiTextBuffer.get_iter_at_mark (out echoStartIter, echoStartMark);
                        incomingAsciiTextBuffer.get_end_iter (out echoStopIter);
                        incomingAsciiTextBuffer.apply_tag_by_name ("echo", echoStartIter, echoStopIter);
                    }
                    sc.echoCompare = "";
                    sc.echoReference = "";
                }

                /* Auto-select hex view for binary data */
                if ((sc.rx > 32) && (sc.nonprintable > 0) && (sc.rx / sc.nonprintable < 4) && !sc.forced_hex_view) {
                    sc.forced_hex_view = true;
                    incoming_notebook.set_current_page (1);
                }

                if (currentPreferences.enableTimeout && recordButton.get_active ()) {
                    if (recordTimeoutID > 0)
                        GLib.Source.remove (recordTimeoutID);
                    if (currentPreferences.timeout > 0)
                        recordTimeoutID = GLib.Timeout.add_seconds (currentPreferences.timeout, recordTimeout);
                }

                recordDataReceived = true;
                bytecountbar.pop (bytecountbarContext);
                bytecountbar.push (bytecountbarContext, sc.getBytecountbarString ());
            }
            streamRecorder.writeIncoming (data);
        }
    }

    private void inputModeChanged (ComboBox inputModeCombo) {
        if (inputModeCombo.get_active () == inputModeValues.HEX)
            outgoing_notebook.set_current_page (1);
        else
            outgoing_notebook.set_current_page (0);
    }

    private void showHelpButton (ToolButton button) {
        showHelp ();
    }

    private void showHelpAction () {
        showHelp ();
    }

    private void showHelp () {
        try {
            show_uri_on_window (null, "help:moserial", Gdk.CURRENT_TIME);
        } catch (GLib.Error e) {
            warning (_("Unable to display help file: %s"), e.message);
        }
    }

    private void showAboutDialog () {

        string license_trans = _(license[0]) + "\n" + _(license[1]) + "\n" + _(license[2]);

        show_about_dialog (gtkWindow,
                           "version", Config.VERSION,
                           "copyright", "Copyright © 2009-2018\nMichael J. Chudobiak\n<mjc@svn.gnome.org>",
                           "comments", _("A serial terminal for the GNOME desktop, optimized for logging and file capture."),
                           "authors", authors,
                           "translator-credits", _(translators),
                           "logo-icon-name", "moserial",
                           "wrap-license", true,
                           "license", license_trans,
                           "website", "http://live.gnome.org/moserial",
                           "website_label", "http://live.gnome.org/moserial",
                           null);
    }

    private void quitSizeSave () {
        windowSizeSave ();
        quitSave ();
    }

    private bool deleteSaveSize () {
        windowSizeSave ();
        quitSave ();
        Gtk.main_quit ();
        return true;
    }

    private bool keyPress (Widget widget, EventKey key) {
        if (key.keyval == Gdk.keyval_from_name ("Escape")) {
            AutoScroll.scroll (va1);
            AutoScroll.scroll (va2);
            AutoScroll.scroll (va3);
            AutoScroll.scroll (va4);
            entry.grab_focus ();
            entry.set_position (-1);
            return true;
        }

        return false;
    }

    private void windowSizeSave () {
        int width = 0;
        int height = 0;

        int pos = paned.get_position ();
        gtkWindow.get_size (out width, out height);
        profile.saveWindowSize (width, height);
        profile.saveWindowPanedPosition (pos);
    }

    private void quitSave () {
        currentPreferences.saveToProfile (profile);
        currentSettings.saveToProfile (profile);
        currentPaths.saveToProfile (profile);
        if (profileFilename != null) {
            if (profileChanged) {
                var dialog = new MessageDialog (gtkWindow, DialogFlags.DESTROY_WITH_PARENT, MessageType.QUESTION, ButtonsType.YES_NO, "%s", _("You have changed your setting or preferences. Do you want to save these changes to the loaded profile?"));
                int response = dialog.run ();
                if (response == Gtk.ResponseType.YES)
                    saveProfile ();
                dialog.destroy ();
            } else {
                /* Save the profile even if settings or preferences have not
                   changed, to save the default file locations */
                saveProfile ();
            }
        }
        profile.save (null, gtkWindow);
        Gtk.main_quit ();
    }

    private void saveProfile () {
        currentPreferences.saveToProfile (profile);
        currentSettings.saveToProfile (profile);
        currentPaths.saveToProfile (profile);
        if (profileFilename == null)
            saveProfileAs ();
        if (profileFilename == null)
            return;
        profile.save (profileFilename, gtkWindow);
        profileChanged = false;
        RecentManager recentManager = RecentManager.get_default ();
        try {
            recentManager.add_full (GLib.Filename.to_uri (profileFilename), recentData);
        } catch (GLib.ConvertError e) {
            stdout.printf ("%s\n", e.message);
        }
    }

    private void saveProfileAs () {
        var dialog = new FileChooserDialog (null, gtkWindow, Gtk.FileChooserAction.SAVE);
        dialog.add_buttons (Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL, Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT, null);
        dialog.set_do_overwrite_confirmation (true);
        dialog.set_local_only (false);
        int response = dialog.run ();
        if (response == Gtk.ResponseType.ACCEPT) {
            profileFilename = dialog.get_filename ();
        }
        dialog.destroy ();
        if (response == Gtk.ResponseType.ACCEPT)
            saveProfile ();
    }

    private void loadProfileOnStartup (string profileFilename) {
        applyProfile (profileFilename);
    }

    private void loadProfile () {
        var dialog = new FileChooserDialog (null, gtkWindow, Gtk.FileChooserAction.OPEN);
        dialog.add_buttons (Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL, Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT, null);
        dialog.set_local_only (false);
        int response = dialog.run ();
        if (response == Gtk.ResponseType.ACCEPT) {
            applyProfile (dialog.get_filename ());
        }
        dialog.destroy ();
    }

    private void copy () {
        if (gtkWindow.get_focus () == (Gtk.Widget)outgoingAsciiTextView || gtkWindow.get_focus () == (Gtk.Widget)incomingAsciiTextView || gtkWindow.get_focus () == (Gtk.Widget)outgoingHexTextView || gtkWindow.get_focus () == (Gtk.Widget)incomingHexTextView) {
            TextView tv = (TextView) gtkWindow.get_focus ();
            tv.buffer.copy_clipboard (Gtk.Clipboard.get (Gdk.SELECTION_CLIPBOARD));
        } else if (gtkWindow.get_focus () == (Gtk.Widget)entry) {
            entry.copy_clipboard ();
        }
    }

    private void cut () {
        if (gtkWindow.get_focus () == (Gtk.Widget)entry) {
            entry.cut_clipboard ();
        }
    }

    private void editMenu () {
        if (gtkWindow.get_focus () == (Gtk.Widget)outgoingAsciiTextView || gtkWindow.get_focus () == (Gtk.Widget)incomingAsciiTextView || gtkWindow.get_focus () == (Gtk.Widget)outgoingHexTextView || gtkWindow.get_focus () == (Gtk.Widget)incomingHexTextView) {
            cutMenuItem.set_sensitive (false);
            TextView tv = (TextView) gtkWindow.get_focus ();
            if (tv.buffer.has_selection)
                copyMenuItem.set_sensitive (true);
            else
                copyMenuItem.set_sensitive (false);
        } else if (gtkWindow.get_focus () == (Gtk.Widget)entry) {
            if (entry.get_selection_bounds (null, null)) {
                cutMenuItem.set_sensitive (true);
                copyMenuItem.set_sensitive (true);
            } else {
                cutMenuItem.set_sensitive (false);
                copyMenuItem.set_sensitive (false);
            }
        } else {
            cutMenuItem.set_sensitive (false);
            copyMenuItem.set_sensitive (false);
        }
    }

    private void paste () {
        entry.paste_clipboard ();
        if (!entry.has_focus) {
            entry.grab_focus ();
            entry.set_position (-1);
        }
    }

    private void clear () {
        incomingHexTextBuffer.clear ();
        incomingAsciiTextBuffer.set_text ("", 0);
        outgoingHexTextBuffer.clear ();
        outgoingAsciiTextBuffer.set_text ("", 0);
        entry.set_text ("");
    }
}

