/*
 * Copyright © 2008 Michael Kanis <mkanis@gmx.de>
 *
 * This file is part of Gnome Format.
 *
 * Gnome Format is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Gnome Format is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Gnome Format.  If not, see <http://www.gnu.org/licenses/>.
 */

using DBus;
using GLib;
using Gee;


namespace GnomeFormat {

        public class HalStorageProvider : GLib.Object, IStorageProvider {

                private DBus.Connection conn;
                private dynamic DBus.Object hal;
                
                public HalStorageProvider() throws DBus.Error, GLib.Error {
                        conn = DBus.Bus.get (DBus.BusType.SYSTEM);
                        hal = conn.get_object("org.freedesktop.Hal",
                                        "/org/freedesktop/Hal/Manager",
                                        "org.freedesktop.Hal.Manager");
                        
                        hal.DeviceAdded += on_device_added;
                        hal.DeviceRemoved += on_device_removed;
                }

                private void on_device_added(dynamic DBus.Object hal, string udi) {
                        if(Config.DEBUG)
                                debug("%s added", udi);

                        Storage s = get_storage_device(udi);
                        
                        if (s != null && s.drive_type != DriveType.cdrom &&
                                        (s.removable || s.hotpluggable)) {
                                
                                // FIXME this is a workaround, because currently we can't
                                // provide the Storage object itself for some reason (dumps)
                                storage_added(s.udi);
                        }
                }

                private void on_device_removed(dynamic DBus.Object hal, string udi) {
                        if(Config.DEBUG)
                                debug("%s removed", udi);
                        
                        storage_removed(udi);
                }
                
                
                public Gee.List<Storage>? get_devices() {
                
                        Gee.List<Storage> devices = new ArrayList<Storage>();
                
                        string[] haldisks;

                        try {
                                haldisks = hal.find_device_by_capability("storage");
                        } catch (GLib.Error e) {
                                // if the method doesn't exist, something's really weird! exit.
                                // FIXME I think this is not the nicest way to do this
                                error("%s", e.message);
                                return null;
                        }

                        foreach (string udi in haldisks) {
                                Storage s = get_storage_device(udi);
                                
                                if (s != null && (s.removable || s.hotpluggable)
                                                && s.drive_type != DriveType.cdrom
                                                && s.drive_type != DriveType.tape) {
                                                
                                        devices.add(s);
                                }
                        }
                        
                        return devices;
                }
                
                private bool is_storage_device(string udi) {
                        dynamic DBus.Object device = conn.get_object(
                                        "org.freedesktop.Hal", udi,
                                        "org.freedesktop.Hal.Device");
                
                        string[] capabilities;
                        try {
                                capabilities = device.get_property_string("info.capabilities");
                        } catch {
                                return false;
                        }

                        bool is_storage = false;
                        bool is_block = false;
                        foreach (string capability in capabilities) {
                                if (capability == "storage") {
                                        is_storage = true;
                                }
                                if (capability == "block") {
                                        is_block = true;
                                }
                        }
                        
                        return is_storage && is_block;
                }
                
                /**
                 * Get a Storage object from the given HAL udi.
                 *
                 * @return Storage object or null if there is no device with that udi or
                 *         if the device is not a storage device
                 */
                public Storage? get_storage_device(string udi) {
                        
                        if (!is_storage_device(udi)) {
                                return null;
                        }

                        dynamic DBus.Object device = conn.get_object(
                                        "org.freedesktop.Hal", udi,
                                        "org.freedesktop.Hal.Device");
                        
                        Storage s = new Storage();
                        
                        try {
                                s.udi = device.get_property_string("info.udi");
                                s.block_device = device.get_property_string("block.device");
                                s.bus = Storage.get_bus_type(device.get_property_string("storage.bus"));
                                s.drive_type = Storage.get_drive_type(
                                                device.get_property_string("storage.drive_type"));
                                s.removable = device.get_property_string("storage.removable");
                                s.hotpluggable = device.get_property_string("storage.hotpluggable");
                                s.model = device.get_property_string("storage.model");
                                s.vendor = device.get_property_string("storage.vendor");
                        } catch (GLib.Error e) {
                                if (Config.DEBUG)
                                        debug("%s", e.message);
                                
                                // these are all madatory, something's wrong if any of them
                                // doesn't exist, so just retrun null
                                return null;
                        }
                        
                        try {
                                s.size = device.get_property_string("storage.removable.media_size");
                        } catch (DBus.Error e) {
                                if(Config.DEBUG)
                                        debug("%s", e.message);
                        }
                        
                        return s;
                }
        }
}

