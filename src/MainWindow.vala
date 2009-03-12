using Gtk;
using Gdk;

public class moserial.MainWindow : Gtk.Window //Have to extend Gtk.Winow to get signals working. Why?
{
        const string[] authors = {
                "Michael J. Chudobiak <mjc@svn.gnome.org>",
                "marlodavampire",
                null
        };
        const string translators = N_("translator-credits");
        const string[] license = {
                N_("moserial is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n"),
                N_("moserial is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.\n"),
                N_("You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.")
        };

        public Builder builder {get; construct; }
        private Gtk.Window window;
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
        private SerialConnection serialConnection = new SerialConnection();
        private TextView incomingHexTextView;
        private TextView incomingAsciiTextView;
        private TextView outgoingHexTextView;
        private TextView outgoingAsciiTextView;
        private ComboBox inputMode;
        private ComboBox terminationMode;
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
        private SerialStreamRecorder streamRecorder = new SerialStreamRecorder();
        private bool recordDataReceived=false;
        private uint recordTimeoutID=0;
        private Rzwrapper rz;
        private Szwrapper? sz;
        private Profile profile;
        public string? startupProfileFilename{get; construct; }
        private string profileFilename=null;
        private bool profileChanged=false;
        private Gtk.Action cutMenuItem;
        private Gtk.Action copyMenuItem;
        public MainWindow(Builder builder, string? profileFilename) {
                this.builder=builder;
                this.startupProfileFilename=profileFilename;
        }
        construct {
                //setup window
                window = (Gtk.Window)builder.get_object("window");
                window.destroy += quitSave;
                window.delete_event += deleteSaveSize;

		//load defaults
                profile=new Profile();
                profile.load(null, window);
		currentSettings=Settings.loadFromProfile(profile);
                int width = profile.getWindowWidth();
                int height = profile.getWindowHeight();
                int panedPosition = profile.getWindowPanedPosition();
                if ((width>0) && (height>0))
                        window.resize (width, height);

                //setup paned
                paned = (Paned)builder.get_object("vpaned");
                if (panedPosition>=-1)
                        paned.set_position(panedPosition);
		else
			paned.set_position(-1);

                //setup menu items
                Action quit = (Action)builder.get_object("menubar_quit");
                quit.activate += quitSizeSave;
                Action saveAs = (Action)builder.get_object("menubar_save_settings_as");
                saveAs.activate += saveProfileAs;
                Action save = (Action)builder.get_object("menubar_save_settings");
                save.activate += saveProfile;
                Action open = (Action)builder.get_object("menubar_open_settings");
                open.activate += loadProfile;
                copyMenuItem = (Action)builder.get_object("menubar_copy");
		copyMenuItem.activate += this.copy;
		Action editMenuItem = (Action)builder.get_object("menubar_edit");
		editMenuItem.activate += this.editMenu;
		cutMenuItem = (Action)builder.get_object("menubar_cut");
		copyMenuItem.set_sensitive(false);
		cutMenuItem.set_sensitive(false);
		cutMenuItem.activate += this.cut;
		Action pasteMenuItem = (Action)builder.get_object("menubar_paste");
		pasteMenuItem.activate += this.paste;
		Action clearMenuItem = (Action)builder.get_object("menubar_clear");
		clearMenuItem.activate += this.clear;
		
                //setup the Port Settings Dialog
                settingsDialog = new SettingsDialog(builder);
                settingsDialog.updateSettings += this.updateSettings;
                settingsButton = (ToolButton)builder.get_object("toolbar_settings");
                settingsButton.clicked += this.showSettingsDialog;

                //setup the Help button
                ToolButton helpButton = (ToolButton)builder.get_object("toolbar_help");
                helpButton.clicked += showHelpButton;

                //setup the statusbar
                statusbar = (Statusbar)builder.get_object("statusbar");
                statusbarContext = statusbar.get_context_id("moserial port status");
                statusbar.push(statusbarContext, currentSettings.getStatusbarString(false));

                //setup the byte count bar
                bytecountbar = (Statusbar)builder.get_object("bytecountbar");
                bytecountbarContext = statusbar.get_context_id("moserial byte counts");
                bytecountbar.push(bytecountbarContext, _("TX: 0, RX: 0"));

                //setup the about dialog
                Action about = (Action)builder.get_object("menubar_about");
                about.activate += showAboutDialog;

                //setup send
                sendProgressDialog = new SendProgressDialog(builder);
                sendChooserDialog = new SendChooserDialog(builder);
                send = (ToolButton)builder.get_object("toolbar_send");
                send.clicked += doSendChooser;
                sendChooserDialog.startTransfer += this.doSend;
                sz = new Szwrapper(Szwrapper.Protocol.NULL, null, null);

                //setup receive
                receiveProgressDialog = new ReceiveProgressDialog(builder);
                receiveChooserDialog = new ReceiveChooserDialog(builder);
                receive = (ToolButton)builder.get_object("toolbar_receive");
                receive.clicked += doReceiveChooser;
                receiveChooserDialog.startTransfer += this.doReceive;
                xmodemFilenameDialog = new XmodemFilenameDialog(builder);
                rz = new Rzwrapper(Rzwrapper.Protocol.NULL, null, null, null);


                //setup recording
                recordDialog = new RecordDialog(builder);
                recordButton = (ToggleToolButton)builder.get_object("toolbar_logging");
                recordButton.clicked += this.record;
                recordDialog.stopRecording += this.stopRecording;
                recordDialog.startRecording += this.startRecording;
                recordLabel = (Label)builder.get_object("record_label");
                stopRecordingLabel = (Label)builder.get_object("stop_recording_label");

                //setup preferences
                preferencesDialog = new PreferencesDialog(builder);
                preferencesDialog.updatePreferences += this.updatePreferences;
                ToolButton preferences = (ToolButton)builder.get_object("toolbar_preferences");
                preferences.clicked += this.showPreferencesDialog;

                //setup connectbutton
                connectButton = (ToggleToolButton)builder.get_object("toolbar_connect");
                connectButton.clicked += this.connect;
                disconnectLabel = (Label)builder.get_object("disconnect_label");
                connectLabel = (Label)builder.get_object("connect_label");

                //setup help
                Action contents = (Action)builder.get_object("menubar_contents");
                contents.activate += showHelpAction;

                //setup incoming notebook
                incoming_notebook = (Notebook)builder.get_object("incoming_notebook");

                //setup outgoing notebook
                outgoing_notebook = (Notebook)builder.get_object("outgoing_notebook");

                //setup textBuffers;
                incomingHexTextBuffer = new HexTextBuffer();
                incomingAsciiTextBuffer = new TextBuffer(new TextTagTable());
                outgoingHexTextBuffer = new HexTextBuffer();
                outgoingAsciiTextBuffer = new TextBuffer(new TextTagTable());

                echoTag = incomingAsciiTextBuffer.create_tag("echo", null);

                incomingHexTextView = (TextView)builder.get_object("incoming_hex_textview");
                incomingHexTextView.modify_font(Pango.FontDescription.from_string("Monospace 10"));
                incomingHexTextView.set_buffer(incomingHexTextBuffer);

                incomingAsciiTextView = (TextView)builder.get_object("incoming_ascii_textview");
                incomingAsciiTextView.modify_font(Pango.FontDescription.from_string("Monospace 10"));
                incomingAsciiTextView.set_buffer(incomingAsciiTextBuffer);

                outgoingHexTextView = (TextView)builder.get_object("outgoing_hex_textview");
                outgoingHexTextView.modify_font(Pango.FontDescription.from_string("Monospace 10"));
                outgoingHexTextView.set_buffer(outgoingHexTextBuffer);

                outgoingAsciiTextView = (TextView)builder.get_object("outgoing_ascii_textview");
                outgoingAsciiTextView.modify_font(Pango.FontDescription.from_string("Monospace 10"));
                outgoingAsciiTextView.set_buffer(outgoingAsciiTextBuffer);
                
                //setup scrolling
                ScrolledWindow incomingAsciiScrolledWindow = (ScrolledWindow)builder.get_object("incoming_ascii_scrolledwindow");
                Adjustment va1 = incomingAsciiScrolledWindow.get_vadjustment();
               	ScrolledWindow incomingHexScrolledWindow = (ScrolledWindow)builder.get_object("incoming_hex_scrolledwindow");
                Adjustment va2 = incomingHexScrolledWindow.get_vadjustment();
                ScrolledWindow outgoingAsciiScrolledWindow = (ScrolledWindow)builder.get_object("outgoing_ascii_scrolledwindow");
                Adjustment va3 = outgoingAsciiScrolledWindow.get_vadjustment();
                ScrolledWindow outgoingHexScrolledWindow = (ScrolledWindow)builder.get_object("outgoing_hex_scrolledwindow");
                Adjustment va4 = outgoingHexScrolledWindow.get_vadjustment();
		AutoScroll.setup(va1, va2, va3, va4);
		
                //setup entry
                sendButton = (Button)builder.get_object("send");
                sendButton.clicked += sendString;
                entry = (Gtk.Entry)builder.get_object("entry");
                entry.activate += sendString;
                inputMode = (ComboBox)builder.get_object("input_mode");
                inputMode.set_active(0);
		inputMode.changed += inputModeChanged;
                terminationMode = (ComboBox)builder.get_object("termination_mode");
                terminationMode.set_active(0);
                
                //load and apply preferences
                currentPreferences = Preferences.loadFromProfile(profile);
       		updatePreferences(null, currentPreferences);
       		profileChanged=false;
       		if(!(startupProfileFilename==null))
       			loadProfileOnStartup(startupProfileFilename);

		currentPaths = DefaultPaths.loadFromProfile(profile);
        }
	

