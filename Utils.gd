# Singleton containing various utility functions
tool
extends Node

# Path of Godot-Utilities folder
var utils_path: String = get_script().resource_path.get_base_dir()

var RNG: RandomNumberGenerator = RandomNumberGenerator.new() setget set_RNG, get_RNG
var anchor: Node = null setget set_anchor, get_anchor
var canvaslayer: CanvasLayer = null setget set_canvaslayer, get_canvaslayer
var editor_log_label: RichTextLabel = null setget set_editor_log_label, get_editor_log_label

# Returns the RNG object (a RandomNumberGenerator created and randomised on init).
func get_RNG() -> RandomNumberGenerator:
	return RNG

# Returns the anchor node (an Node added to the Utils singleton on ready).
func get_anchor() -> Node:
	if anchor == null:
		assert(is_inside_tree())
		anchor = Node.new()
		add_child(anchor)
	return anchor

func get_canvaslayer() -> CanvasLayer:
	if canvaslayer == null:
		assert(is_inside_tree())
		canvaslayer = CanvasLayer.new()
		add_child(canvaslayer)
	return canvaslayer

func get_editor_log_label() -> Node:
	if editor_log_label == null:
		
		# Create a temporary EditorPlugin and Control
		var plugin: EditorPlugin = EditorPlugin.new()
		var temp: Control = Control.new()
		
		# Add the Control to the editor bottom panel
		plugin.add_control_to_bottom_panel(temp, "")
		
		# Cycle through each node in the bottom panel until the EditorLog is found
		# The class is checked by string, as GDScript does not allow usage of editor node classes
		for node in temp.get_parent().get_children():
			if node.get_class() == "EditorLog":
				editor_log_label = node.get_child(1)
				break
		
		if editor_log_label == null:
			push_error("Could not find the EditorLog node")
		
		# Remove plugin and temp nodes
		plugin.remove_control_from_bottom_panel(temp)
		temp.queue_free()
		plugin.queue_free()
		
		editor_log_label.bbcode_enabled = true
	
	return editor_log_label

# Creates a new node with the passed type, adds it to the anchor, and returns it
func get_unique_anchor(type = Node) -> Node:
	var ret: Node = type.new()
	anchor.add_child(ret)
	return ret

# Returns a random item from [array] using [rng]. If [weights] is passed, the item is selected according to those weights.
func random_array_item(array: Array, weights: PoolRealArray = null, rng: RandomNumberGenerator = get_RNG()):
	
	if weights != null and not weights.empty():
		
		var total: float = 0.0
		for i in array.size():
			if i < weights.size():
				assert(weights[i] >= 0.0)
				total += weights[i]
			else:
				total += 1
		
		var target: float = rng.randf_range(0.0, total)
		total = 0.0
		var i: int = 0
		for weight in weights:
			total += weight
			if total >= target:
				return array[i]
			i += 1
		
		assert(false)
	
	return array[rng.randi() % len(array)]

# Returns a random colour.
# Individual values can be overridden using [r], [g], [b], and [a].
func random_colour(r: float = NAN, g: float = NAN, b: float = NAN, a: float = 1.0, rng: RandomNumberGenerator = get_RNG()) -> Color:
	var ret: Color = Color(rng.randf(), rng.randf(), rng.randf())
	if not is_nan(r):
		ret.r = r
	if not is_nan(g):
		ret.g = g
	if not is_nan(b):
		ret.b = b
	if not is_nan(a):
		ret.a = a
	return ret

# Prints each of the [properties] of [object] by name. If [properties] is not passed, all properties of the script or class are printed. 
func printvars(object: Object, properties: PoolStringArray = null):
	
	if properties == null:
		
		var script: Script = object.get_script()
		if script != null:
			properties = PoolStringArray(script.get_script_constant_map().keys())
			for property in script.get_script_property_list():
				properties.append(property["name"])
		else:
			properties = PoolStringArray(ClassDB.class_get_property_list(object.get_class(), true))
	
	var msg: String = "Object " + str(object) + ":\n---------------------------------------------\n"
	for property in properties:
		var value = object.get(property)
		msg += property + " (" + str(typeof(value)) + "): " + str(value) + "\n"
	msg += "---------------------------------------------"
	
	print(msg)

