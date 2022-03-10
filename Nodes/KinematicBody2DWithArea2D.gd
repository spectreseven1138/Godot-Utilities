extends KinematicBody2D
class_name KinematicBody2DWithArea2D

var area: ExPhysicsBodyArea2D
var added_shapes: Array = []

var rid: RID = get_rid()
var area_rid: RID

var area_disabled: bool = false setget set_area_disabled

func _ready():
	var _area: Area2D = Area2D.new()
	_area.set_script(ExPhysicsBodyArea2D)
	area = _area
	add_child(area)
	area.visible = false
	area_rid = area.get_rid()

func _process(delta: float):
	if area_disabled:
		return
	
	var found: Array = []
	for shape_idx in Physics2DServer.body_get_shape_count(rid):
		var shape: RID = Physics2DServer.body_get_shape(rid, shape_idx)
		found.append(shape)
		if shape in added_shapes:
			continue
		Physics2DServer.area_add_shape(area.get_rid(), shape, Physics2DServer.body_get_shape_transform(rid, shape_idx))
		added_shapes.append(shape)
	
	for shape_idx in Physics2DServer.area_get_shape_count(area_rid):
		var shape: RID = Physics2DServer.area_get_shape(area_rid, shape_idx)
		if not shape in found:
			Physics2DServer.area_remove_shape(area_rid, shape_idx)
			added_shapes.erase(shape)

func set_area_disabled(value: bool):
	area_disabled = value
	area.monitoring = area_disabled
	area.monitorable = area_disabled
	
	if area_disabled:
		Physics2DServer.area_clear_shapes(area_rid)
