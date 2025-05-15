extends FileDialog

@onready var _scene = get_node("../../../../Controller")

var _thread:Thread
var mutex := Mutex.new()
var formats := ["None","PNG","JPEG","Lossless WebP","Lossy WebP"]
var format := 0

func _ready():
	self.file_selected.connect(_save)
	get_node('../../ListFormat').item_selected.connect(_on_format_selected)

func _save(path:String):
	if(_thread):
		if(_thread.is_alive()):
			return;
		else:
			_thread.wait_to_finish()
	_thread = Thread.new()
	
	var ext = path.get_extension()
	
	if ext == "glb" or ext == "gltf":
		_thread.start(Callable(self, "_save_gltf_with_annotation").bind(_scene.duplicate(7),path))

func _save_gltf_with_annotation(scene : Node3D, path : String):
	var gltf_doc = GLTFDocument.new() 
	var gltf_state := GLTFState.new()
	var com = []
	var file = FileAccess.open(path.get_slice(".",0)+".dat",FileAccess.WRITE)
	mutex.lock()
	gltf_doc.image_format = formats[format]
	mutex.unlock()
	for child  in scene.get_children():
		if child.is_in_group("Annotation"):
			var body = child.get_node("StaticBody3D")
			var data = {
			"text":child.get_text().c_escape(),
			"police":child.get_police(),
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
				}
			}
			print(data)
			com.append(data)
			scene.remove_child(child)
	gltf_doc.append_from_scene(scene, gltf_state)
	gltf_doc.write_to_filesystem(gltf_state, path)
	file.store_var(com)
	file.close()

func _on_format_selected(index: int) -> void:
	mutex.lock()
	format = index
	mutex.unlock()
