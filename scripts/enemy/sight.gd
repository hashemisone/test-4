extends RefCounted
class_name EnemySight

const SPRITE_HALF := Vector2(55.5, 45.5)


static func on_screen(sprite: CanvasItem) -> bool:
	if sprite == null or not sprite.is_inside_tree():
		return false
	var viewport := sprite.get_viewport()
	if viewport == null or viewport.get_camera_2d() == null:
		return true
	var xf := sprite.get_global_transform_with_canvas()
	var top_left: Vector2 = xf * -SPRITE_HALF
	var bottom_right: Vector2 = xf * SPRITE_HALF
	var rect := Rect2(top_left, bottom_right - top_left)
	return viewport.get_visible_rect().intersects(rect.abs())
