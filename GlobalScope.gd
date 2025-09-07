extends Node

var format:String = "PNG"
var mutex := Mutex.new()
var sceneT5 :Node3D = null

@warning_ignore("unused_signal")
signal glasses_connected()
@warning_ignore("unused_signal")
signal new_comment(com:Node3D)#pour faire passer a plusieur node l'information qu'il y a une nouvel annotation
@warning_ignore("unused_signal")
signal comment_delete(com :Node3D)
