extends RefCounted
class_name EnemySight

const SPRITE_HALF := Vector2(55.5, 45.5)
const TURN_MIN := 2.5
const TURN_MAX := 4.0
const NOTICE_TIME := 0.4
const LOSE_SIGHT_TIME := 10.0
const HOME_SLACK := 6.0
const STUCK_TIME := 0.3


static func random_facing() -> bool:
	return randf() < 0.5


static func random_turn_wait() -> float:
	return randf_range(TURN_MIN, TURN_MAX)


static func facing_player(sprite: AnimatedSprite2D, enemy_x: float, player_x: float) -> bool:
	var dx := player_x - enemy_x
	if absf(dx) <= 8.0:
		return true
	return sprite.flip_h == (dx < 0.0)


static func decide(sprite: AnimatedSprite2D, enemy_x: float, player: Node2D, delta: float, alert: bool, notice_left: float, lost_left: float) -> Dictionary:
	var visible := on_screen(sprite)
	var player_ok: bool = player != null and player.has_method("is_alive") and player.is_alive()
	var attacking := false
	if not player_ok:
		alert = false
		notice_left = -1.0
		lost_left = -1.0
	elif visible and alert:
		attacking = true
		lost_left = -1.0
	elif visible and facing_player(sprite, enemy_x, player.global_position.x):
		if notice_left < 0.0:
			notice_left = NOTICE_TIME
		else:
			notice_left = maxf(notice_left - delta, 0.0)
		if notice_left <= 0.001:
			alert = true
			attacking = true
			notice_left = -1.0
			lost_left = -1.0
	elif alert:
		if lost_left < 0.0:
			lost_left = LOSE_SIGHT_TIME
		lost_left = maxf(lost_left - delta, 0.0)
		if lost_left <= 0.001:
			alert = false
			lost_left = -1.0
			notice_left = -1.0
		else:
			attacking = true
	else:
		notice_left = -1.0
	return {
		"attacking": attacking,
		"alert": alert,
		"notice_left": notice_left,
		"lost_left": lost_left,
	}


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


static func at_home(body: Node2D, home: Vector2) -> bool:
	return absf(home.x - body.global_position.x) <= HOME_SLACK and absf(home.y - body.global_position.y) < 48.0


static func floor_ahead(body: CharacterBody2D, dir: float) -> bool:
	var world := body.get_world_2d()
	if world == null:
		return true
	var origin := body.global_position
	var from := origin + Vector2(dir * 22.0, -6.0)
	var to := origin + Vector2(dir * 22.0, 22.0)
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = body.collision_mask
	query.exclude = [body.get_rid()]
	return not world.direct_space_state.intersect_ray(query).is_empty()
