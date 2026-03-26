@tool
class_name ModuleData
extends Resource


## Les quatre emplacements disponibles sur le robot.
enum Slot {
	RIGHT_ARM,
	LEFT_ARM,
	LEGS,
	BRAIN_CHIP,
}

## Nom affiché dans l'interface.
@export var module_name: String = "Module"

## Emplacement sur lequel ce module se monte.
@export var slot: Slot = Slot.RIGHT_ARM

## Description courte affichée dans l'interface.
@export_multiline var description: String = ""

## Icône optionnelle affichée dans l'inventaire.
@export var icon: Texture2D = null

## Champs de stats optionnels conservés pour l'affichage UI.
@export var speed_bonus: float = 0.0
@export var damage_bonus: int = 0
@export var range_bonus: float = 0.0
@export var cooldown_multiplier: float = 1.0
