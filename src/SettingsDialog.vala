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
using GLib;

public class moserial.SettingsDialog : GLib.Object
{
    // Does anyone have more than 32 serial ports?
    const int max_devices = 32;

    private Window parent;
    private Settings currentSettings;
    private Dialog dialog;
    private Button cancelButton;
    private Button okButton;
    private Settings settings;
    private ComboBox deviceCombo;
    private ComboBox baudRateCombo;
    private ComboBox dataBitsCombo;
    private ComboBox stopBitsCombo;
    private ComboBox parityCombo;
    private CheckButton hardwareHandshake;
    private CheckButton softwareHandshake;
    private ComboBox accessModeCombo;
    private CheckButton localEcho;
    private CheckButton autoConnect;
    private Gtk.ListStore deviceModel;
    private Gtk.Entry deviceInput;
    private Gtk.Entry baudRateInput;
    public signal void updateSettings (Settings settings);

    public SettingsDialog (Window parent)
    {
        this.parent = parent;
        var builder = new Gtk.Builder.from_resource (Config.UIROOT + "settings_dialog.ui");

        dialog = (Dialog) builder.get_object ("settings_dialog");
        dialog.set_transient_for (parent);
        cancelButton = (Button) builder.get_object ("settings_cancel_button");
        okButton = (Button) builder.get_object ("settings_ok_button");
        deviceInput = (Gtk.Entry)builder.get_object ("settings_device_input");
        baudRateInput = (Gtk.Entry)builder.get_object ("settings_baudrate_input");

        baudRateCombo = (ComboBox) builder.get_object ("settings_baud_rate");
        MoUtils.populateComboBox (baudRateCombo, Settings.BaudRateItems, false);

        dataBitsCombo = (ComboBox) builder.get_object ("settings_data_bits");
        MoUtils.populateComboBox (dataBitsCombo, Settings.DataBitItems);

        stopBitsCombo = (ComboBox) builder.get_object ("settings_stop_bits");
        MoUtils.populateComboBox (stopBitsCombo, Settings.StopBitItems);

        parityCombo = (ComboBox) builder.get_object ("settings_parity");
        MoUtils.populateComboBox (parityCombo, Settings.ParityModeStrings);

        hardwareHandshake = (CheckButton) builder.get_object ("settings_hardware_handshake");
        hardwareHandshake.set_tooltip_text (_("Also known as RTS/CTS handshaking"));

        softwareHandshake = (CheckButton) builder.get_object ("settings_software_handshake");
        softwareHandshake.set_tooltip_text (_("Also known as XON/XOFF handshaking"));

        accessModeCombo = (ComboBox) builder.get_object ("settings_open_for");
        MoUtils.populateComboBox (accessModeCombo, Settings.AccessModeStrings);

        localEcho = (CheckButton) builder.get_object ("settings_local_echo");
        localEcho.set_tooltip_text (_("Normally disabled"));

        autoConnect = (CheckButton) builder.get_object ("settings_auto_connect");
        autoConnect.set_tooltip_text (_("Enable to automatically connect on startup or when a profile is loaded"));

        dialog.delete_event.connect (hide);
        cancelButton.clicked.connect (this.cancel);
        okButton.clicked.connect (this.ok);

        deviceCombo = (ComboBox) builder.get_object ("settings_device");
        deviceModel = new Gtk.ListStore (1, typeof (string));
        deviceCombo.set_model (deviceModel);
        // CellRenderText on deviceCombo provided by GtkEntry field.
    }

    private void populateDevices ()
    {
        List<string> deviceTypes = new List<string> ();
        deviceTypes.append ("/dev/ttyAMA");
        deviceTypes.append ("/dev/ttyS");
        deviceTypes.append ("/dev/ttyUSB");
        deviceTypes.append ("/dev/pts/");
        deviceTypes.append ("/dev/ttyACM");
        deviceTypes.append ("/dev/rfcomm");
        deviceTypes.append ("/dev/cuaU");
        deviceTypes.append ("/dev/cua");

        deviceModel.clear ();
        TreeIter iter;

        foreach (string devType in deviceTypes) {
            for (int i = 0; i < max_devices; i++) {
                string dev = "%s%d".printf (devType, i);
                if (FileUtils.test (dev, FileTest.EXISTS)) {
                    deviceModel.append (out iter);
                    deviceModel.set (iter, 0, dev);
                }
            }
        }
    }

