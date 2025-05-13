extends Button

@onready var popup = $FileDialog

func _on_button_pressed() -> void:
	popup.show()

func _on_file_dialog_canceled() -> void:
	popup.hide()
