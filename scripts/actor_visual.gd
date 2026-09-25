class_name ActorVisual
extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: Polygon2D = $Shadow
@onready var carry: CanvasItem = get_node_or_null("Carry") as CanvasItem

var last_direction := Vector2(0, 1)
var current_action := "idle"
var moving := false
var base_sprite_position := Vector2.ZERO
var time := 0.0

func _ready() -> void:
	base_sprite_position = sprite.position
	_play_idle()

func set_motion(value: Vector2) -> void:
	moving = value.length() > 1.0
	if moving:
		last_direction = value.normalized()
		_update_direction_animation()
	else:
		_play_idle()

func set_action(action_name: String) -> void:
	current_action = action_name
	if not moving:
		_play_idle()

func set_carry_visible(value: bool) -> void:
	if carry != null:
		carry.visible = value

func _process(delta: float) -> void:
	time += delta
	sprite.position = base_sprite_position
	sprite.rotation = 0.0
	sprite.scale = Vector2(0.78, 0.78)

	match current_action:
		"take_food":
			sprite.rotation = sin(time * 12.0) * 0.045
		"eat":
			sprite.scale = Vector2(0.80, 0.64)
			sprite.position.y += 9.0 + sin(time * 7.0) * 1.0
		"collect":
			sprite.rotation = sin(time * 9.0) * 0.05
		"clean":
			sprite.rotation = sin(time * 14.0) * 0.075
		"cook":
			sprite.position.y += sin(time * 11.0) * 1.8
		_:
			if moving:
				sprite.position.y += sin(time * 12.0) * 1.2

func _update_direction_animation() -> void:
	var use_back := last_direction.y < -0.15
	sprite.flip_h = last_direction.x < 0.0
	var animation_name := "walk_back" if use_back else "walk_front"
	if sprite.animation != animation_name:
		sprite.play(animation_name)
	elif not sprite.is_playing():
		sprite.play()

func _play_idle() -> void:
	var use_back := last_direction.y < -0.15
	sprite.flip_h = last_direction.x < 0.0
	var animation_name := "idle_back" if use_back else "idle_front"
	if sprite.animation != animation_name or sprite.is_playing():
		sprite.play(animation_name)
		sprite.pause()
		sprite.frame = 0
