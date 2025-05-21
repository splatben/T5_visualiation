extends Control

var _connected_comment = null

func _ready():
	$TextEdit.text_changed.connect(_on_text_changed)
	$PoliceEdit.text_changed.connect(_on_police_changed)

func _on_edit(node:Node):
	if not(node.is_in_group("Annotation")):
		return;
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
