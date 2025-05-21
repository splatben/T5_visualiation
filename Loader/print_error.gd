extends RichTextLabel

func _ready():
	var Loader = get_node("../Button/FileDialog")
	Loader.is_loaded.connect(_on_load)
	Loader.load_failed.connect(_print_error)
	Loader.load_ann.connect(_on_load_ann)
	var Saver = get_node("../Button2/FileDialog")
	Saver.is_saved.connect(_on_saved)
	
func _on_load_ann(_ann:Node3D):
	text= "annotation succesfully import"

func _on_load(node:Node):
	text="Import Successfull of "+node.name

func _print_error(err :String):
	text="Import failed : "+err

func _on_saved():
	text="save sucessfull"
