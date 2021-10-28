tool
class_name ExTexture
extends ImageTexture

"""
A custom Texture which allows the set 'texture' property to be scaled
"""

export var texture: Texture = Texture.new() setget set_texture
export var scale: Vector2 = Vector2.ONE setget set_scale

func update_image():
	if texture == null:
		var empty: Image = Image.new()
		empty.create(1, 1, false, 0)
		create_from_image(empty)
	else:
		create_from_image(process_image(texture.get_data()))

func set_texture(value: Texture):
	texture = value
	if not texture.is_connected("changed", self, "update_image"):
		texture.connect("changed", self, "update_image")
	update_image()

func set_scale(value: Vector2):
	scale = value
	update_image()

func process_image(image: Image) -> Image:
	image.resize(image.get_width() * scale.x, image.get_height() * scale.y, Image.INTERPOLATE_NEAREST)
	return image
