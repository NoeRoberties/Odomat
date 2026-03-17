extends CharacterBody2D

@export var _dialogues: Array[String]
@export var _sprite_frames: SpriteFrames
@export var _name: String

var _dialogue_box_scene: PackedScene = load("res://Scenes/DialogBox.tscn")

func _ready() -> void:
	%AnimatedSprite2D.sprite_frames = _sprite_frames
	_launch_dialogue()


func _launch_dialogue() -> void:
	var dialogue_box_instance = _dialogue_box_scene.instantiate()
	dialogue_box_instance._dialogues = _dialogues
	dialogue_box_instance._speaker = _name
	get_tree().root.add_child.call_deferred( dialogue_box_instance)
