tool
extends EditorPlugin

const singleton_name: String = "Utils"
var plugin_dir_path: String

func _enter_tree():
	plugin_dir_path = get_script().resource_path.get_base_dir() + "/"
	add_autoload_singleton(singleton_name, plugin_dir_path + "Utils.gd")
