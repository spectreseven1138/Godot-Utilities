extends WindowDialog
class_name CustomDialog

# Emitted when a dialog action (button pressed or dialog closed) occurs
signal ACTION_OCCURRED(action)

# The default options used when calling create_and_yield()
const DEFAULT_OPTIONS: Dictionary = {
	"buttons": ["OK", "Cancel"], # Buttons to add automatically
	"title": "Confirm", # Title text
	"body": "", # Body text
	"pause": false, # If true, pauses the SceneTree while the dialog is displayed
	"closable": false, # Whether the dialog can be closed without selecting an option
	"resizable": true, # Whether the dialog can be resized manually
}

# - Public properties -
var closable: bool = true setget set_closable
var last_action: Action = null # The most recently occurred action

# - Internal properties -
var freed: bool = false # Set to true when the dialog is about to be freed from memory
var label: RichTextLabel # Label displaying the dialog's main body text
var button_container: HBoxContainer # Contains buttons added using [add_button]

# Data class containing information about a dialog action
class Action extends Reference:
	enum TYPE {CLOSE, BUTTON}
	var type: int
	var button: String
	
	func _init(type: int, button: String = null):
		self.type = type
		self.button = button
		
	func is_button() -> bool: # True if an action button was pressed
		return type == TYPE.BUTTON

	func is_close() -> bool: # True if the dialog was closed by the user
		return type == TYPE.CLOSE
	
	func get_type() -> int: # Type ID of this action
		return type
	
	func get_button() -> String: # ID of the pressed button, if this is a button action
		assert(is_button())
		return button

func _init(min_size: Vector2 = Vector2(240, 112)):
	rect_min_size = min_size
	
	connect("popup_hide", self, "_on_hide")
	
	var top_container: MarginContainer = MarginContainer.new()
	add_child(top_container)
	top_container.anchor_bottom = 1
	top_container.anchor_right = 1
	top_container.set("custom_constants/margin_left", 10)
	top_container.set("custom_constants/margin_right", 10)
	top_container.set("custom_constants/margin_top", 10)
	top_container.set("custom_constants/margin_bottom", 10)
	
	var container: VBoxContainer = VBoxContainer.new()
	top_container.add_child(container)
	container.anchor_bottom = 1
	container.anchor_right = 1
	
	label = RichTextLabel.new()
	container.add_child(label)
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	button_container = HBoxContainer.new()
	container.add_child(button_container)
	button_container.set("custom_constants/separation", 25)
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.alignment = BoxContainer.ALIGN_CENTER

func queue_free():
	freed = true
	.queue_free()

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

func set_closable(value: bool):
	if closable == value:
		return
	closable = value
	get_close_button().visible = closable
	popup_exclusive = !closable

# Creates and displays new dialog using [options], yields the ACTION_OCCURRED signal, and returns the occurred action.
static func create_and_yield_option(options: Dictionary) -> Action:
	var dialog: CustomDialog = load(Utils.utils_path.plus_file("Nodes/CustomDialog.gd")).new()
	Utils.get_canvaslayer().add_child(dialog)
	
	
	# Fill missing options with the default values
	for option in DEFAULT_OPTIONS:
		if not option in options:
			options[option] = DEFAULT_OPTIONS[option]
	
	# - Apply options -
	dialog.add_buttons(options["buttons"])
	
	dialog.window_title = options["title"]
	dialog.label.text = options["body"]
	dialog.closable = options["closable"]
	dialog.resizable = options["resizable"]
	
	var was_paused: bool
	if options["pause"]:
		dialog.pause_mode = Node.PAUSE_MODE_PROCESS
		was_paused = dialog.get_tree().paused
		dialog.get_tree().paused = true
	
	# - - - - - - - - -
	
	dialog.popup_centered()
	var action: CustomDialog.Action = yield(dialog, "ACTION_OCCURRED")
	dialog.queue_free()
	
	if options["pause"]:
		dialog.get_tree().paused = was_paused
	
	return action

func _on_button_pressed(button_id: String):
	if not is_responsive():
		return
	
	last_action = Action.new(Action.TYPE.BUTTON, button_id)
	emit_signal("ACTION_OCCURRED", last_action)

func _on_hide():
	if not is_responsive():
		return
	last_action = Action.new(Action.TYPE.CLOSE)
	emit_signal("ACTION_OCCURRED", last_action)

func get_last_action() -> Action:
	return last_action

func is_responsive() -> bool:
	return visible and is_instance_valid(Game) and not Game.quitting and not freed
