extends WindowDialog
class_name CustomDialog

# Emitted when a dialog action (button pressed or dialog closed) occurs
signal ACTION_OCCURRED(action)

# The default options used when calling create_and_yield()
const DEFAULT_OPTIONS: Dictionary = {
	"buttons": ["OK", "Cancel"], # Buttons to add automatically
	"title": "Confirm", # Title text
	"body": "", # Body text
	"pause": true, # If true, pauses the SceneTree while the dialog is displayed
	"closable": false, # Whether the dialog can be closed without selecting an option
	"resizable": true, # Whether the dialog can be resized manually,
	"min_size": Vector2(300, 125),
	"input": false,
	"input_hint": "",
	"input_initial": "",
	"input_max": 0,
	"input_close_on_enter": true
}

# - Public properties -
var closable: bool = true setget set_closable # Whether the dialog can be closed using the close button or clicking away
var last_action: Action = null # The most recently occurred action

# - Internal properties -
var freed: bool = false # Set to true when the dialog is about to be freed from memory
var label: Label # Label displaying the dialog's main body text
var main_container: VBoxContainer
var button_container: HBoxContainer # Contains buttons added using [add_button]
var input_field: LineEdit
var initial_paused: bool = null
var applied_options: Dictionary

# Data class containing information about a dialog action
class Action extends Reference:
	enum TYPE {BUTTON, INPUT_CONFIRM, CLOSE}
	var type: int
	var button: String
	var input_text: String
	
	func _init(type: int, dialog: CustomDialog, button: String = null):
		self.type = type
		self.button = button
		self.input_text = dialog.input_field.text
		dialog._on_action_occurred(self)
	
	# True if an action button was pressed
	func is_button() -> bool:
		return type == TYPE.BUTTON
	
	# True if 'enter' was pressed while entering text
	func is_input_confirm() -> bool:
		return type == TYPE.INPUT_CONFIRM
	
	# True if the dialog was closed by the user
	func is_close() -> bool:
		return type == TYPE.CLOSE
	
	# Type ID of this action
	func get_type() -> int:
		return type
	
	# ID of the pressed button if this is a button action, otherwise null
	func get_button() -> String:
		return button if is_button() else null
	
	# Text contained within the input field when the action occurred
	func get_input_text() -> String:
		return input_text

func _init(options: Dictionary = DEFAULT_OPTIONS):
	connect("popup_hide", self, "_on_hide")
	
	var margin_container: MarginContainer = MarginContainer.new()
	add_child(margin_container)
	margin_container.anchor_bottom = 1
	margin_container.anchor_right = 1
	margin_container.set("custom_constants/margin_left", 10)
	margin_container.set("custom_constants/margin_right", 10)
	margin_container.set("custom_constants/margin_top", 10)
	margin_container.set("custom_constants/margin_bottom", 10)
	
	main_container = VBoxContainer.new()
	margin_container.add_child(main_container)
	main_container.connect("draw", self, "_update_container_size", [margin_container])
	main_container.set("custom_constants/separation", 10)
	main_container.anchor_bottom = 1
	main_container.anchor_right = 1
	
	label = Label.new()
	label.autowrap = true
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(label)
	
	input_field = LineEdit.new()
	input_field.connect("text_entered", self, "_on_input_text_entered")
	main_container.add_child(input_field)
	
	button_container = HBoxContainer.new()
	main_container.add_child(button_container)
	button_container.set("custom_constants/separation", 25)
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.alignment = BoxContainer.ALIGN_CENTER
	
	apply_options(options)

func _update_container_size(container: Control):
	container.rect_size = rect_size

func apply_options(options: Dictionary):
	
	# Fill missing options with the default values
	for option in DEFAULT_OPTIONS:
		if not option in options:
			options[option] = DEFAULT_OPTIONS[option]
	
	# - Apply options -
	add_buttons(options["buttons"])
	
	window_title = options["title"]
	label.text = options["body"]
	self.closable = options["closable"]
	resizable = options["resizable"]
	rect_min_size = options["min_size"]
	
	input_field.visible = options["input"]
	input_field.text = options["input_initial"]
	input_field.placeholder_text = options["input_hint"]
	
	if options["pause"]:
		pause_mode = Node.PAUSE_MODE_PROCESS
		initial_paused = Game.get_tree().paused
		Game.get_tree().paused = true
	
	applied_options = options

# Adds a button to the dialog with [text]. If [id] is not passed, [text] is used as the ID instead.
func add_button(text: String, id: String = null) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.connect("pressed", self, "_on_button_pressed", [id if id != null else text])
	button.focus_mode = Control.FOCUS_NONE
	button_container.add_child(button)
	return button

func add_buttons(buttons: Array):
	for button in buttons:
		add_button(button)

# Creates and displays new dialog using [options], yields the ACTION_OCCURRED signal, and returns the occurred action.
static func create_and_yield_option(options: Dictionary = DEFAULT_OPTIONS) -> Action:
	var dialog: CustomDialog = load(Utils.utils_path.plus_file("Nodes/CustomDialog.gd")).new(options)
	Utils.get_canvaslayer().add_child(dialog)
	
	dialog.popup_centered()
	var action: CustomDialog.Action = yield(dialog, "ACTION_OCCURRED")
	dialog.queue_free()
	
	return action

func _on_button_pressed(button_id: String):
	if not is_responsive():
		return
	
	last_action = Action.new(Action.TYPE.BUTTON, self, button_id)
	emit_signal("ACTION_OCCURRED", last_action)

func _on_hide():
	if not is_responsive():
		return
	
	last_action = Action.new(Action.TYPE.CLOSE, self)
	emit_signal("ACTION_OCCURRED", last_action)

func _on_input_text_entered(_text: String):
	
	if not is_responsive() or not applied_options["input_close_on_enter"]:
		return
	
	last_action = Action.new(Action.TYPE.INPUT_CONFIRM, self)
	emit_signal("ACTION_OCCURRED", last_action)

func _on_action_occurred(action: Action):
	if initial_paused != null and not Game.quitting:
		Game.get_tree().paused = initial_paused
		initial_paused = null
	hide()

func get_last_action() -> Action:
	return last_action

func is_responsive() -> bool:
	return visible and is_instance_valid(Game) and not Game.quitting and not freed

func set_closable(value: bool):
	if closable == value:
		return
	closable = value
	get_close_button().visible = closable
	popup_exclusive = !closable
