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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <glib.h>

#include <parted/parted.h>

#include <config.h>

#include "gnome-format-partition.h"

#define try(exp) { \
                   if(error_message) g_free(error_message); \
                   (exp); \
                   if (error_message) { \
                     g_set_error(error, 0, -1, "%s", error_message); \
                     return; \
                   } \
                 }
                                

gchar *error_message;

PedExceptionOption
parted_exception_handler(PedException* ex) {
        if(error_message) g_free(error_message);
        error_message = g_strdup(ex->message);
        return PED_EXCEPTION_OK;
}

void
gnome_format_create_partition(gchar *block_dev, gchar *fs, GError **error) {

        PedDevice *device;
        PedDisk *disk;
        PedFileSystemType *fs_type;
        PedPartition *part;
        
        ped_exception_set_handler(parted_exception_handler);
        
        try(device = ped_device_get(block_dev));
        try(disk = ped_disk_new(device));
        
        int last_part_num = ped_disk_get_last_partition_num(disk);
        if (last_part_num != -1) {
                // if partitions exist, delete them
                try(ped_disk_delete_all(disk));
        }

        long long end = device->length - 1;

        try(fs_type = ped_file_system_type_get(fs));
        
        // create new partition
        try(part = ped_partition_new(disk, PED_PARTITION_NORMAL, fs_type, 1, end));
        try(ped_disk_add_partition(disk, part, ped_constraint_any(device)));

        try(ped_file_system_create(&part->geom, fs_type, NULL));
                
        // commit changes
        try(ped_disk_commit_to_dev(disk));
        
        // this needs root priviliges
//        try(ped_disk_commit_to_os(disk));

#ifdef DEBUG
        printf("device.sector_size: %lld\n", device->sector_size);
        printf("device.length: %lld\n", device->length);
        printf("end: %lld\n", end);
#endif
        
        // free stuff
        ped_disk_destroy(disk);
        ped_device_destroy(device);
}

