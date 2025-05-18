extends A.Sub
const IMPLEMENTS = ["I6.SubInterface"]

@export var a := 1.1
@export var c := "Haha"

@export_category("Test2")
@export var e := &"Test2"

func _ready() -> void:
	var r = A.new()
	var script : Script = r.get_script()
	#print("methods: ",script.get_script_method_list())
	#print("properties: ",script.get_script_property_list())
	#print("signals: ",script.get_script_signal_list())
	#print("constants: ",script.get_script_constant_map())

#