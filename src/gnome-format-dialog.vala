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

using Gtk;
using Glade;
using GLib;
using Gee;


namespace GnomeFormat {

        public class FormatDialog : Gtk.Object {

                private Window window;
                private Gtk.Builder builder;
                private ComboBox volume_combo;
                private ComboBox fs_type_combo;
                private Button info_button;
                private Button advanced_button;
                private Button close_button;
                private Button format_button;
                private Button final_format_button;
                private MessageDialog security_question_dialog;
                private AboutDialog about_dialog;
                private MessageDialog error_dialog;
                
                private Gee.List<Storage> storage_devices;
                private GLib.DesktopAppInfo gparted_desktop;
                private IStorageProvider storage_provider;
                
                private static string[] filesystems;
                
                public FormatDialog(IStorageProvider storage_provider) {
                
                        storage_devices = new ArrayList<Storage>();
                        filesystems = new string[] {"fat32", "ext2"};

                        this.storage_provider = storage_provider;
                        this.storage_provider.storage_added += on_storage_added;
                        this.storage_provider.storage_removed += on_storage_removed;

                        // setup the GUI
                        builder = new Gtk.Builder();
                        try {
                                builder.add_from_file("%s/gnome-format.ui".printf(Config.PACKAGE_DATADIR));
                        } catch (GLib.Error e) {
                                error("%s", e.message);
                        }
                
                        // get widgets
                        window = (Window) builder.get_object("main_window");
                        volume_combo = (ComboBox) builder.get_object("volume_combobox");
                        fs_type_combo = (ComboBox) builder.get_object("fs_type_combobox");
                        info_button = (Button) builder.get_object("info_button");
                        advanced_button = (Button) builder.get_object("advanced_button");
                        close_button = (Button) builder.get_object("close_button");
                        format_button = (Button) builder.get_object("format_button");
                        final_format_button = (Button) builder.get_object("final_format_button");
                        security_question_dialog = (MessageDialog) builder.get_object("security_question_dialog");
                        about_dialog = (AboutDialog) builder.get_object("about_dialog");
                        error_dialog = (MessageDialog) builder.get_object("error_dialog");
                        
                        // make the dialogs belong to the window
                        about_dialog.set_transient_for(window);
                        error_dialog.set_transient_for(window);
                        security_question_dialog.set_transient_for(window);
                        
                        // connect signals
                        window.delete_event += on_window_delete_event;
                        info_button.clicked += on_info_button_clicked;
                        advanced_button.clicked += on_advanced_button_clicked;
                        close_button.clicked += on_close_button_clicked;
                        format_button.clicked += on_format_button_clicked;
                        final_format_button.clicked += on_final_format_button_clicked;
                        volume_combo.changed += on_volume_combo_changed;
                        
                        // setup volume combobox
                        ListStore volume_model = new ListStore(1, typeof(string));
                        volume_combo.set_model(volume_model);
                        
                        CellRendererText cell1 = new CellRendererText();
                        volume_combo.pack_start(cell1, true);
                        volume_combo.add_attribute(cell1, "text", 0);

                        // setup filesystem combobox                        
                        ListStore fs_type_model = new ListStore(1, typeof(string));
                        fs_type_combo.set_model(fs_type_model);

                        CellRendererText cell2 = new CellRendererText();
                        fs_type_combo.pack_start(cell2, true);
                        fs_type_combo.add_attribute(cell2, "text", 0);
                        
                        // hide the "Advanced..." button, if GParted is not installed
                        gparted_desktop = new GLib.DesktopAppInfo("gparted.desktop");;
                        if (gparted_desktop == null){
                                advanced_button.hide();
                        }
                        
                        // make the window visible
                        window.show();
                        
                        // add values to comboboxes
                        fill_volumes();
                        fill_fs_types();
                }

                /* ------------------------------------------------------------------ */
                /*  methods                                                           */
                /* ------------------------------------------------------------------ */

                private void fill_volumes() {
                        Gee.List<Storage> devices = storage_provider.get_devices();
                        
                        foreach (Storage s in devices) {
                                add_storage(s);
                        }
                }

