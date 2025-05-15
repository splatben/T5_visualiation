extends Control

var origin : T5Origin3D
var affichage_zoom : Label

func _find_origin():
	var parent = get_parent()
	while parent and !origin:
		if parent is T5Origin3D:
			origin = parent
			return
		parent = parent.get_parent()

func _ready():
	_find_origin()
	affichage_zoom = get_node("Label16")
	get_node("../../../../../").ready.connect(_on_parent_ready)

func _on_parent_ready():
	var boutton_zoom := get_node("Label10")
	var boutton_dezoom :=  get_node("Label11")
	var boutton_lock :=  get_node("Label12")
	var boutton_annotation :=  get_node("Label9")
	var boutton_annotation_edit :=  get_node("Label8")
	var boutton_reinitialisation :=  get_node("Label7")
	var controller = get_node("../../../../../Wand_1/Pointer/Control")
	boutton_zoom.text = controller.boutton_zoom[-1]
	boutton_dezoom.text = controller.boutton_dezoom[-1]
	boutton_lock.text = controller.boutton_lock[-1]
	boutton_reinitialisation.text = controller.boutton_reinitialisation[-1]
	boutton_annotation.text = controller.boutton_annotation[-1]
	boutton_annotation_edit.text = controller.boutton_annotation_edit[-1]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	affichage_zoom.text = str(origin.gameboard_scale)
