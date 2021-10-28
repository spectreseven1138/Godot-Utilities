class_name NinePatchRectTextureButton
extends NinePatchRect
tool

"""
A TextureButton which uses a NinePatchRect in place of the standard texture
"""

signal pressed

enum _TEXTURE_STATES {NORMAL, PRESSED, HOVER, DISABLED}
var _texture_state: int = _TEXTURE_STATES.NORMAL setget set_texture_state

export var text: String = "" setget set_text
export var text_font: Font setget set_text_font
export var text_position_base: float = 0.0 setget set_text_position_base
export var text_position_pressed: float = 0.0
export var node_pressed_offset: float = 0.0
export var disabled: bool = false setget set_disabled

export(Array, NodePath) var nodepaths_to_offset: Array = []
var nodes_to_offset: ExArray = ExArray.new()
var _nodes_to_offset_default_positions: Dictionary = {}

export var texture_normal: Texture setget set_texture_normal
export var texture_pressed: Texture setget set_texture_pressed
export var texture_hover: Texture setget set_texture_hover
export var texture_disabled: Texture setget set_texture_disabled

var mouse_inside: bool = false
var button: Button = Button.new()
var text_label: Label = Label.new()
const text_label_default_position: float = -10.0

func _on_mouse_inside_changed(_mouse_inside: bool):
	mouse_inside = _mouse_inside
	if not button.pressed:
		set_texture_state(_TEXTURE_STATES.HOVER if mouse_inside else _TEXTURE_STATES.NORMAL)

func _on_pressed_changed(pressed: bool):
	for node in nodes_to_offset:
		if node is Node2D:
			node.position.y = _nodes_to_offset_default_positions[node] + (node_pressed_offset if pressed else 0.0)
		elif node is Control:
			node.rect_position.y = _nodes_to_offset_default_positions[node] + (node_pressed_offset if pressed else 0.0)
		else:
			push_error("Node of invalid type added to nodes_to_offset")
	
	if pressed:
		set_texture_state(_TEXTURE_STATES.PRESSED)
		text_label.rect_position.y = text_position_pressed
	else:
		set_texture_state(_TEXTURE_STATES.HOVER if mouse_inside else _TEXTURE_STATES.NORMAL)
		text_label.rect_position.y = text_position_base

func _on_item_rect_changed():
	button.rect_size = rect_size
	text_label.rect_size = rect_size

func _on_button_pressed():
	emit_signal("pressed")

func _init():
	nodes_to_offset.connect("items_added", self, "_on_nodes_to_offset_items_added")

func _ready():
	for nodepath in nodepaths_to_offset:
		nodes_to_offset.append(get_node(nodepath))
	
	if not button.is_inside_tree():
		add_child(button)
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		add_child(text_label)
		text_label.align = Label.ALIGN_CENTER
		text_label.valign = Label.VALIGN_CENTER
		mouse_filter = Control.MOUSE_FILTER_STOP
		connect("mouse_entered", self, "_on_mouse_inside_changed", [true])
		connect("mouse_exited", self, "_on_mouse_inside_changed", [false])
		connect("item_rect_changed", self, "_on_item_rect_changed")
		button.connect("button_down", self, "_on_pressed_changed", [true])
		button.connect("button_up", self, "_on_pressed_changed", [false])
		button.connect("pressed", self, "_on_button_pressed")
	_on_item_rect_changed()
	_on_pressed_changed(false)

func set_texture_state(value: int):
	_texture_state = value
	match _texture_state:
		_TEXTURE_STATES.NORMAL: texture = texture_normal
		_TEXTURE_STATES.PRESSED: texture = texture_pressed
		_TEXTURE_STATES.HOVER: texture = texture_hover
		_TEXTURE_STATES.DISABLED: texture = texture_disabled

func set_all_textures(texture: Texture):
	set_texture_normal(texture)
	set_texture_pressed(texture)
	set_texture_hover(texture)
	set_texture_disabled(texture)

func set_texture_normal(value: Texture):
	texture_normal = value
	set_texture_state(_texture_state)
func set_texture_pressed(value: Texture):
	texture_pressed = value
	set_texture_state(_texture_state)
func set_texture_hover(value: Texture):
	texture_hover = value
	set_texture_state(_texture_state)
func set_texture_disabled(value: Texture):
	texture_disabled = value
	set_texture_state(_texture_state)

func set_text(value: String):
	text = value
	text_label.text = text

func set_text_font(value: Font):
	text_font = value
	text_label.set("custom_fonts/font", text_font)

func get_icon_class() -> String:
	return "TextureButton"

func _on_nodes_to_offset_items_added(items: Array):
	for item in items:
		if item is Node2D:
			_nodes_to_offset_default_positions[item] = item.position.y
		elif item is Control:
			_nodes_to_offset_default_positions[item] = item.rect_position.y
		else:
			push_error("Node of invalid type added to nodes_to_offset")

func set_text_position_base(value: float):
	text_position_base = value
	if _texture_state != _TEXTURE_STATES.PRESSED:
		text_label.rect_position.y = text_position_base

func set_disabled(value: bool):
	disabled = value
	button.disabled = disabled
