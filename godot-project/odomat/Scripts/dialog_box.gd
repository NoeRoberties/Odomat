extends Control

@export var dialogues: Array[String] = [
	"This is a very long text just to see if the text is printing just as I wish. There is nothing very interesting to see here so please continue your way.",
	"And this is another replica, just to see if we are able to make different dialogues that follow each other."
]
@export var speaker: String = "John Doe"

var current_replica: String = ""
var dialogues_index: int = 0
var replica_length: int = 0

func _ready() -> void:
	%Speaker.text = speaker
	%Dialogue.text = ""
	current_replica = dialogues[dialogues_index]
	%SpeakTimer.start()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		continue_dialogue()

func continue_dialogue() -> void:
	if replica_length != current_replica.length():
		replica_length = current_replica.length()
		return
	%ContinueIndicator.stop_blinking()
	dialogues_index += 1
	if dialogues_index > dialogues.size() - 1:
		self.queue_free()
		return
	current_replica = dialogues[dialogues_index]
	replica_length = 0
	%SpeakTimer.start()


func _on_speak_timer_timeout() -> void:
	replica_length += 3
	if replica_length >= current_replica.length():
		replica_length = current_replica.length()
		%SpeakTimer.stop()
		%ContinueIndicator.start_blinking()
	%Dialogue.text = current_replica.substr(0, replica_length)
