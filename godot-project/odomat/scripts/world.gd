extends Node2D

const TILE_SCENE := preload("res://scenes/IsoTile.tscn")

const TILE_W: int = 64
const TILE_H: int = 32

const GRID_W: int = 20
const GRID_H: int = 20

const COLOR_LIGHT: Color = Color(0.22, 0.48, 0.22)
const COLOR_DARK:  Color = Color(0.15, 0.38, 0.15)

@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	_build_grid()
	player.position = cart_to_iso(Vector2(GRID_W / 2.0, GRID_H / 2.0))

func _build_grid() -> void:
	for y in range(GRID_H, 0, -1):
		for x in range(GRID_W, 0, -1):
			var tile: Node2D = TILE_SCENE.instantiate()
			tile.position = cart_to_iso(Vector2(x, y))
			tile.base_color = (COLOR_LIGHT if (x + y) % 2 == 0 else COLOR_DARK)
			tile.base_color.r = tile.base_color.r + 0.01 * (y + x)
			tile.base_color.g = tile.base_color.g + 0.01 * (y + x)
			tile.base_color.b = tile.base_color.b + 0.01 * (y + x)
			tile.z_index = -1
			add_child(tile)

func cart_to_iso(cart: Vector2) -> Vector2:
	return Vector2(
		(cart.x - cart.y) * (TILE_W / 2.0),
		(cart.x + cart.y) * (TILE_H / 2.0)
	)
