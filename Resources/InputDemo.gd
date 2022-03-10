tool
extends Resource
class_name InputDemo

export var input_data: Array
export var ignored_actions: PoolStringArray
export var recording_framerate: int = null setget set_recording_framerate, get_recording_framerate
export var metadata: Dictionary = {}

var unpacked_data: Array = null

func resave():
#	var data: Array = input_data.duplicate(true)
#	input_data.clear()
#
#	var same: int = 0
#	for i in len(data):
#
#		if i > 0 and are_action_sets_equal(data[i], data[i - 1]):
#			same += 1
#		else:
#			if same > 0:
#				input_data.append(same)
#				same = 0
#			input_data.append(data[i])
#
#	if same > 0:
#		input_data.append(same)
#
#	ResourceSaver.save(resource_path, self)
	return

# Append current inputs to input_data
func record_inputs():
	
	if unpacked_data == null:
		unpacked_data = []
	recording_framerate = Engine.iterations_per_second
	
	var pressed_actions: Array
	for action in InputMap.get_actions():
		if action in ignored_actions:
			continue
		if Input.is_action_pressed(action):
			pressed_actions.append(action)
	
	unpacked_data.append(pressed_actions)
	
	if not input_data.empty():
		if input_data[-1] is int:
			if are_action_sets_equal(input_data[-2], pressed_actions):
				input_data[-1] += 1
				return
		elif are_action_sets_equal(input_data[-1], pressed_actions):
			input_data.append(1)
			return
	
	input_data.append(pressed_actions)

func has_frame(frame: int) -> bool:
	return frame >= 0 and frame < get_frame_count()

func is_action_pressed_on_frame(action: String, frame: int) -> bool:
	unpack_data()
	return has_frame(frame) and action in unpacked_data[frame]

func get_frame_count() -> int:
	unpack_data()
	return unpacked_data.size()

func add_ignored_action(action: String):
	if not is_action_ignored(action):
		ignored_actions.append(action)

func remove_ignored_action(action: String):
	var i: int = 0
	for item in ignored_actions:
		if item == action:
			ignored_actions.remove(i)
			break
		i += 1

func is_action_ignored(action: String):
	return action in ignored_actions

func set_recording_framerate(value: int = null):
	recording_framerate = value
	
	if recording_framerate != Engine.iterations_per_second:
		push_warning("InputDemo framerate doesn't match engine framerate")

func get_recording_framerate() -> int:
	if recording_framerate == 0:
		recording_framerate = Engine.iterations_per_second
	return recording_framerate

func are_action_sets_equal(a: Array, b: Array) -> bool:
	
	if a.size() != b.size():
		return false
	
	for action in a:
		if not action in b:
			return false
	
	for action in b:
		if not action in a:
			return false
	
	return true

func unpack_data():
	
	if unpacked_data != null:
		return
	
	unpacked_data = []
	
	var current: Array = null
	for item in input_data:
		if item is int:
			assert(current != null and item > 0)
			for _i in item:
				unpacked_data.append(current)
		else:
			unpacked_data.append(item)
			current = item
