extends Reference
class_name ExArray

"""
Custom array class

Features:
	A limit for the amount of contained items can be set
	If the limit is exceeded, items will be removed from the left (start) by default
	
	Signals emitted when items are added, removed, or trimmed
"""

# Emitted when item(s) are added manually (such as with append())
signal items_added(items)

# Emitted when item(s) are removed manually (such as with erase() or remove())
signal items_removed(items)

# Emitted when item(s) are removed due to the item amount exceeding the limit
signal items_trimmed(items)

var array: Array
var limit: int = -1

# If true, items will be removed from the right (end) of the array when the limit is exceeded
var limit_remove_from_right: bool = true

func _init(_array: Array = [], _limit: int = INF):
	array = _array
	limit = abs(_limit)
	_enforce_limit()

# Returns true if the array has a limit
func has_limit() -> bool:
	return limit >= 0

# Appends the array with an item up to its the limit. If [to_left] is true, the items are instead added to the left.
func fill_to_limit(with, to_left: bool = false):
	
	if not has_limit() or len(array) >= limit:
		return
	
	if to_left:
		var new: Array = []
		for i in limit - len(array):
			new.append(with)
		new.append_array(array)
		array = new
	else:
		for i in limit - len(array):
			array.append(with)

var _iter_current: int
func _iter_init(arg):
	_iter_current = 0
	return _iter_current < len(array)
func _iter_next(arg):
	_iter_current += 1
	return _iter_current < len(array)
func _iter_get(arg):
	return array[_iter_current]

# Enforces the limit by removing excess items if needed
func _enforce_limit():
	if has_limit() and len(array) > limit:
		var trimmed: Array
		if limit_remove_from_right:
			if not get_signal_connection_list("items_trimmed").empty():
				trimmed = array.slice(limit, len(array) - 1)
			array = array.slice(0, limit - 1)
		else:
			if not get_signal_connection_list("items_trimmed").empty():
				trimmed = array.slice(0, len(array) - limit - 1)
			array = array.slice(len(array) - limit, len(array) - 1)
		
		if not trimmed.empty():
			emit_signal("items_trimmed", trimmed)

func append(item):
	array.append(item)
	_enforce_limit()
	emit_signal("items_added", [item])

func append_array(array: Array):
	array.append_array(array)
	_enforce_limit()
	emit_signal("items_added", array)

func erase(item):
	array.erase(item)
	emit_signal("items_removed", [item])

func remove(index: int):
	var item = array[index]
	array.remove(index)
	emit_signal("items_removed", [item])

func find(item, from: int = 0) -> int:
	return array.find(item, from)

func empty() -> bool:
	return array.empty()

func pop_back():
	var ret = array.pop_back()
	if ret != null:
		emit_signal("items_removed", [ret])
	return ret

func pop_front():
	var ret = array.pop_front()
	if ret != null:
		emit_signal("items_removed", [ret])
	return ret

func size() -> int:
	return array.size()