    public void show (Settings settings)
    {
        populateDevices ();
        this.currentSettings = settings;
        loadSettings ();
        dialog.show_all ();
    }

    // Load the current settings into the dialog
    public void loadSettings ()
    {
        TreeModel t;
        TreeIter ti;
        bool success;

        // Device
        t = deviceCombo.get_model ();
        success = t.get_iter_first (out ti);
        while (success) {
            Value str_data;
            t.get_value (ti, 0, out str_data);
            if (str_data.get_string () == currentSettings.device)
                deviceCombo.set_active_iter (ti);
            success = t.iter_next (ref ti);
        }

        // Baud Rate
        baudRateInput.set_text ("%i".printf (currentSettings.baudRate));

        // Data Bits
        t = dataBitsCombo.get_model ();
        success = t.get_iter_first (out ti);
        while (success) {
            Value str_data;
            t.get_value (ti, 0, out str_data);
            if (str_data.get_string () == "%i".printf (currentSettings.dataBits))
                dataBitsCombo.set_active_iter (ti);
            success = t.iter_next (ref ti);
        }

        // Stop Bits
        t = stopBitsCombo.get_model ();
        success = t.get_iter_first (out ti);
        while (success) {
            Value str_data;
            t.get_value (ti, 0, out str_data);
            if (str_data.get_string () == "%i".printf (currentSettings.stopBits))
                stopBitsCombo.set_active_iter (ti);
            success = t.iter_next (ref ti);
        }

        parityCombo.set_active ((int) currentSettings.parity);
        accessModeCombo.set_active ((int) currentSettings.accessMode);

        hardwareHandshake.set_active (false);
        softwareHandshake.set_active (false);
        if (currentSettings.handshake == Settings.Handshake.BOTH || currentSettings.handshake == Settings.Handshake.HARDWARE)
            hardwareHandshake.set_active (true);
        if (currentSettings.handshake == Settings.Handshake.BOTH || currentSettings.handshake == Settings.Handshake.SOFTWARE)
            softwareHandshake.set_active (true);
        if (currentSettings.localEcho)
            localEcho.set_active (true);
        else
            localEcho.set_active (false);
        if (currentSettings.autoConnect)
            autoConnect.set_active (true);
        else
            autoConnect.set_active (false);

    }

    public bool hide ()
    {
        dialog.hide ();
        return true;
    }

    public void cancel (Widget w)
    {
        currentSettings = null;
        dialog.hide ();
    }

    public void ok (Widget w)
    {

        string device;
        int baudRate;
        int dataBits;
        int stopBits;
        Settings.Parity parity;
        Settings.Handshake handshake;
        Settings.AccessMode accessMode;
        bool pLocalEcho;
        bool pAutoConnect;

        if (deviceInput.get_text_length () == 0) {
            device = Settings.DEFAULT_DEVICEFILE;
        } else {
            device = deviceInput.get_text ();
        }

        string unparsed = null;
        if (!int.try_parse (baudRateInput.get_text (), out baudRate, out unparsed, 10)) {
            var dialog = new MessageDialog (
                this.parent,
                DialogFlags.DESTROY_WITH_PARENT,
                MessageType.ERROR,
                ButtonsType.CLOSE, "Please enter valid baud rate!");
            dialog.run ();
            dialog.destroy ();
            return;
        }

        dataBits = int.parse (Settings.DataBitItems[dataBitsCombo.get_active ()]);
        stopBits = int.parse (Settings.StopBitItems[stopBitsCombo.get_active ()]);

        parity = (Settings.Parity)parityCombo.get_active ();
        accessMode = (Settings.AccessMode)accessModeCombo.get_active ();

        if (hardwareHandshake.get_active () && softwareHandshake.get_active ())
            handshake = Settings.Handshake.BOTH;
        else if (hardwareHandshake.get_active ())
            handshake = Settings.Handshake.HARDWARE;
        else if (softwareHandshake.get_active ())
            handshake = Settings.Handshake.SOFTWARE;
        else
            handshake = Settings.Handshake.NONE;
        pLocalEcho = localEcho.get_active ();
        pAutoConnect = autoConnect.get_active ();
        settings = new Settings (device, baudRate, dataBits, stopBits, parity,
                                 handshake, accessMode, pLocalEcho, pAutoConnect);
        currentSettings = settings;
        this.updateSettings (currentSettings);
        dialog.hide ();
    }
}
