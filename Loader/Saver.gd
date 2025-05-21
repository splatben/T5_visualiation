extends FileDialog

signal is_saved()

@onready var _scene = get_node("../../../../Controller")
var _thread:Thread

func _ready():
	self.file_selected.connect(_save)

func _save(path:String):
	if(_thread):
		if(_thread.is_alive()):
			return;
		else:
			_thread.wait_to_finish()
	_thread = Thread.new()
	_thread.start(Callable(self, "_save_annotation").bind(_scene.duplicate(6),path))

func _save_annotation(scene : Node3D, path : String):
	var nodes = []
	var file = FileAccess.open(path,FileAccess.WRITE)
	
	for node  in scene.get_children():
		var body = node.get_child(0)
		var data_node = {
		"file": node.get_meta("file",""),
			"position":
				{
					"x":body.get_position().x,
					"y":body.get_position().y,
					"z":body.get_position().z
				},
			"taille":
				{
					"x":body.get_scale().x,
					"y":body.get_scale().y,
					"z":body.get_scale().z
				},
			"rotation":
				{
					"x":body.get_rotation().x,
					"y":body.get_rotation().y,
					"z":body.get_rotation().z
				},
			"annotations":[]
			}
		for child in body.get_children():
			if child.is_in_group("Annotation"):
				var body2 = child.get_child(0)
				print(body2.get_position())
				var data_ann = {
				"text":child.get_text(),
				"police":child.get_police(),
				"position":
					{
						"x":body2.get_position().x,
						"y":body2.get_position().y,
						"z":body2.get_position().z
					},
				"taille":
					{
						"x":body2.get_scale().x,
						"y":body2.get_scale().y,
						"z":body2.get_scale().z
					},
				"rotation":
					{
						"x":body2.get_rotation().x,
						"y":body2.get_rotation().y,
						"z":body2.get_rotation().z
					}
				}
				data_node["annotations"].append(data_ann)
		nodes.append(data_node)
	file.store_var(nodes)
	file.close()
	is_saved.emit.call_deferred()
