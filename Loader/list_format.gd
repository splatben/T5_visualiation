extends OptionButton

func _ready():
	self.item_selected.connect(_on_format_selected)
	_on_format_selected(0)

func _on_format_selected(index : int):
	GlobalVar.mutex.lock()
	GlobalVar.format = get_item_text(index) 
	GlobalVar.mutex.unlock()
