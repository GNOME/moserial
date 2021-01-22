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
public class DefaultPaths : GLib.Object
{
    public string ? recordTo { get; set; }
    public string ? receiveTo { get; set; }
    public string ? sendFrom { get; set; }

    public DefaultPaths (string ? RecordTo, string ? ReceiveTo, string ? SendFrom)
    {
        this.recordTo = RecordTo;
        this.receiveTo = ReceiveTo;
        this.sendFrom = SendFrom;
    }

    public void saveToProfile (Profile profile)
    {
        if (recordTo != null)
            profile.setString ("paths", "last_record_path", recordTo);
        if (receiveTo != null)
            profile.setString ("paths", "last_receive_path", receiveTo);
        if (sendFrom != null)
            profile.setString ("paths", "last_send_path", sendFrom);
    }

    public static DefaultPaths loadFromProfile (Profile profile)
    {
        string ? RecordTo = null;
        string ? ReceiveTo = null;
        string ? SendFrom = null;

        RecordTo = getPath (profile, "paths", "last_record_path");
        ReceiveTo = getPath (profile, "paths", "last_receive_path");
        SendFrom = getPath (profile, "paths", "last_send_path");

        return new DefaultPaths (RecordTo, ReceiveTo, SendFrom);
    }

    public static string ? getPath (Profile profile, string group, string key)
    {
        string ? path = null;
        path = profile.getString (group, key);
        if ((path==null) || !MoUtils.fileExists (path))
            return null;
        return path;
    }
}

