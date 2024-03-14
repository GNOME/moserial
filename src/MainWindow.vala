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
        "Michael J. Chudobiak <mjc@avtechpulse.com>",
        "mdarlodavampire",
        "Michael Wolf <michael.wolf@mictronics.de>",
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
    private Gtk.MenuItem cutMenuItem;
    private Gtk.MenuItem copyMenuItem;
    private Adjustment va1;
    private Adjustment va2;
    private Adjustment va3;
    private Adjustment va4;
    private Gtk.AccelGroup ag;
    private Button incomingClearButton;
    private Button outgoingClearButton;
    private ToggleButton dtrButton;
    private ToggleButton rtsButton;
    private Grid incoming_signals;
    private Grid outgoing_signals;
    private CheckMenuItem extraControlsCheck;

    private const string recentGroup = "moserial-configs";
    private Gtk.RecentData recentData;

    private Label serialStatusSignals[4];

    public MainWindow (string ? profileFilename)
    {
        GLib.Object (startupProfileFilename: profileFilename);
    }
    construct {
        var builder = new Gtk.Builder.from_resource (Config.UIROOT + "mainwindow.ui");

        // setup window
        gtkWindow = (Gtk.Window)builder.get_object ("window");
        ag = (Gtk.AccelGroup)builder.get_object ("accelgroup1");
        gtkWindow.add_accel_group (ag);
        // gtkWindow.add_accelerator(gtkWindow, "<Control>b", signal="backspace")
        gtkWindow.destroy.connect (quitSave);
        gtkWindow.delete_event.connect (deleteSaveSize);
        gtkWindow.key_press_event.connect (keyPress);
        gtkWindow.realize.connect (checkExtraVisible);

        paned = (Paned) builder.get_object ("vpaned");

        // load defaults
        profile = new Profile ();
        profile.load (null, gtkWindow);

        // setup extra controls optional view
        incoming_signals = (Grid) builder.get_object ("incoming_signals");
        outgoing_signals = (Grid) builder.get_object ("outgoing_signals");

        extraControlsCheck = (CheckMenuItem) builder.get_object ("menubar_extracontrols");
        extraControlsCheck.toggled.connect (this.toggleExtraControls);

        // setup menu items
        Gtk.MenuItem quit = (Gtk.MenuItem)builder.get_object ("menubar_quit");
        quit.activate.connect (quitSizeSave);
        Gtk.MenuItem saveAs = (Gtk.MenuItem)builder.get_object ("menubar_save_settings_as");
        saveAs.activate.connect (saveProfileAs);
        Gtk.MenuItem save = (Gtk.MenuItem)builder.get_object ("menubar_save_settings");
        save.activate.connect (saveProfile);
        Gtk.MenuItem open = (Gtk.MenuItem)builder.get_object ("menubar_open_settings");
        open.activate.connect (loadProfile);
        copyMenuItem = (Gtk.MenuItem)builder.get_object ("menubar_copy");
        copyMenuItem.activate.connect (this.copy);
        Gtk.MenuItem editMenuItem = (Gtk.MenuItem)builder.get_object ("menubar_edit");
        editMenuItem.activate.connect (this.editMenu);
        cutMenuItem = (Gtk.MenuItem)builder.get_object ("menubar_cut");
        copyMenuItem.set_sensitive (false);
        cutMenuItem.set_sensitive (false);
        cutMenuItem.activate.connect (this.cut);
        Gtk.MenuItem pasteMenuItem = (Gtk.MenuItem)builder.get_object ("menubar_paste");
        pasteMenuItem.activate.connect (this.paste);
        Gtk.MenuItem clearMenuItem = (Gtk.MenuItem)builder.get_object ("menubar_clear");
        clearMenuItem.activate.connect (this.clear);

        // setup the Port Settings Dialog
        settingsDialog = new SettingsDialog (this.gtkWindow);
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

        // setup the byte count bar
        bytecountbar = (Statusbar) builder.get_object ("bytecountbar");
        bytecountbarContext = statusbar.get_context_id ("moserial byte counts");
        bytecountbar.push (bytecountbarContext, _("TX: 0, RX: 0"));

        // setup the about dialog
        Gtk.MenuItem about = (Gtk.MenuItem)builder.get_object ("menubar_about");
        about.activate.connect (showAboutDialog);

        // setup send
        sendProgressDialog = new SendProgressDialog (this.gtkWindow);
        sendChooserDialog = new SendChooserDialog (this.gtkWindow);
        send = (ToolButton) builder.get_object ("toolbar_send");
        send.clicked.connect (doSendChooser);
        send.set_tooltip_text (_("Send a file"));
        sendChooserDialog.startTransfer.connect (this.doSend);
        sz = new Szwrapper (Szwrapper.Protocol.NULL, null, null);

        // setup receive
        receiveProgressDialog = new ReceiveProgressDialog (this.gtkWindow);
        receiveChooserDialog = new ReceiveChooserDialog (this.gtkWindow);
        receive = (ToolButton) builder.get_object ("toolbar_receive");
        receive.clicked.connect (doReceiveChooser);
        receive.set_tooltip_text (_("Receive a file"));
        receiveChooserDialog.startTransfer.connect (this.doReceive);
        xmodemFilenameDialog = new XmodemFilenameDialog (this.gtkWindow);
        rz = new Rzwrapper (Rzwrapper.Protocol.NULL, null, null, null);

        // setup recording
        recordDialog = new RecordDialog (this.gtkWindow);
        recordButton = (ToggleToolButton) builder.get_object ("toolbar_logging");
        recordButton.toggled.connect (this.record);
        recordButton.set_tooltip_text (_("Record sent and/or received data"));
        recordDialog.stopRecording.connect (this.stopRecording);
        recordDialog.startRecording.connect (this.startRecording);
        recordLabel = (Label) builder.get_object ("record_label");
        stopRecordingLabel = (Label) builder.get_object ("stop_recording_label");

        // setup preferences
        preferencesDialog = new PreferencesDialog (this.gtkWindow);
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
        Gtk.MenuItem contents = (Gtk.MenuItem)builder.get_object ("menubar_contents");
        contents.activate.connect (showHelpAction);

        // setup incoming notebook
        incoming_notebook = (Notebook) builder.get_object ("incoming_notebook");
        incoming_notebook.switch_page.connect (onIncomingNotebookSwitchPage);

        // setup outgoing notebook
        outgoing_notebook = (Notebook) builder.get_object ("outgoing_notebook");
        outgoing_notebook.switch_page.connect (onOutgoingNotebookSwitchPage);

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
        inputModeCombo.changed.connect (inputModeChanged);

        lineEndModeCombo = (ComboBox) builder.get_object ("termination_mode");
        MoUtils.populateComboBox (lineEndModeCombo, SerialConnection.LineEndStrings);
        lineEndModeCombo.changed.connect (lineEndChanged);

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

        // setup status bar for serial
        Label label = (Label) builder.get_object ("labelStatusRI");
        label.set_sensitive (false);
        serialStatusSignals[0] = label;
        label = (Label) builder.get_object ("labelStatusDSR");
        label.set_sensitive (false);
        serialStatusSignals[1] = label;
        label = (Label) builder.get_object ("labelStatusCD");
        label.set_sensitive (false);
        serialStatusSignals[2] = label;
        label = (Label) builder.get_object ("labelStatusCTS");
        label.set_sensitive (false);
        serialStatusSignals[3] = label;
        GLib.Timeout.add (200, (GLib.SourceFunc)showSerialStatus, 0);

        // setup DTR toggle button
        dtrButton = (ToggleButton) builder.get_object ("buttonDTR");
        dtrButton.toggled.connect (this.toggleDTR);
        dtrButton.set_tooltip_text (_("Shows and toggles the DTR output (Data Terminal Ready)"));

        // setup RTS toggle button
        rtsButton = (ToggleButton) builder.get_object ("buttonRTS");
        rtsButton.toggled.connect (this.toggleRTS);
        rtsButton.set_tooltip_text (_("Shows and toggles the RTS output (Request To Send)"));

        // setup incoming clear button
        incomingClearButton = (Button) builder.get_object ("buttonIncomingClear");
        incomingClearButton.clicked.connect (clearIncoming);
        incomingClearButton.set_tooltip_text (_("Clear incoming text box"));

        // setup outgoing clear button
        outgoingClearButton = (Button) builder.get_object ("buttonOutgoingClear");
        outgoingClearButton.clicked.connect (clearOutgoing);
        outgoingClearButton.set_tooltip_text (_("Clear outgoing text box"));

        // load and apply preferences
        applyProfile (startupProfileFilename);
    }

    private void onIncomingNotebookSwitchPage (Widget page, uint page_num)
    {
        profile.setInteger ("main_ui_controls", "incoming_tab", (int) page_num);
    }

    private void onOutgoingNotebookSwitchPage (Widget page, uint page_num)
    {
        profile.setInteger ("main_ui_controls", "outgoing_tab", (int) page_num);
    }

    private void checkExtraVisible (Widget widget)
    {
        bool new_state = profile.getBoolean ("main_ui_controls", "show_extra_controls", true);
        incoming_signals.visible = new_state;
        outgoing_signals.visible = new_state;
    }

    private void toggleExtraControls (CheckMenuItem check)
    {
        profile.setBoolean ("main_ui_controls", "show_extra_controls", check.get_active ());
        checkExtraVisible (gtkWindow);
    }

    private void toggleRTS (ToggleButton button)
    {
        // Toogle only when connected
        if (!serialConnection.isConnected ()) {
            return;
        }

        if (button.get_active ()) {
            serialConnection.controlRTS (true);
        } else {
            serialConnection.controlRTS (false);
        }
    }

    private void toggleDTR (ToggleButton button)
    {
        // Toogle only when connected
        if (!serialConnection.isConnected ()) {
            return;
        }

        if (button.get_active ()) {
            serialConnection.controlDTR (true);
        } else {
            serialConnection.controlDTR (false);
        }
    }

    private void clearIncoming ()
    {
        incomingHexTextBuffer.clear ();
        incomingAsciiTextBuffer.set_text ("", 0);
    }

    private void clearOutgoing ()
    {
        outgoingHexTextBuffer.clear ();
        outgoingAsciiTextBuffer.set_text ("", 0);
    }

    private void applyProfile (string ? filename)
    {
        profile.load (filename, gtkWindow);
        profileFilename = filename;
        ensureDisconnected ();
        currentSettings = Settings.loadFromProfile (profile);
        currentPreferences = Preferences.loadFromProfile (profile);
        currentPaths = DefaultPaths.loadFromProfile (profile);

        int width = profile.getInteger("window", "width", -1);
        int height = profile.getInteger("window", "height", -1);
        int panedPosition = profile.getInteger("window", "paned_pos", -1);
        if ((width > 0) && (height > 0)) {
            gtkWindow.resize (width, height);
        }

        // setup paned
        if (panedPosition >= -1) {
            paned.set_position (panedPosition);
        } else {
            paned.set_position (-1);
        }

        // update misc main UI settigns
        incoming_notebook.set_current_page (profile.getInteger("main_ui_controls", "incoming_tab", 0));
        outgoing_notebook.set_current_page (profile.getInteger("main_ui_controls", "outgoing_tab", 0));
        if (profile.getBoolean("main_ui_controls", "input_mode_hex", false)) {
            inputModeCombo.set_active (inputModeValues.HEX);
        } else {
            inputModeCombo.set_active (inputModeValues.ASCII);
        }
        lineEndModeCombo.set_active (profile.getInteger("main_ui_controls", "input_line_end", 0));
        updateOutgoingInputArea ();

        // update preferences dialog
        updatePreferences (null, currentPreferences);

        // update status bar
        statusbar.pop (statusbarContext);
        statusbar.push (statusbarContext, currentSettings.getStatusbarString (false));

        // update optional views
        extraControlsCheck.set_active (profile.getBoolean ("main_ui_controls", "show_extra_controls", true));
        checkExtraVisible (gtkWindow);

        // update window title
        setWindowTitle (null);

        // update recents
        if (filename != null) {
            RecentManager recentManager = RecentManager.get_default ();
            try {
                recentManager.add_full (GLib.Filename.to_uri (filename), recentData);
            } catch (GLib.ConvertError e) {
                stdout.printf ("%s\n", e.message);
            }
        }

        // auto-connect
        if (currentSettings.autoConnect) {
            ensureConnected ();
        }
    }

    private void setWindowTitle (string ? recordingFilename)
    {
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

    private void recentItemOpen (RecentChooser r)
    {
        try {
            applyProfile (GLib.Filename.from_uri (r.get_current_uri ()));
        } catch (GLib.ConvertError e) {
            stdout.printf ("%s\n", e.message);
        }
    }

    private void insertBufferEnd (TextBuffer buf, string s)
    {
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

    public void sendString (Widget w)
    {
        string s;
        s = entry.get_text ();
        if (!ensureConnected ()) {
            return;
        }

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

            string t = SerialConnection.LineEndValues[lineEndModeCombo.get_active ()];
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
                Regex rex = new Regex("[^0123456789ABCDEFabcdef]");
                uchar[] h = InputParser.parseHex (rex.replace(s, s.length, 0, ""));
                len = h.length;
                for (int x = 0; x < len; x++) {
                    serialConnection.sendByte (h[x]);
                    streamRecorder.writeOutgoing (h[x]);
                    outgoingHexTextBuffer.add (h[x]);
                    insertBufferEnd (outgoingAsciiTextBuffer, "%c".printf (h[x]));
                }
            } catch (Error e) {
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

    private void doSendChooser (ToolButton button)
    {
        if (!ensureConnected ())
            return;
        sendChooserDialog.show (currentPaths.sendFrom);
    }

    private void doSend (SendChooserDialog dialog)
    {
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

    public void sendComplete (GLib.Object o)
    {
        sz.updateStatus.disconnect (sendProgressDialog.updateStatus);
        sendProgressDialog.transferCanceled.disconnect (sz.transferCanceled);
        sendProgressDialog.hide ();
    }

    private void doReceiveChooser (ToolButton button)
    {
        if (!ensureConnected ())
            return;

        receiveChooserDialog.show (currentPaths.receiveTo);
    }

    private void doReceive (ReceiveChooserDialog dialog)
    {
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

    public void receiveComplete (GLib.Object o)
    {
        rz.updateStatus.disconnect (receiveProgressDialog.updateStatus);
        receiveProgressDialog.transferCanceled.disconnect (rz.transferCanceled);
        receiveProgressDialog.hide ();
    }

    public void record (ToggleToolButton button)
    {
        if (button.get_active ()) {
            if (!ensureConnected ()) {
                button.set_active (false);
                return;
            }
            button.set_label_widget(stopRecordingLabel);
            if (currentPreferences.recordAutoName) {
                var now = new DateTime.now_local();
                var year = now.get_year();
                var month = now.get_month();
                var day = now.get_day_of_month();
                var hour = now.get_hour();
                var minute = now.get_minute();
                var second = now.get_second();
                string folder = currentPreferences.recordAutoFolder;
                string pExtension = currentPreferences.recordAutoExtension;
                string extension = "";
                if (pExtension!="") {
                    extension = ".%s".printf(pExtension);
                }
                string filename = "%s/moserial_%04d-%02d-%02d_%02d-%02d-%02d%s".printf(
                                      folder, year, month, day, hour, minute, second, extension);
                SerialStreamRecorder.Direction direction;
                switch(currentPreferences.recordAutoDirection) {
                case 0:
                default:
                    direction=SerialStreamRecorder.Direction.INCOMING;
                    break;
                case 1:
                    direction=SerialStreamRecorder.Direction.OUTGOING;
                    break;
                case 2:
                    direction=SerialStreamRecorder.Direction.BOTH;
                    break;
                }
                startRecording(filename, direction);
            } else {
                recordDialog.show(currentPaths.recordTo);
            }
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

    public void stopRecording ()
    {
        recordButton.set_active (false); // this generates recordButton.clicked signal
    }

    public void startRecording (string filename, moserial.SerialStreamRecorder.Direction direction)
    {
        try {
            streamRecorder.open (filename, direction);
            currentPaths.recordTo = MoUtils.getParentFolder (filename);
            if (!ensureConnected ())
                stopRecording ();
            setWindowTitle (filename);
        } catch (GLib.Error e) {
            var errorDialog = new MessageDialog (gtkWindow, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.CLOSE, "%s: %s\n%s", _("Error: Could not open file"), filename, e.message);
            errorDialog.run ();
            errorDialog.destroy ();
            stopRecording ();
        }
    }

    public bool recordTimeout ()
    {
        recordButton.set_active (false);
        return false;
    }

    public void showWindow ()
    {
        gtkWindow.show_all ();
    }

    private void updateSettings (SettingsDialog d, Settings newSettings)
    {
        currentSettings = newSettings;
        statusbar.pop (statusbarContext);
        statusbar.push (statusbarContext, currentSettings.getStatusbarString (false));
        updateOutgoingInputArea ();
    }

    private void updateOutgoingInputArea ()
    {
        if (currentSettings.accessMode == READONLY) {
            entry.set_sensitive (false);
            sendButton.set_sensitive (false);
        } else {
            entry.set_sensitive (true);
            sendButton.set_sensitive (true);
        }
    }

    private void updatePreferences (PreferencesDialog ? d, Preferences newPreferences)
    {
        currentPreferences = newPreferences;
        string font;
        if (currentPreferences.useSystemMonospaceFont)
            font = Preferences.getSystemDefaultMonospaceFont ();
        else
            font = currentPreferences.font;

        Pango.FontDescription fd = Pango.FontDescription.from_string (font);

        string unit = "px";
        if (Gtk.check_version (3, 22, 0) == null) {
            unit = "pt";
        }

        var family = fd.get_family ().split (",")[0];
        int size = (int) Math.round (fd.get_size () / Pango.SCALE);
        int weight = (int) fd.get_weight ();

        var style = """
                    .TextviewColor text {
                        color:
                        %s;
                        background-color:
                        %s;
                    }
        .TextInputColor {
color:
            %s;
background-color:
            %s;
        }
        .TextFont {
font-family:
            %s;
font-size:
            %d%s;
font-weight:
            %d;
        }
        """.printf (
        currentPreferences.fontColor,
        currentPreferences.backgroundColor,
        currentPreferences.fontColor,
        currentPreferences.backgroundColor,
        family,
        size,
        unit,
        weight
        );

        var css_provider = new Gtk.CssProvider ();

        try
        {
            css_provider.load_from_data (style, -1);
        } catch (GLib.Error e)
        {
            warning ("Failed to parse CSS style : %s", e.message);
        }

        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
                                   css_provider,
                                   Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        echoTag.foreground = currentPreferences.highlightColor;
        incomingHexTextBuffer.applyPreferences (currentPreferences);
        outgoingHexTextBuffer.applyPreferences (currentPreferences);
    }

    private void showSettingsDialog (GLib.Object o)
    {
        settingsDialog.show (currentSettings);
    }

    private void showPreferencesDialog (GLib.Object o)
    {
        preferencesDialog.show (currentPreferences, recordButton.get_active ());
    }

    public bool ensureConnected ()
    {
        if (!connectButton.get_active ())
            connectButton.set_active (true);
        return connectButton.get_active ();
    }

    public void ensureDisconnected ()
    {
        if (connectButton.get_active ())
            connectButton.set_active (false);
    }

    private bool startConnection ()
    {
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
        // Feedback signal status back to button.
        bool[] state = serialConnection.getStatus ();
        rtsButton.set_active (state[4]);
        dtrButton.set_active (state[5]);

        settingsButton.set_sensitive (false);
        statusbar.pop (statusbarContext);
        statusbar.push (statusbarContext, currentSettings.getStatusbarString (true));
        serialConnection.newData.connect (this.updateIncoming);
        serialConnection.onError.connect(this.connectionError);
        connectButton.set_label_widget (disconnectLabel);
        connectButton.set_icon_name ("network-transmit-receive");
        return true;
    }

    private void connectButtonClick (ToggleToolButton button)
    {
        if (button.get_active ()) {
            startConnection ();
        } else {
            settingsButton.set_sensitive (true);
            serialConnection.doDisconnect ();
            serialConnection.newData.disconnect (this.updateIncoming);
            serialConnection.onError.disconnect(this.connectionError);
            bytecountbar.pop (bytecountbarContext);
            bytecountbar.push (bytecountbarContext, serialConnection.getBytecountbarString ());
            statusbar.pop (statusbarContext);
            statusbar.push (statusbarContext, currentSettings.getStatusbarString (false));
            button.set_label_widget (connectLabel);
            button.set_icon_name ("network-offline");

            serialStatusSignals[0].set_sensitive (false);
            serialStatusSignals[1].set_sensitive (false);
            serialStatusSignals[2].set_sensitive (false);
            serialStatusSignals[3].set_sensitive (false);
            if (recordButton.get_active ())
                recordButton.set_active (false);
        }
    }

    private bool showSerialStatus ()
    {
        if (!serialConnection.isConnected ()) {
            return true;
        }

        bool[] state = serialConnection.getStatus ();
        serialStatusSignals[0].set_sensitive (state[0]); // RI
        serialStatusSignals[1].set_sensitive (state[1]); // DSR
        serialStatusSignals[2].set_sensitive (state[2]); // CD
        serialStatusSignals[3].set_sensitive (state[3]); // CTS
        return true;
    }

    private void connectionError()
    {
        settingsButton.set_sensitive(true);
        serialConnection.doDisconnect();
        serialConnection.newData.disconnect(this.updateIncoming);
        serialConnection.onError.disconnect(this.connectionError);
        bytecountbar.pop(bytecountbarContext);
        bytecountbar.push(bytecountbarContext, serialConnection.getBytecountbarString());
        statusbar.pop(statusbarContext);
        statusbar.push(statusbarContext, currentSettings.getStatusbarString(false));
        connectButton.set_label_widget(connectLabel);
        connectButton.set_icon_name ("network-offline");
        connectButton.set_active(false);

        if (recordButton.get_active())
            recordButton.set_active(false);
    }

    private void updateIncoming (SerialConnection sc, uchar[] data, int size)
    {
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
                    profile.setInteger ("main_ui_controls", "incoming_tab", 1);
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

    private void inputModeChanged (ComboBox inputModeCombo)
    {
        if (inputModeCombo.get_active () == inputModeValues.HEX) {
            outgoing_notebook.set_current_page (1);
            profile.setInteger ("main_ui_controls", "outgoing_tab", 1);
            profile.setBoolean ("main_ui_controls", "input_mode_hex", true);
        } else {
            outgoing_notebook.set_current_page (0);
            profile.setInteger ("main_ui_controls", "outgoing_tab", 0);
            profile.setBoolean ("main_ui_controls", "input_mode_hex", false);
        }
    }

    private void lineEndChanged (ComboBox lineEndCombo)
    {
        profile.setInteger ("main_ui_controls", "input_line_end", lineEndCombo.get_active ());
    }

    private void showHelpButton (ToolButton button)
    {
        showHelp ();
    }

    private void showHelpAction ()
    {
        showHelp ();
    }

    private void showHelp ()
    {
        try {
            show_uri_on_window (null, "help:moserial", Gdk.CURRENT_TIME);
        } catch (GLib.Error e) {
            warning (_("Unable to display help file: %s"), e.message);
        }
    }

    private void showAboutDialog ()
    {

        string license_trans = _(license[0]) + "\n" + _(license[1]) + "\n" + _(license[2]);

        show_about_dialog (gtkWindow,
                           "version", Config.VERSION,
                           "copyright", "Copyright © 2009-2021\nMichael J. Chudobiak\n<mjc@avtechpulse.com>",
                           "comments", _("A serial terminal for the GNOME desktop, optimized for logging and file capture."),
                           "authors", authors,
                           "translator-credits", _(translators),
                           "logo-icon-name", "moserial",
                           "wrap-license", true,
                           "license", license_trans,
                           "website", "https://wiki.gnome.org/Apps/Moserial",
                           "website_label", "https://wiki.gnome.org/Apps/Moserial",
                           null);
    }

    private void quitSizeSave ()
    {
        windowSizeSave ();
        quitSave ();
    }

    private bool deleteSaveSize ()
    {
        windowSizeSave ();
        quitSave ();
        Gtk.main_quit ();
        return true;
    }

    private bool keyPress (Widget widget, EventKey key)
    {
        // GLib.print("key:%x\r\n",key.keyval);
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

    private void windowSizeSave ()
    {
        int width = 0;
        int height = 0;

        int pos = paned.get_position ();
        gtkWindow.get_size (out width, out height);
        profile.setInteger ("window", "width", width);
        profile.setInteger ("window", "height", height);
        profile.setInteger ("window", "paned_pos", pos);
    }

    private void quitSave ()
    {
        currentPreferences.saveToProfile (profile);
        currentSettings.saveToProfile (profile);
        currentPaths.saveToProfile (profile);
        if (profileFilename != null) {
            if (profile.profileChanged) {
                var dialog = new MessageDialog (gtkWindow, DialogFlags.DESTROY_WITH_PARENT, MessageType.QUESTION, ButtonsType.YES_NO, "%s", _("Save modified settings to the loaded profile?"));
                int response = dialog.run ();
                if (response == Gtk.ResponseType.YES)
                    saveProfile ();
                dialog.destroy ();
            } else {
                /* Save the profile even if settings or preferences have not
                   changed, to save the default file locations */
                // update the non-default profile, if it has change
                saveProfile ();
            }
        }
        // update the default profile, always
        profile.save (null, gtkWindow);
        Gtk.main_quit ();
    }

    private void saveProfile ()
    {
        currentPreferences.saveToProfile (profile);
        currentSettings.saveToProfile (profile);
        currentPaths.saveToProfile (profile);
        if (profileFilename == null)
            saveProfileAs ();
        if (profileFilename == null)
            return;
        profile.save (profileFilename, gtkWindow);
        RecentManager recentManager = RecentManager.get_default ();
        try {
            recentManager.add_full (GLib.Filename.to_uri (profileFilename), recentData);
        } catch (GLib.ConvertError e) {
            stdout.printf ("%s\n", e.message);
        }
    }

    private void saveProfileAs ()
    {
        var dialog = new FileChooserDialog (null, gtkWindow, Gtk.FileChooserAction.SAVE);
        dialog.add_buttons ("gtk-cancel", Gtk.ResponseType.CANCEL, "gtk-save", Gtk.ResponseType.ACCEPT, null);
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

    private void loadProfile ()
    {
        var dialog = new FileChooserDialog (null, gtkWindow, Gtk.FileChooserAction.OPEN);
        dialog.add_buttons ("gtk-cancel", Gtk.ResponseType.CANCEL, "gtk-open", Gtk.ResponseType.ACCEPT, null);
        dialog.set_local_only (false);
        int response = dialog.run ();
        if (response == Gtk.ResponseType.ACCEPT) {
            applyProfile (dialog.get_filename ());
        }
        dialog.destroy ();
    }

    private void copy ()
    {
        if (gtkWindow.get_focus () == (Gtk.Widget)outgoingAsciiTextView || gtkWindow.get_focus () == (Gtk.Widget)incomingAsciiTextView || gtkWindow.get_focus () == (Gtk.Widget)outgoingHexTextView || gtkWindow.get_focus () == (Gtk.Widget)incomingHexTextView) {
            TextView tv = (TextView) gtkWindow.get_focus ();
            tv.buffer.copy_clipboard (Gtk.Clipboard.get (Gdk.SELECTION_CLIPBOARD));
        } else if (gtkWindow.get_focus () == (Gtk.Widget)entry) {
            entry.copy_clipboard ();
        }
    }

    private void cut ()
    {
        if (gtkWindow.get_focus () == (Gtk.Widget)entry) {
            entry.cut_clipboard ();
        }
    }

    private void editMenu ()
    {
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

    private void paste ()
    {
        entry.paste_clipboard ();
        if (!entry.has_focus) {
            entry.grab_focus ();
            entry.set_position (-1);
        }
    }

    private void clear ()
    {
        this.clearOutgoing ();
        this.clearIncoming ();
        entry.set_text ("");
    }
}