# Prints a string to the editor log, with BBCode parsing enabled
func print_bbcode(bbcode: String):
	get_editor_log_label().append_bbcode(bbcode)
	get_editor_log_label().newline()

# Prints [message] to the editor log with [colour]ed text.
func printc(message, colour: Color):
	print_bbcode(bbcode_colour_text(str(message), colour))

func print(message):
	print(message)

func prints(messages: Array):
	var msg: String = ""
	for message in messages:
		msg += str(message) + " | "
	print(msg.trim_suffix(" | "))

# Clears the editor output log. If [print_message] is true, prints a message after clearing the log.
func clear_log(print_message: bool = true):
	get_editor_log_label().clear()
	if print_message:
		printc("<Log cleared>\n", Color.coral)

# Calls [function] with [arguments], then returns whatever was printed to the engine log during the call.
# If [passthrough] is false, removes the printed content from the log.
func capture_log_function(function: FuncRef, arguments: Array = [], passthrough: bool = false) -> String:
	var editor_log: RichTextLabel = get_editor_log_label()
	var before: String = editor_log.text
	function.call_funcv(arguments)
	
	var after: String = editor_log.text
	
	# If log was cleared
	if not after.begins_with(before):
		if not passthrough:
			clear_log(false)
		
		return after
	
	var ret: String = after.trim_prefix(before).trim_suffix("\n")
	if not passthrough:
		
		# Removing lines seems to be the only way to erase text while preserving bbcode
		var line: int = before.count("\n")
		for _i in ret.count("\n") + 1:
			editor_log.remove_line(line)
	
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
		return node.global_transform.origin if global else node.transform.origin
	else:
		push_error("Node '" + str(node) + "' isn't a Node2D, Control, or Spatial")
		return Vector2.ZERO

# Sets the local or [global] position of the [node].
# [node] must be a Node2D, Control, or Spatial.
func set_node_position(node: Node, position, global: bool = false):
	if node is Node2D:
		if global:
			node.global_position = position
		else:
			node.position = position
	elif node is Control:
		if global:
			node.rect_global_position = global
		else:
			node.rect_position = global
	elif node is Spatial:
		if global:
			node.global_transform.origin = position
		else:
			node.transform.origin = position
	else:
		push_error("Node '" + str(node) + "' isn't a Node2D, Control, or Spatial")

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

# Loads file at [path], parses its contents as JSON, and returns the result.
func load_json(path: String) -> JSONParseResult:
	var f = File.new()
	if not f.file_exists(path):
		return null
	f.open(path, File.READ)
	var data = f.get_as_text()
	f.close()
	return JSON.parse(data)

# Writes a file at [path] with [data] in JSON format. If [pretty] is true, indentation is added to the file.
func save_json(path: String, data, pretty: bool = false):
	var f = File.new()
	var error: int = f.open(path, File.WRITE)
	if error != OK:
		push_error("Error saving json file '" + path + "': " + str(error))
		return
	f.store_string(JSON.print(data, "\t" if pretty else ""))
	f.close()

# Yields until [emitter] has stopped emitting, and has no remaining particles. [emitter] must be of type Particles, Particles2D, CPUParticles, or CPUParticles2D.
func yield_particle_completion(emitter: Node):
	assert(emitter is Particles or emitter is Particles2D or emitter is CPUParticles or emitter is CPUParticles2D)
	
	while emitter.emitting:
		while emitter.emitting:
			yield(get_tree(), "idle_frame")
		
		yield(get_tree().create_timer(emitter.lifetime / emitter.speed_scale), "timeout")

