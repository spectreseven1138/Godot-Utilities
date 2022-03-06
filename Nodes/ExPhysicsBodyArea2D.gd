extends Node2D
class_name ExPhysicsBodyArea2D

var s: Node2D = self

var disabled: bool = false setget set_disabled

var _stored_collision_layer: int = null
var _stored_collision_mask: int = null

func _init():
	assert(s is Area2D or s is PhysicsBody2D, "ExPhysicsBodyArea2D node must inherit Area2D or PhysicsBody2D")

func _set(property: String, value) -> bool:
	
	if disabled:
		if property == "collision_layer":
			_stored_collision_layer = value
			return true
		if property == "collision_mask":
			_stored_collision_mask = value
			return true
	
	return false

func enable():
	if not disabled:
		return
	
	s.set_collision_layer(_stored_collision_layer)
	s.set_collision_mask(_stored_collision_mask)
	
	disabled = false

func disable():
	if disabled:
		return
	
	_stored_collision_layer = s.collision_layer
	_stored_collision_mask = s.collision_mask
	
	s.collision_layer = 0
	s.collision_mask = 0
	
	disabled = true

func set_disabled(value: bool):
	if disabled == value:
		return
	
	if value:
		disable()
	else:
		enable()
