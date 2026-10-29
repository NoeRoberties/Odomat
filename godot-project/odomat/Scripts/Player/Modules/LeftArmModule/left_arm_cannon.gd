class_name LeftArmCannonModule
extends Module

const PROJECTILE_SCRIPT := preload("res://Scripts/Player/Modules/LeftArmModule/cannon_projectile.gd")

const TAP_THRESHOLD: float = 0.2
const MAX_CHARGE_TIME: float = 1.5
const SMALL_COOLDOWN: float = 0.15
const MAX_COOLDOWN: float = 1.2
const SMALL_SIZE: float = 0.5
const MAX_SIZE: float = 3.0
const SMALL_RECOIL: float = 60.0
const MAX_RECOIL: float = 600.0
const SMALL_SPEED: float = 700.0
const MAX_SPEED: float = 500.0

var _cooldown_remaining := 0.0
var _charging := false
var _charge_time := 0.0
var _fully_charged := false
var _last_move_dir: Vector2 = Vector2.DOWN

@onready var _muzzle: Marker2D = $Muzzle
@onready var _rect: ColorRect = $Rect


func _ready() -> void:
	super._ready()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if not _charging:
		return
	_charge_time = minf(_charge_time + delta, MAX_CHARGE_TIME)
	_rect.scale = Vector2.ONE * (1.0 + (_charge_time / MAX_CHARGE_TIME) * 0.4)
	if _charge_time >= MAX_CHARGE_TIME and not _fully_charged:
		_fully_charged = true
		_animate_blink()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cannon_fire") and _cooldown_remaining <= 0.0:
		_charging = true
		_charge_time = 0.0
		_fully_charged = false
	elif event.is_action_released("cannon_fire") and _charging:
		var player = get_parent()
		if player != null:
			_fire(player, _charge_time)
		_stop_charge()


func _stop_charge() -> void:
	_charging = false
	_charge_time = 0.0
	_rect.scale = Vector2.ONE


func _fire(player: CharacterBody2D, held: float) -> void:
	var r := 0.0 if held < TAP_THRESHOLD else clampf(held / MAX_CHARGE_TIME, 0.0, 1.0)
	var size := lerpf(SMALL_SIZE, MAX_SIZE, r)
	var recoil := lerpf(SMALL_RECOIL, MAX_RECOIL, r)
	var speed := lerpf(SMALL_SPEED, MAX_SPEED, r)
	_cooldown_remaining = lerpf(SMALL_COOLDOWN, MAX_COOLDOWN, r)

	var origin: Vector2 = _muzzle.global_position
	var dir := (player.get_global_mouse_position() - origin).normalized()

	var p := Area2D.new()
	p.set_script(PROJECTILE_SCRIPT)
	p.setup(dir, speed, size)
	player.get_parent().add_child(p)
	p.global_position = origin

	player.velocity -= dir * recoil


func update_animation(move_dir: Vector2) -> void:
	if move_dir == Vector2.ZERO:
		_sprite.stop()
	elif move_dir.x < 0.0:
		_sprite.play("walk_left")
	elif move_dir.x > 0.0:
		_sprite.play("walk_right")
	_last_move_dir = move_dir