# TODO
enum DIR2DICT_MODES {NESTED, SINGLE_LAYER_DIR, SINGLE_LAYER_FILE}
func dir2dict(path: String, mode: int = DIR2DICT_MODES.NESTED, allowed_files = null, allowed_extensions = null, top_path: String = ""):
	var ret: Dictionary = {}
	var data: Dictionary = ret
	if top_path == "":
		top_path = path
	
	var dir: Directory = Directory.new()
	
	var error: int = dir.open(path)
	if error != OK:
		return error
	
	for file in get_dir_items(dir):
		if dir.dir_exists(file):
			if mode == DIR2DICT_MODES.NESTED:
				data[file] = dir2dict(path + file + "/", mode, allowed_files, allowed_extensions, top_path)
			else:
				var layer_data: Dictionary = dir2dict(path + file + "/", mode, allowed_files, allowed_extensions, top_path)
				for key in layer_data:
					data[key] = layer_data[key]
		else:
			file = file.trim_suffix(".import")
			if (allowed_files == null or file in allowed_files) and (allowed_extensions == null or file.split(".")[1] in allowed_extensions):
				var key: String
				match mode:
					DIR2DICT_MODES.NESTED: key = file.split(".")[0]
					DIR2DICT_MODES.SINGLE_LAYER_DIR: key = path.trim_prefix(top_path)
					DIR2DICT_MODES.SINGLE_LAYER_FILE: key = path.trim_prefix(top_path) + file.split(".")[0]
				data[key.trim_suffix("/")] = path + file
	
	return ret

# Returns true if [node] has a parent
func node_has_parent(node: Node) -> bool:
	return is_instance_valid(node.get_parent())

# Constructs and returns a Sprite node from the passed [tilemap] and [cell_position]. If [use_world_position] is true, treats [cell_position] as a global coordinate.
# If [use_sprite] is passed, uses it as the Sprite instead of creating a new one.
func get_tilemap_tile_sprite(tilemap: TileMap, cell_position: Vector2, use_world_position: bool = true, use_sprite: Sprite = null) -> Sprite:
	
	# Convert global position to local cell position
	if use_world_position:
		cell_position = tilemap.world_to_map(tilemap.to_local(cell_position))
	
	var tile: int = tilemap.get_cellv(cell_position)
	assert(tile != TileMap.INVALID_CELL)
	
	var tileset: TileSet = tilemap.tile_set
	
	var sprite: Sprite = Sprite.new() if use_sprite == null else use_sprite
	sprite.region_enabled = true
	sprite.texture = tileset.tile_get_texture(tile)
	sprite.modulate = tileset.tile_get_modulate(tile)
	
	if tilemap.is_cellv_autotile(cell_position):
		sprite.region_rect = Rect2(tilemap.get_cellv_autotile_coord(cell_position) * (tileset.autotile_get_size(tile) + Vector2.ONE * tileset.autotile_get_spacing(tile)), tileset.autotile_get_size(tile))
	else:
		sprite.region_rect = tileset.tile_get_region(tile)
	
	return sprite

# Calls the append function on [array] with [append_value]
func array_append(array: Array, append_value):
	array.append(append_value)

func yield_functions(functions: Array):
	var running_functions: ExArray = ExArray.new()
	for function in functions:
		if function is GDScriptFunctionState and function.is_valid():
			running_functions.append(function)
			function.connect("completed", running_functions, "erase", [function])
	
	while not running_functions.empty():
		yield(running_functions, "items_removed")

# Calls each function connected to [signal_name] of [object], and yields each function until complered
func emit_signal_and_yield(object: Object, signal_name: String):
	var running_functions: ExArray = ExArray.new()
	for connection in object.get_signal_connection_list(signal_name):
		var function = connection["target"].callv(connection["method"], connection["binds"])
		if function is GDScriptFunctionState:
			running_functions.append(function)
			function.connect("completed", running_functions, "erase", [function])
	
	if running_functions.empty():
		yield(get_tree(), "idle_frame")
	else:
		while not running_functions.empty():
			yield(running_functions, "items_removed")

