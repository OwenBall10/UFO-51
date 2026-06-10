extends CanvasLayer

@onready var display = $ColorRect/RichTextLabel
var pending_messages: String = ""

func _ready() -> void:
	display.text = "--- GAME STARTED ---\n"
	if pending_messages != "":
		display.text += pending_messages

func log_msg(message: String) -> void:
	print(message) 
	
	if display != null:
		display.text += message + "\n"
	else:
		pending_messages += message + "\n"