        private void insertBufferEnd (TextBuffer buf, string s) {
                TextIter iter;
		int i;
		var builder = new StringBuilder();

		for (i=0;i<s.length;i++) {
			unichar c = s.get_char();
			if (c.isprint() || c.isspace())
				builder.append_unichar(c);	
			s=s.next_char();
		}

                buf.get_end_iter(out iter);
                buf.insert(iter, builder.str, (int)builder.str.length);
        }

        public void sendString(Widget w) {

                if (!ensureConnected())
                        return;

                string s;
                s=entry.get_text();
                serialConnection.echoReference=s;

                long len;
                if (inputMode.get_active()==0) {
                        len = s.length;

                        for (int x=0; x<len; x++) {
                                serialConnection.sendByte((uchar)s.get_char());
                                streamRecorder.writeOutgoing((uchar)s.get_char());
                                outgoingHexTextBuffer.add((uchar)s.get_char());
                                insertBufferEnd(outgoingAsciiTextBuffer, "%c".printf((uchar)s.get_char()));
                                s=s.next_char();
                        }

                        string t = serialConnection.getLineEnd(terminationMode.get_active());
                        len = t.length;

                        for (int x=0; x<len; x++) {
                                serialConnection.sendByte((uchar)t.get_char());
                                streamRecorder.writeOutgoing((uchar)t.get_char());
                                outgoingHexTextBuffer.add((uchar)t.get_char());

                                /* Just display the first byte of the terminator in the ASCII window,
                                   so that CRLF doesn't cause two line advances. */
                                if (x==0)
                                        insertBufferEnd(outgoingAsciiTextBuffer, "%c".printf((uchar)t.get_char()));

                                t=t.next_char();
                        }

                } else {
                	try {
		                uchar[] h = InputParser.parseHex(s);
		                len = h.length;
		                for (int x=0; x<len; x++) {
		                        serialConnection.sendByte(h[x]);
		                        streamRecorder.writeOutgoing(h[x]);
		                        outgoingHexTextBuffer.add(h[x]);
		                        insertBufferEnd(outgoingAsciiTextBuffer, "%c".printf(h[x]));
		                }
			}
			catch (HexParseError e) {
	                        var errorDialog = new MessageDialog (window, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.CLOSE, e.message);
				errorDialog.run();
				errorDialog.destroy();
			}
                }
                bytecountbar.pop(bytecountbarContext);
                bytecountbar.push(bytecountbarContext, serialConnection.getBytecountbarString());
                entry.set_text("");

                /* Start listening for an echo */
                serialConnection.echoCompare="";
                TextIter echoStartIter;
                incomingAsciiTextBuffer.get_end_iter(out echoStartIter);
                echoStartMark = incomingAsciiTextBuffer.create_mark ("echo",echoStartIter,true);
        }

