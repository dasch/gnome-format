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

using GLib;

namespace GnomeFormat {

        public static void main(string[] args) {

                // this is a workaround to make Vala include config.h before
                // gi18n-lib.h
                string gettext_package = Config.GETTEXT_PACKAGE;
                
                Intl.bindtextdomain(gettext_package, Config.PACKAGE_LOCALEDIR);
                Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
                Intl.textdomain(Config.GETTEXT_PACKAGE);

                IStorageProvider storage_provider;
                FormatDialog format_dialog;

                Gtk.init (ref args);
                
                try {
                        storage_provider = new HalStorageProvider();
                } catch (Error e) {
                        // can't do anything about an error here. exit with an error.
                        error("%s", e.message);
                }
                
                format_dialog = new FormatDialog(storage_provider);
                Gtk.main();

        }
}
