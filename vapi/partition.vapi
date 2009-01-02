namespace GnomeFormat {
	[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "gnome-format-partition.h")]
	public void create_partition(string block_dev, string fs) throws GLib.Error;
}