        private void doSendChooser(ToolButton button) {
                if (!ensureConnected())
                        return;
                sendChooserDialog.show(currentPaths.sendFrom);
        }

        private void doSend(SendChooserDialog dialog) {
                Szwrapper.Protocol protocol;
                string filename;
                filename=dialog.filename;
		currentPaths.sendFrom=MoUtils.getParentFolder(filename);
                switch (dialog.protocolCombo.get_active()) {
                case 0:
                        protocol=Szwrapper.Protocol.XMODEM;
                        break;
                case 1:
                        protocol=Szwrapper.Protocol.YMODEM;
                        break;
                case 2:
                default:
                        protocol=Szwrapper.Protocol.ZMODEM;
                        break;
                case 3:
                	protocol=Szwrapper.Protocol.RAW;
                	break;
                }                	
                sz = new Szwrapper(protocol, serialConnection, filename);
                if(sz.running)
		{
			sendProgressDialog.show();
		        sz.updateStatus+=sendProgressDialog.updateStatus;
		        sendProgressDialog.transferCanceled+=sz.transferCanceled;
		        sz.transferComplete += this.sendComplete;
		}
        }
        public void sendComplete(GLib.Object o) {
	        sz.updateStatus-=sendProgressDialog.updateStatus;
        	sendProgressDialog.transferCanceled-=sz.transferCanceled;
                sendProgressDialog.hide(sendProgressDialog);
        }
        private void doReceiveChooser(ToolButton button) {
                if (!ensureConnected())
                        return;

                receiveChooserDialog.show(currentPaths.receiveTo);
        }

