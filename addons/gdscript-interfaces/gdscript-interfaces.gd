@tool
extends EditorPlugin

var curent_script: Script
var interfaces = {}
const GLOBAL_NAME = "InterfacesAutoload"
var GLOBAL : Interfaces

func _enter_tree() -> void:
	GLOBAL = Interfaces.new()
	add_child(GLOBAL)
	var SE = get_editor_interface().get_script_editor()
	SE.editor_script_changed.connect(_on_script_changed)
	SE.script_close.connect(_on_script_close)
	add_autoload_singleton(GLOBAL_NAME,"res://addons/gdscript-interfaces/global.gd")

func _ready() -> void:
	for path in GLOBAL.paths.values():
		load_interface_from_path(path)

func load_interface_from_path(path) -> Error:
#	print("try to load ",path)
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var script = load(path)
	if not script is Script:
		return ERR_INVALID_DATA
	read_script(script)
#	print("loaded interface ",path)
	return OK

func _on_script_changed(p_s:Script):
	if p_s == curent_script:
		return
	read_script(curent_script)
	read_script(p_s)
	curent_script = p_s

func read_script(p_s:Script):
	if not p_s or p_s == get_script():
		return
	print(p_s)
	var inst = null
	if not p_s.reload(true) and p_s.has_method("new"):
		inst = p_s.new()
	if not inst:
		return
	if inst is BasicInterface:
		var interface_global_name = p_s.get_global_name()
		if interface_global_name == "":
			interface_global_name = p_s.resource_path
		var spec = InterfaceSpecification.new()
		for met in p_s.get_script_method_list():
			var n = met["name"]
			met.erase("name")
			spec.methods[n] = met
		for sig in p_s.get_script_signal_list():
			spec.signals.append(sig["name"])
		for prop in p_s.get_script_property_list():
			if prop["name"].ends_with(".gd"):
				continue
			var n = prop["name"]
			prop.erase("name")
			spec.variables[n] = prop
		interfaces[interface_global_name] = spec
		return
	var cons = p_s.get_script_constant_map()
	if "IMPLEMENTS" in cons and not p_s.has_script_signal(Interfaces.NOT_IMPLEMENT):
		var methods = {}
		var variables = {}
		for method in inst.get_method_list():
			methods[method["name"]] = method
		for prop in inst.get_property_list():
			variables[prop["name"]] = prop
		if cons["IMPLEMENTS"] is Array:
			for i_name in cons["IMPLEMENTS"]:
				if i_name is Script:
					if i_name.get_global_name() == "":
						i_name = i_name.resource_path
					else:
						i_name = i_name.get_global_name()
				if not interfaces.has(i_name):
					if load_interface_from_path(i_name) != OK:
						show_error(p_s,"Unknown interface '"+i_name+"'.")
						continue
				var spec = interfaces[i_name]
				for sig in spec.signals:
					if inst.has_signal(sig):
						continue
					show_error(p_s,"Implementation of "+i_name+" interface lacks declaration of "+sig+" signal.")
				for key in spec.variables.keys():
					if not variables.has(key):
						show_error(p_s,"Implementation of "+i_name+" interface lacks declaration of "+key+" property.")
						continue
					var type = spec.variables[key]["type"]
					if type == TYPE_NIL:
						continue
					var type_string = type_string(type)
					if type == TYPE_OBJECT:
						type_string = spec.variables[key]["class_name"]
						if type_string == variables[key]["class_name"]:
							continue
					elif type == variables[key]["type"]:
						continue
					show_error(p_s,"Type of "+key+" does not match type specified in "+i_name+" interface. "+
						"It should be a(n) "+type_string+".")
				for key in spec.methods.keys():
					if not methods.has(key):
						show_error(p_s,"Implementation of "+i_name+" interface lacks declaration of "+key+"() method.")
						continue
					var args = methods[key]["args"]
					var iargs = spec.methods[key]["args"]
					if len(args) < len(iargs):
						show_error(p_s,"Method "+key+"() has less arguments than specified in "+i_name+" interface. It should have at least "+str(len(iargs))+".")
						continue
					for i in range(len(iargs)):
						var type = args[i]["type"]
						var itype = iargs[i]["type"]
						if type == TYPE_NIL:
							continue
						if itype == TYPE_NIL:
							show_error(p_s,"Argument "+args[i]["name"]+" of "+key+"() method has excessively defined type. "+
								"Interface "+i_name+" requires this method to support any type.")
							continue
						if itype == TYPE_OBJECT:
							if args[i]["class_name"] == iargs[i]["class_name"]:
								continue
							show_error(p_s,"Type of "+args[i]["name"]+" argument of "+key+"() method does not match type specified in "+i_name+" interface. "+
								"It should be a(n) "+iargs[i]["class_name"]+".")
							continue
						if itype != type:
							show_error(p_s,"Type "+type_string(type)+" of "+args[i]["name"]+" in "+key+" method does not match "+type_string(itype)+" type specified in "+i_name+" interface.")
					var ret = methods[key]["return"]
					var iret = spec.methods[key]["return"]
					if iret["type"] == TYPE_NIL:
						continue
					var required_type = type_string(iret["type"])
					if iret["type"] == TYPE_OBJECT:
						required_type = iret["class_name"]
					if ret["type"] == TYPE_OBJECT:
						if ret["class_name"] == required_type:
							continue
					elif ret["type"] == iret["type"]:
						continue
					show_error(p_s,"Interface "+i_name+" requires "+key+"() method to return "+required_type+".")
#	inst.free()

func _build() -> bool :
	var SE = get_editor_interface().get_script_editor()
	for script in SE.get_open_scripts():
		build_script(script)
	return true

func _on_script_close(p_s:Script):
	if not p_s or p_s == get_script():
		return
	var path = p_s.resource_path
	build_from_path.call_deferred(path)

func build_from_path(path):
	if not path.ends_with(".gd"):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var s_c = file.get_as_text()
	file.close()
	for i_name in interfaces.keys():
		var empty = ""
		for _i in range(len(i_name)):
			empty += " "
		var regex = RegEx.create_from_string(r":(\s*)"+i_name+r"(\s*[\s,#])")
		for m in regex.search_all(s_c):
			print("'",m.get_string(2),"'")
		s_c = regex.sub(s_c," $1"+empty+"$2",true)
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(s_c)
	file.close()

func build_script(p_s:Script):
	if not p_s or p_s == get_script():
		return
	build_from_path(p_s.resource_path)

func show_error(p_script:Script,p_message:String):
	printerr(p_script.resource_path+" - "+p_message)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(GLOBAL_NAME)
