tool
extends PolyCollisionShape2D
class_name TileMapPolyCollisionShape2D

export var tilemap_path: NodePath
export var tiles_to_use: PoolIntArray = PoolIntArray()
export var invert: bool = false
export var inverted_border_size: float = 5.0
export var generate_collisionshapes_now: bool = false setget set_polygon_now

const NEIGHBOUR_CELLS: Array = [
	Vector2(-1, 0), # Left
	Vector2(0, -1), # Top
	Vector2(1, 0), # Right
	Vector2(0, 1) # Bottom
]

func set_polygon_now(value: bool):
	if not value:
		return
	
	if not has_node(tilemap_path):
		Utils.printc("Tilemap path must be set", Color.red)
		return
	elif not get_node(tilemap_path) is TileMap:
		Utils.printc("Tilemap path must refer to a TileMap", Color.red)
		return
	
	for node in get_children():
		node.queue_free()
		yield(node, "tree_exited")
	
	var start: int = OS.get_ticks_usec()
	var base: PolyNode2D = null
	for polygon in generate_polygons(get_node(tilemap_path), tiles_to_use, invert, inverted_border_size):
		var polynode: PolyNode2D = PolyNode2D.new()
		polynode.points = polygon
		polynode.color.a = 0.0
		
		if base == null:
			base = polynode
			polynode.name = "Base" + polynode.get_class()
			polynode.operation = PolyNode2D.OP_NONE
			Utils.tool_add_child(self, polynode)
		else:
			polynode.operation = PolyNode2D.OP_XOR
			Utils.tool_add_child(base, polynode)
	
	Utils.printc("Generated polygon in " + str((OS.get_ticks_usec() - start) / 1000000.0) + " seconds", Color.darkseagreen)

func generate_polygons(tilemap: TileMap, tiles_to_use: PoolIntArray = null, invert: bool = false, inverted_border_size: float = 0.0) -> Array:
	
	var used_cells: PoolVector2Array = tilemap.get_used_cells()
	var used_rect: Rect2 = tilemap.get_used_rect()
	var cell_size: Vector2 = tilemap.get_cell_size()
	
	var edges: Dictionary = {}
	var next_edges: Dictionary = {}
	for cell_pos in used_cells:
		
		if not (tiles_to_use == null or tiles_to_use.empty() or tilemap.get_cellv(cell_pos) in tiles_to_use):
			continue
		
		var p0: Vector2 = tilemap.map_to_world(cell_pos + Vector2(0, 1)) # Bottom left
		var p1: Vector2 = tilemap.map_to_world(cell_pos + Vector2(0, 0)) # Top left
		var p2: Vector2 = tilemap.map_to_world(cell_pos + Vector2(1, 0)) # Top right
		var p3: Vector2 = tilemap.map_to_world(cell_pos + Vector2(1, 1)) # Bottom right
		
		var cell_edges: Array = [
			[p0, p1], # Left
			[p1, p2], # Top
			[p2, p3], # Right
			[p3, p0]  # Bottom
		]
		
		for edge in 4:
			
			var neighbour_pos: Vector2 = cell_pos + NEIGHBOUR_CELLS[edge]
			var neighbour_tile: int = tilemap.get_cellv(neighbour_pos)
			
			# Neighbour cell blocks this edge, so remove it
			if neighbour_tile != TileMap.INVALID_CELL and (tiles_to_use == null or tiles_to_use.empty() or neighbour_tile in tiles_to_use):
				cell_edges[edge] = null
		
		edges[cell_pos] = cell_edges
	
	for cell_pos in edges:
		for edge in 4:
			
			# No edge here, skip
			if edges[cell_pos] is Vector2 or edges[cell_pos][edge] == null:
				continue
			
			var cell_edge: Array = edges[cell_pos][edge]
			
			if not cell_pos in next_edges:
				next_edges[cell_pos] = {}
			
			# Check for parralel neighbouring edges
			for _a in 1:
				var neighbour_pos: Vector2 = cell_pos + NEIGHBOUR_CELLS[wrapi(edge + 1, 0, 4)]
				if not neighbour_pos in edges:
					break
				
				var neighbour_edge = edges[neighbour_pos][edge]
				if neighbour_edge == null:
					break
				
				var cont: bool = false
				while neighbour_edge is Vector2:
					neighbour_pos = neighbour_edge
					if not neighbour_pos in edges:
						cont = true
						break
					
					neighbour_edge = edges[neighbour_pos][edge]
					if neighbour_edge == null:
						cont = true
				if cont:
					break
				
				assert(neighbour_edge is Array)
				
				if neighbour_edge[0] == cell_edge[1]:
					neighbour_edge[0] = cell_edge[0]
				elif neighbour_edge[1] == cell_edge[0]:
					neighbour_edge[1] = cell_edge[1]
				else:
					break
				
				edges[cell_pos][edge] = neighbour_pos
				next_edges[cell_pos][edge] = [neighbour_pos, edge, "one"]
			
			if edge in next_edges[cell_pos]:
				continue
			
			# Parallel edge wasn't found, so check for orthogonal neighbouring edges
			for set in [[Vector2.ZERO, 1], [NEIGHBOUR_CELLS[wrapi(edge + 1, 0, 4)] + NEIGHBOUR_CELLS[edge], -1]]:
				var neighbour_pos: Vector2 = cell_pos + set[0]
				if not neighbour_pos in edges:
					continue
				
				var neighbour_edge = edges[neighbour_pos][wrapi(edge + set[1], 0, 4)]
				if neighbour_edge == null:
					continue
				
				var cont: bool = false
				while neighbour_edge is Vector2:
					neighbour_pos = neighbour_edge
					if not neighbour_pos in edges:
						cont = true
						continue
					
					neighbour_edge = edges[neighbour_pos][wrapi(edge + set[1], 0, 4)]
					if neighbour_edge == null:
						cont = true
				if cont:
					continue
				
				next_edges[cell_pos][edge] = [neighbour_pos, wrapi(edge + set[1], 0, 4), "two"]
			
			assert(edge in next_edges[cell_pos])
	
	var shape: PoolVector2Array = PoolVector2Array()
	
	var initial: Array = [next_edges.keys()[0], next_edges[next_edges.keys()[0]].keys()[0]]
	var current: Array = initial
	while true:
		
		var edge = edges[current[0]][current[1]]
		assert(edge != null)
		
		while edge is Vector2:
			current = next_edges[current[0]][current[1]]
			edge = edges[current[0]][current[1]]
			assert(edge != null)
		
		shape.append(edge[0])
		shape.append(edge[1])
		
		current = next_edges[current[0]][current[1]]
		
		if current[0] == initial[0] and current[1] == initial[1]:
			break
	
	if invert:
		
		inverted_border_size /= 2.0
		var outer: PoolVector2Array = PoolVector2Array([
			(Vector2(-inverted_border_size, -inverted_border_size) + used_rect.position) * cell_size,
			(Vector2(used_rect.size.x + inverted_border_size, -inverted_border_size) + used_rect.position) * cell_size,
			(Vector2(inverted_border_size, inverted_border_size) + used_rect.size + used_rect.position) * cell_size,
			(Vector2(-inverted_border_size, used_rect.size.y + inverted_border_size) + used_rect.position) * cell_size
		])
		
		return [shape, outer]
	
	else:
		return [shape]