        private void doReceive(ReceiveChooserDialog dialog) {
                string filename="";
		currentPaths.receiveTo=dialog.path;
                if (dialog.protocolCombo.get_active()==0) { //get the filename for xmodem
                        xmodemFilenameDialog.show();
                        filename = xmodemFilenameDialog.filename;
                }
                Rzwrapper.Protocol protocol;
                switch (dialog.protocolCombo.get_active()) {
                case 0:
                        protocol=Rzwrapper.Protocol.XMODEM;
                        break;
                case 1:
                        protocol=Rzwrapper.Protocol.YMODEM;
                        break;
                case 2:
                default:
                        protocol=Rzwrapper.Protocol.ZMODEM;
                        break;
                }
                rz = new Rzwrapper(protocol, serialConnection, dialog.path, filename);
                if(rz.running)
                {
		        receiveProgressDialog.show();
		        rz.updateStatus+=receiveProgressDialog.updateStatus;
		        receiveProgressDialog.transferCanceled+=rz.transferCanceled;
		        rz.transferComplete += this.receiveComplete;
		}
        }

        public void receiveComplete(GLib.Object o) {
                rz.updateStatus-=receiveProgressDialog.updateStatus;
                receiveProgressDialog.transferCanceled-=rz.transferCanceled;
                receiveProgressDialog.hide(receiveProgressDialog);
        }

