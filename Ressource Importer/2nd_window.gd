extends Window

func _ready():
	self.show()
	self.close_requested.connect(_on_window_close_requested)

func _on_window_close_requested() -> void:
	self.hide()
	get_tree().quit() # fermer l'aplication
