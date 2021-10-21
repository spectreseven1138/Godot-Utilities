tool
extends EditorPlugin

var plugin_dir_path: String

func _enter_tree():
	plugin_dir_path = get_script().resource_path.get_base_dir() + "/"
	
	var dir: Directory = Directory.new()
	if dir.dir_exists(plugin_dir_path + "Nodes"):
		
		dir.open(plugin_dir_path + "Nodes")
		dir.list_dir_begin(true, true)
		
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() == "gd":
				
				var script: GDScript = load(plugin_dir_path + "Nodes/" + file_name)
				var instance: Object = script.new()
				
				var icon_class: String = instance.get_icon_class() if instance.has_method("get_icon_class") else instance.get_class()
				add_custom_type(file_name.get_basename(), instance.get_class(), script, get_class_icon(icon_class))
				instance.free()
				
			file_name = dir.get_next()

func get_class_icon(cls: String) -> Texture:
	return get_editor_interface().get_base_control().get_icon(cls, "EditorIcons")