        public void record(ToggleToolButton button) {
                if (button.get_active()) {
                        button.set_label_widget(stopRecordingLabel);
                        recordDialog.show(currentPaths.recordTo);
                } else {
                        streamRecorder.close(currentPreferences.recordLaunch);
                        button.set_label_widget(recordLabel);
			if (recordTimeoutID > 0) {
				GLib.Source.remove (recordTimeoutID);
				recordTimeoutID = 0;
			}
                }
        }

        public void stopRecording(moserial.RecordDialog dialog) {
                recordButton.set_active(false); //this generates recordButton.clicked signal
        }

        public void startRecording(moserial.RecordDialog dialog, string filename, moserial.SerialStreamRecorder.Direction direction) {
                try {
                        streamRecorder.open(filename, direction);
			currentPaths.recordTo=MoUtils.getParentFolder(filename);
                        if (!ensureConnected())
                                stopRecording(dialog);
                } catch (GLib.Error e) {
                        warning(_("Error: Could not open %s\n"), filename);
                        var errorDialog = new MessageDialog (window, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.CLOSE, "%s: %s\n%s".printf(_("Error: Could not open file"), filename, e.message));
                        errorDialog.run();
                        errorDialog.destroy();
                        stopRecording(dialog);
                }
        }

	public bool recordTimeout() {
		recordButton.set_active(false);
		return false;
	}

        public void show() {
                window.show_all();
        }

        private void updateSettings(SettingsDialog d, Settings newSettings) {
                currentSettings = newSettings;
                statusbar.pop(statusbarContext);
                statusbar.push(statusbarContext, currentSettings.getStatusbarString(false));
                profileChanged=true;
        }
        
        private void updatePreferences(PreferencesDialog? d, Preferences newPreferences) {
        	currentPreferences = newPreferences;
        	string font;
        	if(currentPreferences.useSystemMonospaceFont)
        		font=Preferences.getSystemDefaultMonospaceFont();
        	else
        		font=currentPreferences.font;
        	incomingAsciiTextView.modify_font(Pango.FontDescription.from_string(font));
        	incomingAsciiTextView.modify_text(Gtk.StateType.NORMAL, Preferences.getGdkColor(currentPreferences.fontColor));
        	incomingAsciiTextView.modify_base(Gtk.StateType.NORMAL, Preferences.getGdkColor(currentPreferences.backgroundColor));
        	echoTag.foreground=currentPreferences.highlightColor;
		
		incomingHexTextView.modify_font(Pango.FontDescription.from_string(font));
 	      	incomingHexTextView.modify_text(Gtk.StateType.NORMAL, Preferences.getGdkColor(currentPreferences.fontColor));
        	incomingHexTextView.modify_base(Gtk.StateType.NORMAL, Preferences.getGdkColor(currentPreferences.backgroundColor));
        	incomingHexTextBuffer.applyPreferences(currentPreferences);
		
		outgoingAsciiTextView.modify_font(Pango.FontDescription.from_string(font));
        	outgoingAsciiTextView.modify_text(Gtk.StateType.NORMAL, Preferences.getGdkColor(currentPreferences.fontColor));
        	outgoingAsciiTextView.modify_base(Gtk.StateType.NORMAL, Preferences.getGdkColor(currentPreferences.backgroundColor));

        	outgoingHexTextView.modify_font(Pango.FontDescription.from_string(font));
 	      	outgoingHexTextView.modify_text(Gtk.StateType.NORMAL, Preferences.getGdkColor(currentPreferences.fontColor));
        	outgoingHexTextView.modify_base(Gtk.StateType.NORMAL, Preferences.getGdkColor(currentPreferences.backgroundColor));
        	outgoingHexTextBuffer.applyPreferences(currentPreferences);
        	profileChanged=true;
        }

        private void showSettingsDialog(GLib.Object o) {
                settingsDialog.show(currentSettings);
        }
        
        private void showPreferencesDialog(GLib.Object o) {
                preferencesDialog.show(currentPreferences, recordButton.get_active());
        }

