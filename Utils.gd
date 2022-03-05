# Singleton containing various utility functions
extends Node

var RNG: RandomNumberGenerator = RandomNumberGenerator.new() setget set_RNG, get_RNG
onready var anchor: Node = Node.new() setget set_anchor, get_anchor

# Returns the RNG object (a RandomNumberGenerator created and randomised on init).
func get_RNG() -> RandomNumberGenerator:
	return RNG

# Returns the anchor node (an Node added to the Utils singleton on ready).
func get_anchor() -> Node:
	return anchor

# Creates a new node with the passed type, adds it to the anchor, and returns it
func get_unique_anchor(type = Node) -> Node:
	var ret: Node = type.new()
	anchor.add_child(ret)
	return ret

# Prints [items] in a single line with dividers.
# If [tprint] is true, prints using the tprint function.
func sprint(items: Array, tprint: bool = false, divider: String = " | "):
	var msg: String = ""
	
	for i in len(items):
		msg += str(items[i])
		if i + 1 != len(items):
			msg += divider
	
	if tprint:
		tprint(msg)
	else:
		print(msg)

# Prints [msg] prepended with the current engine time (OS.get_ticks_msec()). Useful for printing every frame.
func tprint(msg):
	print(OS.get_ticks_msec(), ": ", msg)

# Returns a random item from [array] using [rng].
func random_array_item(array: Array, rng: RandomNumberGenerator = get_RNG()):
	return array[rng.randi() % len(array)]

# Returns a random colour.
# Individual values can be overridden using [r], [g], [b], and [a].
func random_colour(r: float = NAN, g: float = NAN, b: float = NAN, a: float = NAN, rng: RandomNumberGenerator = get_RNG()) -> Color:
	var ret: Color = Color(rng.randf(), rng.randf(), rng.randf())
	for property in ["r", "g", "b", "a"]:
		if not is_nan(get(property)):
			ret[property] = get(property)
	return ret

# Removes [node] from its parent, then adds it to  [new_parent].
# If [retain_global_position] is true, the global_position of [node] will be maintained.
func reparent_node(node: Node, new_parent: Node, retain_global_position: bool = false):
	var original_global_position
	if retain_global_position:
		original_global_position = get_node_position(node, true)
	
	var old_parent: Node = node.get_parent()
	if is_instance_valid(old_parent):
		old_parent.remove_child(node)
	new_parent.add_child(node)
	
	if retain_global_position:
		set_node_position(node, original_global_position, true)

# Returns the position of [position_of] relative to [relative_to].
# Equivalent to Node2D.to_local(), but also works for Control and Spatial nodes.
func to_local(position_of: Node, relative_to: Node) -> Vector2:
	return get_node_position(position_of, true) - get_node_position(relative_to, true)

# Returns the local or [global] position of [node].
# [node] must be a Node2D, Control, or Spatial.
func get_node_position(node: Node, global: bool = false) -> Vector2:
	if node is Node2D:
		return node.global_position if global else node.position
	elif node is Control:
		return node.rect_global_position if global else node.rect_position
	elif node is Spatial:
		return node.global_transform if global else node.transform
	else:
		push_error("Node '" + str(node) + "' isn't a Node2D or Control")
		return Vector2.ZERO

# Sets the local or [global] position of the [node].
# [node] must be a Node2D, Control, or Spatial.
func set_node_position(node: Node, position, global: bool = false):
	if node is Node2D:
		node.set("global_position" if global else "position", position)
	elif node is Control:
		node.set("rect_global_position" if global else "rect_position", position)
	elif node is Spatial:
		node.set("global_transform" if global else "transform", position)
	else:
		push_error("Node '" + str(node) + "' isn't a Node2D or Control")

# Returns the global modulation of [node] (the product of the modulations of the node and all its ancestors).
# In other words, returns the actual modulation applied to the node when rendered.
func get_global_modulate(node: CanvasItem) -> Color:
	var ret: Color = node.modulate
	var root: Viewport = get_tree().root
	
	var parent: Node = node.get_parent()
	while true:
		if parent is CanvasItem:
			ret *= parent.modulate
		parent = parent.get_parent()
		
		if not is_instance_valid(parent) or parent == root:
			break
	
	return ret

# Appends [append] onto [base] (values will be overwritten).
# If [duplicate_values] is true, values that are an array or dictionary will be duplicated.
func append_dictionary(base: Dictionary, append: Dictionary, duplicate_values: bool = false):
	for key in append:
		var value = append[key]
		if duplicate_values and (value is Array or value is Dictionary):
			value = value.duplicate()
		base[key] = value

# Returns [text] as a BBCode formatted string with the passed [colour].
func bbcode_colour_text(text: String, colour: Color) -> String:
	return "[color=#" + colour.to_html() + "]" + text + "[/color]"

# Returns the line number of [position] within [string].
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

# Returns the position of [line] within [string].
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

# Returns the items contained in [directory] as an array. May return an int error.
func get_dir_items(directory, skip_navigational: bool = true, skip_hidden: bool = true):
	assert(directory is String or directory is Directory, "[directory] must be a String or Directory")
	
	if directory is String:
		var path: String = directory
		directory = Directory.new()
		var error: int = directory.open(path)
		if error != OK:
			return error
	
	var ret: Array = []
	directory.list_dir_begin(skip_navigational, skip_hidden)
	var file_name = directory.get_next()
	while file_name != "":
		ret.append(file_name)
		file_name = directory.get_next()
	return ret

func load_json(path: String):
	var f = File.new()
	if not f.file_exists(path):
		return null
	f.open(path, File.READ)
	var data = f.get_as_text()
	f.close()
	return JSON.parse(data).result

func save_json(path: String, data, pretty: bool = false):
	var f = File.new()
	var error: int = f.open(path, File.WRITE)
	if error != OK:
		push_error("Error saving json file '" + path + "': " + str(error))
		return
	f.store_string(JSON.print(data, "\t" if pretty else ""))
	f.close()

func yield_particle_completion(emitter: Node):
	assert(emitter is Particles or emitter is Particles2D or emitter is CPUParticles or emitter is CPUParticles2D)
	if not emitter.emitting:
		return
	
	while emitter.emitting:
		yield(get_tree(), "idle_frame")
	
	yield(get_tree().create_timer(emitter.lifetime / emitter.speed_scale), "timeout")

# ------------------------------

func _init():
	RNG.randomize()

func _ready():
	add_child(anchor)

# Deleted function
func set_RNG(_value: RandomNumberGenerator):
	return

# Deleted function
func set_anchor(_value: Node):
	return

