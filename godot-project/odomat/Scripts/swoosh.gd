extends Node2D

## Rayon de l'arc en pixels.
const RADIUS    := 52.0
## Amplitude de l'arc en degrés.
const ARC_DEG   := 155.0
## Nombre de segments de la ligne.
const STEPS     := 14
## Épaisseur max de la ligne.
const LINE_W    := 14.0

## Joue l'animation dans la direction indiquée puis se détruit.
## attack_dir : vecteur normalisé player → cible (ou direction par défaut).
func play(attack_dir: Vector2) -> void:
	var line := Line2D.new()
	line.width = LINE_W

	# Dégradé d'épaisseur : épais à la base, effilé à la pointe.
	var w_curve := Curve.new()
	w_curve.add_point(Vector2(0.0, 1.00))
	w_curve.add_point(Vector2(0.5, 0.55))
	w_curve.add_point(Vector2(1.0, 0.04))
	line.width_curve = w_curve

	# Couleur jaune-blanc légèrement transparente.
	line.default_color = Color(1.0, 0.90, 0.25, 0.92)

	# Construit l'arc de points (plan XY centré sur l'axe X).
	var half := deg_to_rad(ARC_DEG * 0.5)
	for i in range(STEPS + 1):
		var t := float(i) / float(STEPS)
		var a: float = lerp(-half, half, t)
		line.add_point(Vector2(cos(a), sin(a)) * RADIUS)

	# Oriente l'arc vers la cible : face de l'arc = attack_dir.
	rotation = attack_dir.angle()

	add_child(line)

	# Animation : coup de scale rapide puis fondu.
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.06) \
			.set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "modulate:a", 0.0, 0.18) \
			.set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
