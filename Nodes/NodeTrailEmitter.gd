extends Node2D
class_name NodeTrailEmitter

export var emitting: bool = true
export(Array, NodePath) var nodepaths: Array # Paths automatically added as trail nodes on ready
export var frequency: int = -1 # Target emissions per second (set < 0 for every idle frame)
export var lifetime: float = 0.1 # Lifetime in seconds for emitted trails
export var fade_out_from: float = 0.5 # Emitted trails will begin to fade out after reaching this percentage of their lifetime (set < 0 for no fade)
export var follow_speed: float = 1.0 # The speed at which emitted trails follow the original node 

var nodes_to_trail: Array
var trail_container: Node2D
var fade_tween: Tween
var emission_timer: float = 0.0

func _process(delta: float):
	
	if not emitting:
		emission_timer = 0.0
		return
	
	if frequency < 0:
		emit_trails()
	else:
		emission_timer += delta
		if emission_timer >= 1.0 / frequency:
			emit_trails()
			emission_timer = 0.0

func _physics_process(delta: float):
	if follow_speed > 0.0:
		for trail_node in trail_container.get_children():
			trail_node.global_position = lerp(trail_node.global_position, trail_node.get_meta("following_node").global_position, delta * follow_speed)

func _ready():
	
	trail_container = Node2D.new()
	add_child(trail_container)
	
	fade_tween = Tween.new()
	add_child(fade_tween)
	
	set_as_toplevel(true)
	for path in nodepaths:
		if has_node(path):
			assert(get_node(path) is Node2D)
			add_trail_node(get_node(path))

# Returns true if emitting trail for [node]
func has_trail_node(node: Node) -> bool:
	return node in nodes_to_trail

# Starts emitting trail for [node]
func add_trail_node(node: Node):
	assert(!has_trail_node(node))
	nodes_to_trail.append(node)

# Stops emitting trail for [node]
func remove_trail_node(node: Node):
	assert(has_trail_node(node))
	nodes_to_trail.erase(node)

# Clears existing trails
func clear_trails():
	for trail_node in trail_container.get_children():
		trail_node.queue_free()

# Emit trail once for each node
func emit_trails():
	
	var added: Array = []
	for node in nodes_to_trail:
		if not node.visible:
			continue
		
		var trail_node: Node2D = node.duplicate()
		trail_node.set_meta("following_node", node)
		trail_container.add_child(trail_node)
		trail_node.global_position = node.global_position
		
		get_tree().create_timer(lifetime).connect("timeout", trail_node, "queue_free")
		
		added.append(trail_node)
	
	if fade_out_from >= 0.0 and not added.empty():
		if fade_out_from > 0.0:
			yield(get_tree().create_timer(lifetime * fade_out_from), "timeout")
		
		for node in added:
			fade_tween.interpolate_property(node, "modulate:a", node.modulate.a, 0.0, lifetime * (1.0 - fade_out_from))
		fade_tween.start()
