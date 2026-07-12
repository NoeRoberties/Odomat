extends Node2D

enum Judgement { PERFECT, GOOD, MISS }

const DIRECTIONS = ["up", "down", "left", "right"]
const ARROW_ROTATIONS = { "up": -90.0, "down": 90.0, "left": 180.0, "right": 0.0 }
const INPUT_MAP = { "ui_up": "up", "ui_down": "down", "ui_left": "left", "ui_right": "right" }

# --- Réglages rythme (calés sur alwin-brauns-bumbumchack.wav) ---
@export var bpm: float = 123.0
@export var lead_in: float = 2.32          # 1er temps fort du morceau (à affiner à l'oreille)
@export var beats_per_arrow: int = 2       # une flèche tous les N temps
@export var precharge_beats: float = 0.5   # la rune "charge" X temps avant le beat cible

# --- Fenêtres de timing (en secondes autour du beat) ---
@export var perfect_window: float = 0.10
@export var good_window: float = 0.25

# --- Textures ---
@export var tex_dim: Texture2D
@export var tex_lit: Texture2D

@onready var arrow: Sprite2D = $Arrow
@onready var cave_wall: Sprite2D = $CaveWall
@onready var music: AudioStreamPlayer = $Music
@onready var status_label: Label = $UI/StatusLabel
@onready var score_label: Label = $UI/ScoreLabel

var beat_duration: float = 0.5
var song_started: bool = false
var song_time: float = 0.0

var current_arrow_dir: String = ""
var current_arrow_beat: int = -1
var arrow_resolved: bool = true
var last_spawned_beat: int = -1

var score: int = 0
var combo: int = 0

func _ready() -> void:
	beat_duration = 60.0 / bpm
	_center_visuals()
	get_viewport().size_changed.connect(_center_visuals)
	arrow.visible = false
	if tex_dim:
		arrow.texture = tex_dim
	status_label.text = "ESPACE pour commencer"
	score_label.text = ""

func _center_visuals() -> void:
	var center := Vector2(get_viewport_rect().size) * 0.5
	arrow.position = center
	if cave_wall:
		cave_wall.position = center

func _unhandled_input(event: InputEvent) -> void:
	if not song_started and event.is_action_pressed("ui_accept"):
		_start_song()
		return
	if song_started and not arrow_resolved:
		for action in INPUT_MAP:
			if event.is_action_pressed(action):
				_judge_input(INPUT_MAP[action])
				return

func _start_song() -> void:
	song_started = true
	score = 0
	combo = 0
	last_spawned_beat = -1
	arrow_resolved = true
	score_label.text = "Score : 0"
	status_label.text = ""
	music.play()

func _process(_delta: float) -> void:
	if not song_started:
		return

	song_time = music.get_playback_position() - lead_in
	if song_time < 0.0:
		return

	var current_beat := int(floor(song_time / beat_duration))

	var next_active := last_spawned_beat + 1
	while next_active % beats_per_arrow != 0:
		next_active += 1

	var precharge_time := precharge_beats * beat_duration
	var next_active_time := next_active * beat_duration
	if song_time >= next_active_time - precharge_time and next_active > last_spawned_beat:
		_spawn_arrow(next_active)
		last_spawned_beat = next_active

	if not arrow_resolved:
		var target_time := current_arrow_beat * beat_duration
		if song_time >= target_time:
			arrow.texture = tex_lit if tex_lit else arrow.texture
			if song_time > target_time + good_window:
				_register(Judgement.MISS)

func _spawn_arrow(beat_index: int) -> void:
	current_arrow_dir = DIRECTIONS[randi() % DIRECTIONS.size()]
	current_arrow_beat = beat_index
	arrow_resolved = false
	arrow.rotation_degrees = ARROW_ROTATIONS[current_arrow_dir]
	arrow.texture = tex_dim if tex_dim else arrow.texture
	arrow.visible = true

func _judge_input(dir: String) -> void:
	if dir != current_arrow_dir:
		_register(Judgement.MISS)
		return
	var target_time := current_arrow_beat * beat_duration
	var offset: float = abs(song_time - target_time)
	if offset <= perfect_window:
		_register(Judgement.PERFECT)
	elif offset <= good_window:
		_register(Judgement.GOOD)
	else:
		_register(Judgement.MISS)

func _register(judgement: int) -> void:
	arrow_resolved = true
	match judgement:
		Judgement.PERFECT:
			score += 100
			combo += 1
			status_label.text = "PARFAIT !"
		Judgement.GOOD:
			score += 50
			combo += 1
			status_label.text = "Bien"
		Judgement.MISS:
			combo = 0
			status_label.text = "Raté"
	score_label.text = "Score : %d   Combo : %d" % [score, combo]
	_fade_arrow()

func _fade_arrow() -> void:
	await get_tree().create_timer(0.15).timeout
	if arrow_resolved:
		arrow.visible = false
