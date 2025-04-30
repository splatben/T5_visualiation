extends Node

var in_scene : Array # tableau de get Node path, qui represente les objet 3D dans la scène 

var buttonDelete : OptionButton

@export var path_to_scene := "/root/Main/Scene/Scene"

@onready var _scene = get_node(path_to_scene) # scene principal, ce que l'on voie sur les tilt fives

func _ready():
	var fileDialog = get_node("./Control/Button/FileDialog") # les bouton deroulant du menu
	buttonDelete = get_node("./Control/OptionButton2") # les bouton deroulant du menu
	buttonDelete.item_selected.connect(_on_pressed_delete)
	fileDialog.is_loaded.connect(_on_is_loaded)
	fileDialog.load_failed.connect(_on_fail)

func _on_is_loaded(node:Node):
	_scene.add_child(node);
	in_scene.append(node.get_path())
	maj_button_Delete()

func _on_fail():
	var text = get_node("../../RichTextLabel")
	text.text="import failed"
	

func _on_pressed_delete(number : int) -> void:
	print(number)
	var item = get_node(in_scene[number])
	_scene.remove_child(item)
	item.queue_free() #mettre en queue pour supression, pas suprimmée instantanément
	in_scene.remove_at(number)
	maj_button_Delete()

func maj_button_Delete() -> void:
	buttonDelete.clear()
	for n in range(len(in_scene)):
		buttonDelete.add_item(in_scene[n].get_name(in_scene[n].get_name_count()-1),n)#recupère le dernier 
		# élément du chemin du node pour l'afficher dans la liste des "à suprimmer"
