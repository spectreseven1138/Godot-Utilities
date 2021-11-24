# Singleton containing various utility functions
extends Node

var RNG: RandomNumberGenerator = RandomNumberGenerator.new()

func _init():
	RNG.randomize()

# Returns a random item from the passed array
func random_array_item(array: Array, rng: RandomNumberGenerator = RNG):
	return array[rng.randi() % len(array)]

# Returns a random colour
# Individual RBGA values can be overridden if needed
func random_colour(r: float = NAN, g: float = NAN, b: float = NAN, a: float = NAN, rng: RandomNumberGenerator = RNG) -> Color:
	var ret: Color = Color(rng.randf(), rng.randf(), rng.randf())
	for property in ["r", "g", "b", "a"]:
		if not is_nan(get(property)):
			ret[property] = get(property)
	return ret

# Removes 'node' from its parent, then makes it a child of 'new_parent'
# If 'retain_global_position' is true, the global_position of 'node' will be maintained
func reparent_node(node: Node, new_parent: Node, retain_global_position: bool = false):
	var original_global_position: Vector2
	if retain_global_position:
		original_global_position = get_node_position(node, true)
	
	if node.is_inside_tree():
		node.get_parent().remove_child(node)
	new_parent.add_child(node)
	
	if retain_global_position:
		set_node_position(node, original_global_position, true)

# Equivalent to Node2D.to_local(), but also works for Control nodes
func to_local(position_of: Node, relative_to: Node):
	return get_node_position(position_of, true) - get_node_position(relative_to, true)

# Returns the (global) position of the passed node
# The node must be either a Node2D or Control
func get_node_position(node: Node, global: bool = false) -> Vector2:
	if node is Node2D:
		return node.global_position if global else node.position
	elif node is Control:
		return node.rect_global_position if global else node.rect_position
	else:
		push_error("Node '" + str(node) + "' isn't a Node2D or Control")
		return Vector2.ZERO

# Sets the (global) position of the passed node
# The node must be either a Node2D or Control
func set_node_position(node: Node, position: Vector2, global: bool = false):
	if node is Node2D:
		node.set("global_position" if global else "position", position)
	elif node is Control:
		node.set("rect_global_position" if global else "rect_position", position)
	else:
		push_error("Node '" + str(node) + "' isn't a Node2D or Control")

# Appends the 'append' dictionary onto the 'base' dictionary (values will be overwritten) 
# If 'duplicate_values is true, values that are an array or dictionary will be duplicated
func append_dictionary(base: Dictionary, append: Dictionary, duplicate_values: bool = false):
	for key in append:
		print("APPEND ", key)
		var value = append[key]
		if duplicate_values and (value is Array or value is Dictionary):
			value = value.duplicate()
		base[key] = value

func bbcode_colour_text(text: String, colour: Color) -> String:
	return "[color=#" + colour.to_html() + "]" + text + "[/color]"

func get_line_of_position(string: String, position: int) -> int:
	
	if position == 0:
		return 0
	elif position >= len(string) or position < 0:
		push_error("Position is outside of passed string bounds")
		return -1
	
	var line: int = 0
	for i in position:
		if string[i] == "\n":
			line += 1
	return line

func get_position_of_line(string: String, line: int) -> int:
	if line == 0:
		return 0
	elif line > 0:
		var current_line: int = 0
		for i in len(string):
			if string[i] == "\n":
				current_line += 1
				if current_line == line:
					return i + 1
	
	push_error("Line is outside of passed string bounds")
	return -1

func get_dir_items(dir, skip_navigational: bool = true, skip_hidden: bool = true):
	
	if dir is String:
		var path: String = dir
		dir = Directory.new()
		var error: int = dir.open(path)
		if error != OK:
			return error
	elif not dir is Directory:
		push_error("The 'dir' argument must be a string or Directory")
		assert(false, "The 'dir' argument must be a string or Directory")
		return []
	
	var ret = []
	dir.list_dir_begin(skip_navigational, skip_hidden)
	var file_name = dir.get_next()
	while file_name != "":
		ret.append(file_name)
		file_name = dir.get_next()
	return ret
