extends OptionButton

var delete_list = []

func _ready():
	var Loader = get_node("../Button/FileDialog")
	Loader.is_loaded.connect(_on_load)
	Loader.load_ann.connect(_on_load)
	self.item_selected.connect(_on_pressed_delete)
	GlobalScope.new_comment.connect(_on_load)
	GlobalScope.comment_delete.connect(_on_delete)

func _on_load(node:Node):
	delete_list.append(node)
	maj_button_Delete()

func maj_button_Delete() -> void:
	self.clear()
	for i in range(len(delete_list)):
		self.add_item(delete_list[i].get_name(),i)

func _on_pressed_delete(number : int) -> void:
	var item = delete_list[number]
	delete_list.remove_at(number)
	for child in item.get_child(0).get_children():
		if(delete_list.has(child)):
			delete_list.remove_at(delete_list.find(child));
	item.get_parent().remove_child(item)
	item.queue_free() #mettre en queue pour supression, pas suprimmée instantanément
	maj_button_Delete()

func _on_delete(com:Node3D):
	var indice : int = -1
	for i in range(delete_list.size()):
		if delete_list[i] == com :
			indice = i
			break
	if indice != -1:
		delete_list.remove_at(indice)
		com.get_parent().remove_child(com)
		com.queue_free()
