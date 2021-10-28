# **Godot Utilities**

#### A collection of various nodes and functions



### Nodes:

- NinePatchRectTextureButton
  - A combination of a NinePatchRect and a TextureButton, with some extra features like text
- ExArray
  - A custom array class with a limit property and signals for when items are added or removed
- ExTexture
  - A texture class which allows a texture to be scaled



### Functions (contained in Utils.gd):

- random_array_item

  ​	Returns a random item from the passed array.

- random_colour

  ​	Returns a random colour. Individual RBGA values can be overridden if needed.

- reparent_node

  ​	Removes the passed child node from its parent, then makes it a child of the passed parent node. If 'retain_global_position' is true, the global_position of the child node will be maintained.

- to_local

  ​	Equivalent to Node2D.to_local(), but also works for Control nodes.

- get_node_position / set_node_position

  ​	Gets / sets the (global) position of the passed node. The node must be either a Node2D or Control.

  
