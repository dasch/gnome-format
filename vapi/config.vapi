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

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "config.h")]

namespace Config {

        public const string GETTEXT_PACKAGE;
        public const string PACKAGE_DATADIR;
        public const string PACKAGE_LOCALEDIR;
        public const string PACKAGE_NAME;
        public const string PACKAGE_VERSION;
        public const string VERSION; 

        public const bool DEBUG;

} 
