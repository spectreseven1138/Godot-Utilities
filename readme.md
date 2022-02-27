# **Godot Utilities**

#### A collection of various nodes and functions



### Nodes:

- **NinePatchRectTextureButton**
  - A combination of a NinePatchRect and a TextureButton, with some extra features like text
- **ExArray**
  - A custom array class with a limit property and signals for when items are added or removed
- **ExTexture**
  - A texture class which allows a texture to be scaled



### Functions (contained in Utils.gd):

- `RandomNumberGenerator` **get_RNG** `( )`

  ​	Returns the RNG object (a RandomNumberGenerator created and randomised on init).

- `Node` **get_anchor** `( )`

  ​	Returns the anchor node (an Node added to the Utils singleton on ready).

- `Node` **get_unique_anchor** `( type: Any )` *<- type must be a GDScript or GDScriptNativeClass*

  ​	Creates a new node using [type], adds it to the anchor node, and returns it.

- `void` **sprint** `( items: Array, divider: String = " | ", tprint: bool = false )`

  ​	Prints [items] in a single line with dividers. If [tprint] is true, prints using the tprint function.
  
  ​ Example: `sprint(["one", 2, "three"])` **->** one | 2 | three
 
- `void` **tprint** `( msg: Any )`

  ​	Prints [msg] prepended with the current engine time (OS.get_ticks_msec()). Useful for printing every frame.

- `Any` **random_array_item** `( array: Array, rng: RandomNumberGenerator = get_RNG() )`

  ​	Returns a random item from [array] using [rng].

- `Color` **random_colour** `( r: float = NAN, g: float = NAN, b: float = NAN, a: float = NAN, rng: RandomNumberGenerator = get_rng() )`

  ​	Returns a random colour. Individual values can be overridden using [r], [g], [b], and [a].

- `void` **reparent_node** `( node: Node, new_parent: Node, retain_global_position: bool = false )`

  ​	Removes [node] from its parent, then adds it to  [new_parent]. If [retain_global_position] is true, the global_position of [node] will be maintained.

- `Vector2` **to_local** `( position_of: Node, relative_to: Node )`

  ​	Returns the position of [position_of] relative to [relative_to]. Equivalent to Node2D.to_local(), but also works for Control and Spatial nodes.

- `Vector2` **get_node_position** `( node: Node, global: bool = false )`

  ​ Returns the local or [global] position of [node]. [node] must be a Node2D, Control, or Spatial.

- `void` **set_node_position** `( node: Node, global: bool = false )`

  ​ Sets the local or [global] position of the [node]. [node] must be a Node2D, Control, or Spatial.

- `Color` **get_global_modulate** `( node: CanvasItem )`

  ​ Returns the global modulation of [node] (the product of the modulations of the node and all its ancestors). In other words, returns the actual modulation applied to the node when rendered.

- `void` **append_dictionary** `( base: Dictionary, append: Dictionary, duplicate_values: bool = false )`

  ​	Appends [append] onto [base] (values will be overwritten). If [duplicate_values] is true, values that are an array or dictionary will be duplicated.

- `String` **bbcode_colour_text** `( text: String, colour: Color )`

  ​ Returns [text] as a BBCode formatted string with the passed [colour].

- `int` **get_line_of_position** `( string: String, position: int )`

  ​	Returns the line number of [position] within [string].

- `int` **get_position_of_line** `( string: String, line: int )`

  ​	Returns the position of [line] within [string].

- `Array or int (error)` **get_dir_items** `( directory: String (path) or Directory, skip_navigational: bool = true, skip_hidden: bool = true )`

  ​	Returns the items contained in [directory] as an array. May return an int error.

