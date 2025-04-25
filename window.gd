extends Window

func _ready():
	self.show()

func _on_window_close_requested() -> void:
	self.hide()
	get_tree().quit() # fermer l'aplication