	public bool ensureConnected () {
                if (!connectButton.get_active())
                        connectButton.set_active(true);

                /* Is this a race condition? We want to know if the
                   set_active attempt was successful. */
                return connectButton.get_active();
        }

        public void ensureDisconnected () {
                if (connectButton.get_active())
                        connectButton.set_active(false);
        }

        private bool startConnection() {
                if (!(serialConnection.connect(currentSettings))) {
                        connectButton.set_active(false);
                        warning(_("Error: Could not open %s\n"), currentSettings.device);
                        var dialog = new MessageDialog (window, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.CLOSE, "%s: %s".printf(_("Error: Could not open device"), currentSettings.device));
                        dialog.run();
                        dialog.destroy();
                        return false;
                }
                incomingHexTextBuffer.clear();
                incomingAsciiTextBuffer.set_text("",0);
                outgoingHexTextBuffer.clear();
                outgoingAsciiTextBuffer.set_text("",0);

                settingsButton.set_sensitive(false);
                statusbar.pop(statusbarContext);
                statusbar.push(statusbarContext, currentSettings.getStatusbarString(true));
                serialConnection.newData += this.updateIncoming;
                connectButton.set_label_widget(disconnectLabel);
                return true;
        }

        private void connect(ToggleToolButton button) {
                if (button.get_active()) {
                        startConnection();
                } else {
                        settingsButton.set_sensitive(true);
                        serialConnection.disconnect();
                        serialConnection.newData -= this.updateIncoming;
                        bytecountbar.pop(bytecountbarContext);
                        bytecountbar.push(bytecountbarContext, serialConnection.getBytecountbarString());
                        //serialConnection = new SerialConnection();
                        statusbar.pop(statusbarContext);
                        statusbar.push(statusbarContext, currentSettings.getStatusbarString(false));
                        button.set_label_widget(connectLabel);

                        if (recordButton.get_active())
                                recordButton.set_active(false);
                }
        }

	private void updateIncoming(SerialConnection sc, uchar[1000] data, int size) {
                if (rz.running) {
                        for (int x=0; x<size; x++) {
	                        rz.writeChar(data[x]);
                        }
                        rz.flush();
                } else if (sz.running) {
                        for (int x=0; x<size; x++) {
                                sz.writeChar(data[x]);
                        }
                } else {
                        for (int x=0; x<size; x++) {

                                incomingHexTextBuffer.add(data[x]);

                                unichar c = "%c".printf(data[x]).get_char();
                                string s = "%c".printf(data[x]);

                                /* Keep a record of any possible echo */
                                if (sc.echoCompare.length < sc.echoReference.length)
                                        sc.echoCompare += s;

                                if (s.validate() && (c.isprint() || c.isspace())) {
                                        /* Ignore LF if last char was CR (CRLF terminator) */
                                        if (! (sc.lastRxCharWasCR && (c == '\n'))) {
                                                insertBufferEnd(incomingAsciiTextBuffer, s);
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
                                                incomingAsciiTextBuffer.get_end_iter(out echoStopIter);
                                                incomingAsciiTextBuffer.apply_tag_by_name("echo",echoStartIter,echoStopIter);
                                        }
                                        sc.echoCompare="";
                                        sc.echoReference="";
                                }

                                /* Auto-select hex view for binary data */
                                if ((sc.rx > 32) && (sc.nonprintable > 0) && (sc.rx / sc.nonprintable < 4) && !sc.forced_hex_view) {
                                        sc.forced_hex_view = true;
                                        incoming_notebook.set_current_page(1);
                                }

				if(currentPreferences.enableTimeout && recordButton.get_active()) {
					if (recordTimeoutID > 0)
						GLib.Source.remove (recordTimeoutID);
					if (currentPreferences.timeout > 0)
						recordTimeoutID = GLib.Timeout.add_seconds(currentPreferences.timeout, recordTimeout);
				}

                                streamRecorder.writeIncoming(data[x]);
				recordDataReceived=true;
                                bytecountbar.pop(bytecountbarContext);
                                bytecountbar.push(bytecountbarContext, sc.getBytecountbarString());
                        }
                }
        }

