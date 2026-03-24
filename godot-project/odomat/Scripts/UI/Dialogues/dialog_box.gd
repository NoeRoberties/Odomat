extends CanvasLayer

@export var _dialogues: Array[String]
@export var _speaker: String

var _current_replica: String = ""
var _dialogues_index: int = 0
var _replica_length: int = 0

func _ready() -> void:
	%Speaker.text = _speaker
	%Dialogue.text = ""
	_current_replica = _dialogues[_dialogues_index]
	%SpeakTimer.start()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		_continue_dialogue()


func _continue_dialogue() -> void:
	if _replica_length != _current_replica.length():
		_replica_length = _current_replica.length()
		return
	%ContinueIndicator.stop_blinking()
	_dialogues_index += 1
	if _dialogues_index > _dialogues.size() - 1:
		self.queue_free()
		return
	_current_replica = _dialogues[_dialogues_index]
	_replica_length = 0
	%SpeakTimer.start()


func _on_speak_timer_timeout() -> void:
	_replica_length += 3
	if _replica_length >= _current_replica.length():
		_replica_length = _current_replica.length()
		%SpeakTimer.stop()
		%ContinueIndicator.start_blinking()
	%Dialogue.text = _current_replica.substr(0, _replica_length)
