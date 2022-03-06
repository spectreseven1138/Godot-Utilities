extends KinematicBody2D
class_name KinematicBody2DWithArea2D

var area: ExPhysicsBodyArea2D
var registered_shapes: Dictionary = {}

func _ready():
	var _area: Area2D = Area2D.new()
	_area.set_script(ExPhysicsBodyArea2D)
	
	area = _area
	
	add_child(area)
	area.visible = false
	area.collision_layer = 0
	area.collision_mask = 0

func _process(delta: float):
	
	var not_found: Array = registered_shapes.keys().duplicate()
	
	for owner_id in get_shape_owners():
		var shape: Node2D = shape_owner_get_owner(owner_id)
		
		if owner_id in registered_shapes:
			if shape is CollisionShape2D:
				registered_shapes[owner_id].shape = shape.shape
			else: # CollisionPolygon2D
				registered_shapes[owner_id].polygon = shape.polygon
			
			registered_shapes[owner_id].global_position = shape.global_position
			
		else:
			var new_shape: Node2D = shape.duplicate(DUPLICATE_USE_INSTANCING)
			area.add_child(new_shape)
			registered_shapes[owner_id] = new_shape
		
		not_found.erase(owner_id)
	
	for owner_id in not_found:
		registered_shapes[owner_id].queue_free()
		registered_shapes.erase(owner_id)
		
