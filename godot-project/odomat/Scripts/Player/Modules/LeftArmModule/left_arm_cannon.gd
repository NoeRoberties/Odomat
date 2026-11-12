class_name LeftArmCannonModule
extends Module

const BULLET_SCENE: PackedScene = preload("res://Scenes/Player/WeaponEffects/Bullet.tscn")

const TAP_THRESHOLD: float = 0.2
const MAX_CHARGE_TIME: float = 1.5
const SMALL_COOLDOWN: float = 0.15
const MAX_COOLDOWN: float = 1.2
const SMALL_SIZE: float = 0.5
const MAX_SIZE: float = 3.0
const MAX_RECOIL: float = 800.0
const SMALL_SPEED: float = 700.0
const MAX_SPEED: float = 500.0
const FULL_CHARGE_BLINK_COLOR := Color(0.7, 0.3, 1.0)

var _cooldown_remaining := 0.0
var _charging := false
var _charge_time := 0.0
var _fully_charged := false
var _sprite_base_scale: Vector2

@onready var _muzzle: Marker2D = $Muzzle


func _ready() -> void:
	super._ready()
	_sprite_base_scale = _sprite.scale


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if not _charging:
		return
	_charge_time = minf(_charge_time + delta, MAX_CHARGE_TIME)
	_sprite.scale = _sprite_base_scale * (1.0 + (_charge_time / MAX_CHARGE_TIME) * 0.4)
	if _charge_time >= MAX_CHARGE_TIME and not _fully_charged:
		_fully_charged = true
		_blink_full_charged()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cannon_fire") and _cooldown_remaining <= 0.0:
		_charging = true
		_charge_time = 0.0
		_fully_charged = false
	elif event.is_action_released("cannon_fire") and _charging:
		var player := get_parent() as Player
		if player != null:
			_fire(player, _charge_time)
		_stop_charge()


func _stop_charge() -> void:
	_charging = false
	_charge_time = 0.0
	_sprite.scale = _sprite_base_scale


func _blink_full_charged() -> void:
	if _blink_tween:
		_blink_tween.kill()

	_sprite.self_modulate = _original_color

	_blink_tween = create_tween()
	for i in range(4):
		_blink_tween.tween_property(_sprite, "self_modulate", FULL_CHARGE_BLINK_COLOR, 0.08)
		_blink_tween.tween_property(_sprite, "self_modulate", _original_color, 0.08)


func _fire(player: Player, held: float) -> void:
	var r := 0.0 if held < TAP_THRESHOLD else clampf(held / MAX_CHARGE_TIME, 0.0, 1.0)
	var size := lerpf(SMALL_SIZE, MAX_SIZE, r)
	var speed := lerpf(SMALL_SPEED, MAX_SPEED, r)
	_cooldown_remaining = lerpf(SMALL_COOLDOWN, MAX_COOLDOWN, r)

	var origin: Vector2 = _muzzle.global_position
	var dir := (player.get_global_mouse_position() - origin).normalized()

	var bullet := BULLET_SCENE.instantiate()
	bullet.setup(dir, speed, size)
	bullet.global_position = origin
	player.get_parent().add_child(bullet)

	if size > SMALL_SIZE:
		player.apply_knockback(-dir * MAX_RECOIL * r)


func update_animation(move_dir: Vector2) -> void:
	if move_dir == Vector2.ZERO:
		_sprite.stop()
	elif move_dir.x < 0.0:
		_sprite.play("walk_left")
		_face(-1.0)
	elif move_dir.x > 0.0:
		_sprite.play("walk_right")
		_face(1.0)


func _face(side: float) -> void:
	_sprite.flip_h = side > 0.0
	_sprite.position.x = absf(_sprite.position.x) * side
	_muzzle.position.x = absf(_muzzle.position.x) * side
