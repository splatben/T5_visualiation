extends Window

var _connected_comment :Node = null

func _ready():
	GlobalScope.glasses_connected.connect(_on_glasses_connected)
	self.close_requested.connect(_on_close)
	$TextEdit.text_changed.connect(_on_text_changed)
	$PoliceEdit.text_changed.connect(_on_police_changed)
	self.hide()

func _on_glasses_connected():
	var controller = get_node("/root/Main/TiltFiveGlasses/Player/Origin/Wand_1/Pointer/Control")
	controller.edit.connect(_on_edit)

func _on_edit(node:Node):
	self.hide()
	if not(node.is_in_group("Annotation")):
		return;
	self.show()
	_connected_comment = node
	$TextEdit.text = _connected_comment.get_text()
	$PoliceEdit.text = str(_connected_comment.get_police())

func _on_text_changed():
	if _connected_comment != null:
		_connected_comment.set_text($TextEdit.text)
		_connected_comment.print_text()

func _on_police_changed(text : String):
	if _connected_comment != null:
		if text.is_valid_int():
			_connected_comment.set_police(text.to_int())
			_connected_comment.print_police()
			
func _on_close():
	self.hide()
	_connected_comment = null
