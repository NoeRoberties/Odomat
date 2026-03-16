extends Polygon2D

func _ready() -> void:
	self.hide()


func start_blinking() -> void:
	self.show()
	$BlinkTimer.start()


func stop_blinking() -> void:
	self.hide()
	$BlinkTimer.stop()


func _on_blink_timer_timeout() -> void:
	self.visible = !self.visible
