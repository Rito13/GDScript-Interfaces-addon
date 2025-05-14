@tool
extends Node
class_name Interfaces

const NOT_IMPLEMENT = "does_not_implement_interfaces"
static var inherits = {}
static var paths = {}

func _enter_tree() -> void:
	var tmp_inh = {}
	for cl in ProjectSettings.get_global_class_list():
		tmp_inh[cl["class"]] = cl["base"]
		paths[cl["class"]] = cl["path"]
	var BI_PATH = paths[&"BasicInterface"]
	for key in tmp_inh.keys():
		inherits[key] = []
		var b = tmp_inh[key]
		inherits[key].append(b)
		while tmp_inh.has(b):
			b = tmp_inh[b]
			inherits[key].append(b)
		if not &"BasicInterface" in inherits[key]:
			tmp_inh.erase(key)
			paths.erase(key)
	inherits = {BI_PATH:[]}
	paths[&"BasicInterface"] = BI_PATH
	for g_name in paths.keys():
		var path = paths[g_name]
		var s = ResourceLoader.load(path)
		if s is Script:
			extra_load_interface(s,path,g_name)
#	print(paths)

static func extra_load_interface(p_script:Script,p_path:="",p_global_name:="") -> Error:
	var base := p_script.get_base_script()
	var tmp = []
	var constants = p_script.get_script_constant_map()
	if p_path == "":
		p_path = p_script.resource_path
	for constant_name in constants:
		if constants[constant_name] is Script:
			extra_load_interface.call(constants[constant_name],p_path+":"+constant_name)
			if p_global_name != "":
				paths[p_global_name+"."+constant_name] = p_path+":"+constant_name
	if not base:
		return ERR_INVALID_PARAMETER
	var key = ""
	#if inherits.has(p_script.get_global_name()):
	#	key = p_script.get_global_name()
	while key == "":
		if inherits.has(base.resource_path):
			key = base.resource_path
		#elif inherits.has(base.get_global_name()):
		#	key = base.get_global_name()
		else:
			tmp.append(base.resource_path)
			base = base.get_base_script()
			if not base:
				return ERR_INVALID_PARAMETER
	tmp.append(key)
	tmp.append_array(inherits[key])
#	print(p_path," - ",tmp)
	inherits[p_path] = tmp
	return OK

static func implements(who:Object,what:StringName) -> bool:
	if who.has_signal(NOT_IMPLEMENT):
		return false
	var interfaces = who.get("IMPLEMENTS")
	if interfaces:
		if what in interfaces:
			return true
		if paths.has(what):
			what = paths[what]
		for i in interfaces:
			if i is Resource:
				if i.resource_path == what:
					return true
				if not inherits.has(i.resource_path):
					if extra_load_interface(i) != OK:
						continue
				i = i.resource_path
			else:
				if not paths.has(i):
					continue
				i = paths[i]
			if what in inherits[i]:
				return true
	return false

static func as_interface(who:Object,interface:StringName=&"") -> Object:
	if interface:
		assert(implements(who,interface))
	return who

static func say(what:String) -> void:
	print_rich("Global is not able to say "+what+" himself.")