	private void inputModeChanged (ComboBox inputMode) {
		if (inputMode.get_active()==1)
			outgoing_notebook.set_current_page(1); // HEX
		else
			outgoing_notebook.set_current_page(0); // ASCII
	}

	private void showHelpButton (ToolButton button) {
		showHelp ();
	}
	
	private void showHelpAction (Action a) {
		showHelp ();
	}

        private void showHelp () {
                try {
                        show_uri(null, "ghelp:moserial", Gdk.CURRENT_TIME);
                } catch (GLib.Error e) {
                        warning(_("Unable to display help file: %s"), e.message);
                }
        }

        private void showAboutDialog () {

                string license_trans = license[0] + "\n" + license[1] + "\n" + license[2];

                AboutDialog.set_url_hook (url_hook);
                show_about_dialog (window,
                                   "version", Config.VERSION,
                                   "copyright", "Copyright © 2009\nMichael J. Chudobiak\n<mjc@svn.gnome.org>",
                                   "comments", _("A serial terminal for the GNOME desktop, optimized for logging and file capture."),
                                   "authors", authors,
                                   "translator-credits", translators,
                                   "logo-icon-name", "moserial",
                                   "wrap-license", true,
                                   "license", license_trans,
                                   "website", "http://live.gnome.org/moserial",
                                   null);
        }

        private void url_hook (AboutDialog about, string link) {
                try {
                        show_uri (null, link, Gdk.CURRENT_TIME);
                } catch (GLib.Error e) {
                        warning (_("Can't display a clickable URL: %s"), e.message);
                }
        }

        private void quitSizeSave () {
                windowSizeSave();
                quitSave();
        }

        private bool deleteSaveSize(Widget widget, Event event) {
                windowSizeSave();
                quitSave();
                Gtk.main_quit();
                return true;
        }

        private void windowSizeSave () {
                int width = 0;
                int height = 0;

                int pos = paned.get_position();
                window.get_size (out width, out height);
                profile.saveWindowSize(width, height);
                profile.saveWindowPanedPosition(pos);
        }

