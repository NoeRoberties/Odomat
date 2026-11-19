class_name EnemyHealthBar
extends TextureProgressBar

func setMaxHP(max_hp: float) -> void:
	max_value = max_hp
	value = max_hp

func update_health(current_hp: float) -> void:
	value = current_hp