                private void fill_fs_types() {
                        fs_type_combo.append_text(_("FAT (Compatible with all computers)"));
                        fs_type_combo.append_text(_("ext2 (Compatible only with Linux)"));
                        
                        fs_type_combo.set_active(0);
                }
                
                private void quit() {
                        Gtk.main_quit();
                }

                private void add_storage(Storage s) {
                        storage_devices.add(s);
                        volume_combo.append_text(s.get_readable_name());
                }
                
                private void remove_storage(string udi) {
                        int i = -1;
                        for (i = 0; i < storage_devices.size; i++) {
                                Storage s = storage_devices.get(i);
                                if (s.udi == udi) {
                                        break;
                                }
                        }
                        
                        if (i < storage_devices.size) {
                                storage_devices.remove_at(i);
                                volume_combo.remove_text(i);
                        }
                }
                
                /* ------------------------------------------------------------------ */
                /*  signal callbacks                                                  */
                /* ------------------------------------------------------------------ */

                public bool on_window_delete_event(Gtk.Window window) {
                        quit();
                        return true;
                }

                public void on_close_button_clicked(Gtk.Button button) {
                        quit();
                }
                
                public void on_info_button_clicked(Button button) {
                        about_dialog.run();
                        about_dialog.hide();
                }
                
                public void on_format_button_clicked(Gtk.Button button) {
                        Storage s = storage_devices.get(volume_combo.get_active());
                
                        if (Config.DEBUG)
                                debug(_("Formatting %s"), s.block_device);

                        security_question_dialog.set_markup(_("<b>Really format \"%s\"?</b>").printf(s.model));
                        security_question_dialog.run();
                        security_question_dialog.hide();
                }

                public void on_final_format_button_clicked(Gtk.Button button) {
                        security_question_dialog.hide();

                        Storage s = storage_devices.get(volume_combo.get_active());
                        
                        // TODO unmount if mounted
/*
                        File file = File.new_for_path(s.block_device);
                        file.unmount_mountable(MountUnmountFlags.NONE, null, on_unmount_ready);
                        // this doesn't do, what I thought it would
*/
                        
                        string filesystem = filesystems[fs_type_combo.get_active()];

                        if (Config.DEBUG)
                                debug(_("Creating partition on %s"), s.block_device);

                        // i think, floppies don't have partition tables TODO: verify
                        if (s.drive_type != DriveType.floppy) {
                                // TODO make this threaded, so the GUI doesn't hang
                                try {
                                        create_partition(s.block_device, filesystem);
                                } catch (GLib.Error e) {
                                        message("%s", e.message);
                                        error_dialog.set_markup(e.message);
                                        error_dialog.run();
                                        error_dialog.hide();
                                }
                        }

                        // TODO mount? (does nautilus do this? do we want this?)
                }
                
                public static void on_unmount_ready(GLib.Object obj, AsyncResult result) {
                        message("%s", obj.get_type().name());
                        message("%s", result.get_source_object().get_type().name());
                }
                
                public void on_advanced_button_clicked(Gtk.Button button) {
                        GLib.List<GLib.File> args = new GLib.List<GLib.File>();
                        
                        if (volume_combo.get_active() >= 0) {
                                string block_dev = storage_devices.get(volume_combo.get_active()).block_device;
                                if (block_dev != null) {
                                        args.append(GLib.File.new_for_path(block_dev));
                                }
                        }
                        
                        if (gparted_desktop != null){
                                try {
                                        gparted_desktop.launch(args, new GLib.AppLaunchContext());
                                } catch {
                                        message(_("problem launching gparted, probably not installed?"));
                                }
                                quit();
                        } else {
                                message(_("GParted seems not to be installed."));
                        }

                }
                
                public void on_storage_added(IStorageProvider storage_provider, string udi) {
                        Storage s = storage_provider.get_storage_device(udi);
                        add_storage(s);
                }

                public void on_storage_removed(IStorageProvider storage_provider, string udi) {
                        remove_storage(udi);
                }
                
                public void on_volume_combo_changed(ComboBox volume_combo) {
                        if (volume_combo.get_active() >= 0) {
                                format_button.set("sensitive", true);
                        } else {
                                format_button.set("sensitive", false);
                                security_question_dialog.hide();
                        }
                }
        }
}