        private void quitSave() {
                currentPreferences.saveToProfile(profile);
                currentSettings.saveToProfile(profile);
		currentPaths.saveToProfile(profile);
		if (profileFilename != null) {
			if (profileChanged) {
                		var dialog = new MessageDialog (window, DialogFlags.DESTROY_WITH_PARENT, MessageType.QUESTION, ButtonsType.YES_NO, _("You have changed your setting or preferences. Do you want to save these changes to the loaded profile?"));
	                	int response = dialog.run();
        	        	if(response == Gtk.ResponseType.YES)
	        	        	saveProfile();
                		dialog.destroy();
			} else {
				/* Save the profile even if settings or preferences have not
                                   changed, to save the default file locations */
				saveProfile();
			}
                }
                profile.save(null, window);
                Gtk.main_quit ();
        }
	private void saveProfile () {
                currentPreferences.saveToProfile(profile);
                currentSettings.saveToProfile(profile);
		currentPaths.saveToProfile(profile);
		if(profileFilename==null)
			saveProfileAs();
		if(profileFilename==null)
			return;
		profile.save(profileFilename, window);
		profileChanged=false;
	}	
	private void saveProfileAs () {
                var dialog = new FileChooserDialog (null, window, Gtk.FileChooserAction.SAVE);
                dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_SAVE, Gtk.ResponseType.ACCEPT, null);
                dialog.set_do_overwrite_confirmation(true);
                dialog.set_local_only(false);
	        int response = dialog.run();
	        if(response == Gtk.ResponseType.ACCEPT) {
		        profileFilename=dialog.get_filename();
		}
                dialog.destroy();
                if(response == Gtk.ResponseType.ACCEPT)
                	saveProfile();
	}
	private void loadProfileOnStartup(string profileFilename) {
	        if (profile.load(profileFilename, window)) {
			ensureDisconnected();
		        currentSettings = Settings.loadFromProfile(profile);
        	        currentPreferences = Preferences.loadFromProfile(profile);
			currentPaths = DefaultPaths.loadFromProfile(profile);
			updatePreferences(null, currentPreferences);
        		statusbar.pop(statusbarContext);
        		statusbar.push(statusbarContext, currentSettings.getStatusbarString(false));
			window.set_title("moserial - %s".printf(GLib.Path.get_basename(profileFilename)));
			profileChanged=false;
			this.profileFilename=profileFilename;
		}
	}
	private void loadProfile() {
                var dialog = new FileChooserDialog (null, window, Gtk.FileChooserAction.OPEN);
                dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OPEN, Gtk.ResponseType.ACCEPT, null);
                dialog.set_local_only(false);
	        int response = dialog.run();
	        if(response == Gtk.ResponseType.ACCEPT) {
		        profileFilename=dialog.get_filename();
		        if (profile.load(profileFilename, window)) {
				ensureDisconnected();
			        currentSettings = Settings.loadFromProfile(profile);
        	                currentPreferences = Preferences.loadFromProfile(profile);
				currentPaths = DefaultPaths.loadFromProfile(profile);
	       			updatePreferences(null, currentPreferences);
	                	statusbar.pop(statusbarContext);
        	        	statusbar.push(statusbarContext, currentSettings.getStatusbarString(false));
				window.set_title("moserial - %s".printf(GLib.Path.get_basename(profileFilename)));
				profileChanged=false;
			}
		}
                dialog.destroy();
	}
	
	private void copy() {
		if(window.get_focus()==(Gtk.Widget)outgoingAsciiTextView || window.get_focus()==(Gtk.Widget)incomingAsciiTextView || window.get_focus()==(Gtk.Widget)outgoingHexTextView || window.get_focus()==(Gtk.Widget)incomingHexTextView) {
			TextView tv = (TextView)window.get_focus();
			tv.buffer.copy_clipboard(Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD));
		}
		else if(window.get_focus()==(Gtk.Widget)entry) {
			entry.copy_clipboard();
		}
	}
	
	private void cut() {
		if(window.get_focus()==(Gtk.Widget)entry) {
			entry.cut_clipboard();
		}
	}
	
	private void editMenu(Action a) {
		if(window.get_focus()==(Gtk.Widget)outgoingAsciiTextView || window.get_focus()==(Gtk.Widget)incomingAsciiTextView || window.get_focus()==(Gtk.Widget)outgoingHexTextView || window.get_focus()==(Gtk.Widget)incomingHexTextView) {
			cutMenuItem.set_sensitive(false);
			TextView tv = (TextView)window.get_focus();
			if(tv.buffer.has_selection)
				copyMenuItem.set_sensitive(true);
			else
				copyMenuItem.set_sensitive(false);
		}
		else if(window.get_focus()==(Gtk.Widget)entry){
			int s=0;
			int e=0;
			if(entry.get_selection_bounds(s, e)) {
				cutMenuItem.set_sensitive(true);
				copyMenuItem.set_sensitive(true);
			}
			else {
				cutMenuItem.set_sensitive(false);
				copyMenuItem.set_sensitive(false);
			}
		}
		else {
			cutMenuItem.set_sensitive(false);
			copyMenuItem.set_sensitive(false);
		}
	}
	
	private void paste() {
		entry.paste_clipboard();
		if (!entry.has_focus) {
			entry.grab_focus();
			entry.set_position(-1);
		}
	}

	private void clear() {
                incomingHexTextBuffer.clear();
                incomingAsciiTextBuffer.set_text("",0);
                outgoingHexTextBuffer.clear();
                outgoingAsciiTextBuffer.set_text("",0);
                entry.set_text("");
	}
}

