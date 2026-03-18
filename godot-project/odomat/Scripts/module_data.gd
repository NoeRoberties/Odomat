## Représente un module que le robot peut équiper sur l'un de ses emplacements.
## Crée des instances de cette ressource via l'éditeur Godot :
##   Clic droit dans FileSystem → New Resource → ModuleData
@tool
class_name ModuleData
extends Resource


## Les quatre emplacements disponibles sur le robot.
enum Slot {
	RIGHT_ARM,   ## Bras droit
	LEFT_ARM,    ## Bras gauche
	LEGS,        ## Jambes (les deux d'un coup)
	BRAIN_CHIP,  ## Puce cérébrale
}

## Nom affiché dans l'interface.
@export var module_name: String = "Module"

## Emplacement sur lequel ce module se monte.
@export var slot: Slot = Slot.RIGHT_ARM

## Description courte affichée dans l'interface.
@export_multiline var description: String = ""

## Icône optionnelle affichée dans l'inventaire.
@export var icon: Texture2D = null

# ── Modificateurs de statistiques ────────────────────────────────────────────

## Bonus de vitesse de déplacement (pixels/seconde, peut être négatif).
@export var speed_bonus: float = 0.0

## Bonus de dégâts par attaque (peut être négatif).
@export var damage_bonus: int = 0

## Bonus de portée d'attaque en pixels (peut être négatif).
@export var range_bonus: float = 0.0

## Multiplicateur appliqué au cooldown d'attaque.
## < 1.0 → attaque plus vite | > 1.0 → attaque plus lentement.
@export var cooldown_multiplier: float = 1.0
