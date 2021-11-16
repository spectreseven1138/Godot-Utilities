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
