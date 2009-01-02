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

using Gee;

namespace GnomeFormat {

        errordomain StorageError {
                UNKNOWN_BUS,
                UNKNOWN_DRIVE_TYPE,
                UNKNOWN_PARTITION_TYPE
        }

        public enum BusType {
                ide, usb, ieee1394, scsi, sata, platform, linux_raid, mmc;
        }
        
        public enum DriveType {
                disk, cdrom, floppy, tape, compact_flash, memory_stick, smart_media,
                sd_mmc;
        }
        
        public enum PartitionType {
                mbr, gpt, apm
        }
        
        public class Storage {
        
                public string udi;
                public string block_device;
        
                public BusType bus;
                public DriveType drive_type;
                public bool removable;
                public bool removable_media_available;
                public bool removable_media_size;
                public PartitionType partitioning_scheme;
                public uint64 size;
                
                public bool hotpluggable;
                public string model;
                public string vendor;
                
                // TODO complete bus types
                public static BusType get_bus_type(string s) throws StorageError {
                        if (s == "ide")
                                return BusType.ide;
                        else if (s == "usb")
                                return BusType.usb;
                        else if (s == "scsi")
                                return BusType.scsi;
                        else if (s == "mmc")
                                return BusType.mmc;
                        else
                                throw new StorageError.UNKNOWN_BUS("Unknown bus type \"%s\"", s);
                }

                // TODO complete drive types
                public static DriveType get_drive_type(string s) throws StorageError {
                        if (s == "disk")
                                return DriveType.disk;
                        else if (s == "cdrom")
                                return DriveType.cdrom;
                        else if (s == "sd_mmc")
                                return DriveType.sd_mmc;
                        else
                                throw new StorageError.UNKNOWN_DRIVE_TYPE("Unknown drive type \"%s\"", s);
                }


                public string get_readable_size() {
                        string[] size_units = new string[]
                                        {"Byte", "KB", "MB", "GB", "TB", "PB"};
        
                        uint64 size2 = size;
                        
                        int i = 0;
                        while (size2 > 1000) {
                                size2 /= 1000;
                                i++;
                        }
                        
                        return "%d %s".printf((int) size2, size_units[i]);
                }
                
                public string get_readable_name() {

                        string name = "%s %s".printf(vendor, model).strip();
                        
                        // some devices don't provide vendor or model name
                        if (name == "")
                                // TODO create a nicer name from bus type and device type
                                name = block_device;
                        
                        string s_size = get_readable_size();
                        
                        return "%s (%s)".printf(name, s_size);
                }
        }
}

