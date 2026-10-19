extends RefCounted
class_name EnemySight

const SPRITE_HALF := Vector2(55.5, 45.5)
const TURN_MIN := 2.5
const TURN_MAX := 4.0
const NOTICE_TIME := 0.4


static func random_facing() -> bool:
	return randf() < 0.5


static func random_turn_wait() -> float:
	return randf_range(TURN_MIN, TURN_MAX)


static func facing_player(sprite: AnimatedSprite2D, enemy_x: float, player_x: float) -> bool:
	var dx := player_x - enemy_x
	if absf(dx) <= 8.0:
		return true
	return sprite.flip_h == (dx < 0.0)


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
