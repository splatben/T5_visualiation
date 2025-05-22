extends Node

var _origin : T5Origin3D
var _affichage_zoom : Label

var _enum_to_text:Dictionary ={
	Wand_Control.Wand_button.A:"a",
	Wand_Control.Wand_button.B:"b",
	Wand_Control.Wand_button.Y:"y",
	Wand_Control.Wand_button.X:"x",
	Wand_Control.Wand_button._1:"1",
	Wand_Control.Wand_button._2:"2",
	Wand_Control.Wand_button.STICK:"stick click",
	Wand_Control.Wand_button.MIDDLE:"middle",
	Wand_Control.Wand_button.GACHETTE:"gachette"
}

func _find_origin():
	var parent = get_parent()
	while parent and !_origin:
		if parent is T5Origin3D:
			_origin = parent
			return
		parent = parent.get_parent()

func _ready():
	_find_origin()
	_affichage_zoom = get_node("Label16")
	_origin.ready.connect(_on_parent_ready,4)

func _on_parent_ready():
	var boutton_zoom := get_node("Label10")
	var boutton_dezoom :=  get_node("Label11")
	var boutton_lock :=  get_node("Label12")
	var boutton_annotation :=  get_node("Label9")
	var boutton_annotation_edit :=  get_node("Label8")
	var boutton_reinitialisation :=  get_node("Label7")
	var controller = _origin.get_node("Wand_1/Pointer/Control")
	boutton_zoom.text = _enum_to_text[controller.zoom]
	boutton_dezoom.text = _enum_to_text[controller.dezoom]
	boutton_lock.text = _enum_to_text[controller.lock]
	boutton_reinitialisation.text = _enum_to_text[controller.reinitialisation]
	boutton_annotation.text = _enum_to_text[controller.ajouter_annotation]
	boutton_annotation_edit.text = _enum_to_text[controller.edit_annotation]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_affichage_zoom.text = str(_origin.gameboard_scale)
