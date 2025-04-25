extends Node

@export var scenes := {
	0 : "Jovin",
	1 : "Champignon"
}

var in_scene = [] # tableau de get Node path, qui represente les objet 3D dans la scène 

var buttonDelete : OptionButton

@onready var _scene = get_node("/root/Main/Scene/Scene") # scene principal, ce que l'on voie sur les tilt fives

func _ready():
	var buttonNew = get_node("./Control/OptionButton") # les bouton deroulant du menu
	buttonDelete = get_node("./Control/OptionButton2") # les bouton deroulant du menu
	buttonNew.item_selected.connect(_on_pressed_new)
	buttonDelete.item_selected.connect(_on_pressed_delete)

func _on_pressed_new(number : int) -> void:
	var nodePacked = load("res://material/"+scenes[number]+"/"+scenes[number]+".tscn") #charger une scène qui n'est pas deja dans la scène 
	var node = nodePacked.instantiate()
	_scene.add_child(node);
	in_scene.append(node.get_path()) #ajouter a la liste des modèle 3D dans la scène 
	maj_button_Delete()

func _on_pressed_delete(number : int) -> void:
	var item = get_node(in_scene[number])
	_scene.remove_child(item)
	item.queue_free() #mettre en queue pour supression, pas suprimmée instantanément
	var tmp = in_scene#           \
	in_scene = [] #               |
	for n in range(len(tmp)-1): # } retirer de la liste des modèle 3D dans la scène 
		if( n != number):  #      |
			in_scene.append(tmp[n])#/
	maj_button_Delete()

func maj_button_Delete() -> void:
	buttonDelete.clear()
	for n in range(len(in_scene)):
		buttonDelete.add_item(in_scene[n].get_name(in_scene[n].get_name_count()-1),n)#recupère le dernier 
		# élément du chemin du node pour l'afficher dans la liste des "à suprimmer"
