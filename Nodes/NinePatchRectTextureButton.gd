extends NinePatchRect
tool

enum _TEXTURE_STATES {NORMAL, PRESSED, HOVER, DISABLED}
var _texture_state: int = _TEXTURE_STATES.NORMAL setget set_texture_state

export var text: String = "" setget set_text
export var text_font: Font setget set_text_font
export var text_position_base: float = 0.0
export var text_position_pressed: float = 0.0
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
	if pressed:
		set_texture_state(_TEXTURE_STATES.PRESSED)
		text_label.rect_position.y = text_position_pressed
	else:
		set_texture_state(_TEXTURE_STATES.HOVER if mouse_inside else _TEXTURE_STATES.NORMAL)
		text_label.rect_position.y = text_position_base

func _on_item_rect_changed():
	button.rect_size = rect_size
	text_label.rect_size = rect_size

func _ready():
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
	_on_item_rect_changed()
	_on_pressed_changed(false)

func set_texture_state(value: int):
	_texture_state = value
	match _texture_state:
		_TEXTURE_STATES.NORMAL: texture = texture_normal
		_TEXTURE_STATES.PRESSED: texture = texture_pressed
		_TEXTURE_STATES.HOVER: texture = texture_hover
		_TEXTURE_STATES.DISABLED: texture = texture_disabled

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