# Swaps the values of [property_a] and [property_b] on [object]
func swap_values(object: Object, property_a: String, property_b: String):
	var value_a = object.get(property_a)
	object.set(property_a, object.get(property_b))
	object.set(property_b, value_a)

# Adds [child] to [node], then sets ownership of child to the scene root so that it appears in the editor
func tool_add_child(node: Node, child: Node):
	assert(Engine.editor_hint and node.is_inside_tree())
	node.add_child(child)
	child.set_owner(node.get_tree().get_edited_scene_root())

# Returns an array of the script export properties of [object]
func get_export_property_list(object: Object) -> PoolStringArray:
	var script: Script = object.get_script()
	assert(script != null)
	
	var ret: PoolStringArray = PoolStringArray()
	for property in script.get_script_property_list():
		if property["usage"] in [PROPERTY_USAGE_EDITOR,
								PROPERTY_USAGE_DEFAULT,
								PROPERTY_USAGE_DEFAULT_INTL
								]:
			ret.append(property["name"])
	
	return ret

class Callback extends Reference:
	var callback: FuncRef
	var binds: Array
	var standalone: bool
	
	var attached_node: Node = null setget attach_to_node
	const ATTACHED_NODE_META_NAME: String = "CONNECTED_CALLBACKS"
	
	signal CALLED(binds)
	
	func _init(callback: FuncRef, binds: Array = [], standalone: bool = false):
		self.callback = callback
		self.binds = binds
		self.standalone = standalone
	
	func attach_to_node(node: Node) -> Callback:
		if node == attached_node:
			return self
		
		# Detach from previous node
		if attached_node != null and is_instance_valid(attached_node) and attached_node.has_meta(ATTACHED_NODE_META_NAME):
			attached_node.get_meta(ATTACHED_NODE_META_NAME).erase(self)
		
		attached_node = node
		
		# Attach to new node
		if attached_node != null:
			assert(is_instance_valid(attached_node), "Node must be a valid instance")
			if attached_node.has_meta(ATTACHED_NODE_META_NAME):
				attached_node.get_meta(ATTACHED_NODE_META_NAME).append(self)
			else:
				attached_node.set_meta(ATTACHED_NODE_META_NAME, [self])
		
		return self
	
	func detach_from_node():
		attach_to_node(null)
	
	func connect_signal(signal_object: Object, signal_name: String, auto_attach: bool = false) -> Callback:
		if not is_signal_connected(signal_object, signal_name):
			signal_object.connect(signal_name, self, CALLBACK_METHOD)
		
		if auto_attach:
			assert(signal_object is Node, "Cannot attach to a non-node object")
			attach_to_node(signal_object)
		
		return self
	
	func disconnect_signal(signal_object: Object, signal_name: String) -> Callback:
		if is_signal_connected(signal_object, signal_name):
			signal_object.disconnect(signal_name, self, CALLBACK_METHOD)
		return self
	
	func is_signal_connected(signal_object: Object, signal_name: String) -> bool:
		return signal_object.is_connected(signal_name, self, CALLBACK_METHOD)
	
	func _notification(what: int):
		if what == NOTIFICATION_PREDELETE and attached_node == null and not standalone:
			push_error("Callback was freed prematurely")
	
	const CALLBACK_METHOD: String = "call_callback"
	func call_callback(_a=0, _b=0, _c=0, _d=0, _e=0, _f=0, _g=0, _h=0, _i=0, _j=0):
		if callback != null:
			callback.call_funcv(binds)
		emit_signal("CALLED", binds)

# ------------------------------

func _init():
	RNG.randomize()

# Deleted function
func set_RNG(_value: RandomNumberGenerator):
	return

# Deleted function
func set_anchor(_value: Node):
	return

# Deleted function
func set_canvaslayer(_value: CanvasLayer):
	return

# Deleted function
func set_editor_log_label(_value: RichTextLabel):
	return
