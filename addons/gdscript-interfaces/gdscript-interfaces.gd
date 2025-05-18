@tool
extends EditorPlugin

var curent_script: Script
var interfaces = {}
const GLOBAL_NAME = "InterfacesAutoload"
var GLOBAL : Interfaces
var BOTTOM_PANEL_TAB : Control
var BOTTOM_PANEL_BUTTON : Button
var SE : ScriptEditor

# Messages
## [Interface]
const UNKNOWN_INTERFACE = "Unknown interface [b]%s[/b]."
## [Interface,signal]
const LACK_OF_SIGNAL = "Implementation of [b]%s[/b] interface lacks declaration of [color={color}][i]%s[/i][/color] signal."
## [Interface,property]
const LACK_OF_PROPERTY = "Implementation of [b]%s[/b] interface lacks declaration of [color={color}][u]%s[/u][/color] property."
## [Interface,method]
const LACK_OF_METHOD = "Implementation of [b]%s[/b] interface lacks declaration of [color={color}]%s()[/color] method."
## [property,Interface,expected_type]
const INVALID_PROPERTY_TYPE = "Type of [color={color}][u]%s[/u][/color] does not match type specified in [b]%s[/b] interface. It should be a(n) [color={color}][b]%s[/b][/color]."
## [method,Interface,expected_value]
const METHOD_NEED_MORE_ARGS = "Method [color={color}]%s()[/color] has less arguments than specified in [b]%s[/b] interface. It should have at least %d."
## [argument,method,Interface]
const ARGUMENT_EXCESSIVE_TYPE = "Argument [color={color}][u]%s[/u][/color] of [color={color}]%s()[/color] method has excessively defined type. Interface [b]%s[/b] requires this method to support any type."
## [curent_type,argument,method,expected_type,Interface]
const INVALID_ARGUMENT_TYPE = "Type [color={color}][b]%s[/b][/color] of [color={color}][u]%s[/u][/color] in [color={color}]%s()[/color] method does not match [color={color}][b]%s[/b][/color] type specified in [b]%s[/b] interface."
## [Interface,method,return_type]
const INVALID_RETURN_TYPE = "Interface [b]%s[/b] requires [color={color}]%s()[/color] method to return [color={color}][b]%s[/b][/color]."

func _enter_tree() -> void:
	GLOBAL = Interfaces.new()
	add_child(GLOBAL)
	SE = get_editor_interface().get_script_editor()
	SE.editor_script_changed.connect(_on_script_changed)
	SE.script_close.connect(_on_script_close)
	add_autoload_singleton(GLOBAL_NAME,"res://addons/gdscript-interfaces/global.gd")
	BOTTOM_PANEL_TAB = preload("res://addons/gdscript-interfaces/bottom_panel_tab.tscn").instantiate()
	BOTTOM_PANEL_BUTTON = add_control_to_bottom_panel(BOTTOM_PANEL_TAB,"Interfaces")
	BOTTOM_PANEL_TAB.Editor_Interface = get_editor_interface()

func _ready() -> void:
	for path in GLOBAL.paths.values():
		load_interface_from_path(path)
	var timer := Timer.new()
	timer.autostart = true
	timer.wait_time = 2
	timer.timeout.connect(_update_current)
	add_child(timer)

func _update_current() -> void:
	read_script(curent_script)

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
	var static_typing_info = p_s.source_code.get_slice('\n',p_s.source_code.get_slice_count('\n')-1)
	if static_typing_info != "" and static_typing_info[0] == '#':
		_readd_static_typing(p_s,static_typing_info)
	BOTTOM_PANEL_TAB.remove_errors_generated_by_script(p_s)
	var inst = null
	if not p_s.reload(true) and p_s.has_method("new"):
		inst = p_s.new()
	if not inst:
		return
	var cons = p_s.get_script_constant_map()
	var interface_global_name = p_s.get_global_name()
	if interface_global_name == "":
		interface_global_name = p_s.resource_path
	for key in cons:
		if cons[key] is Script:
			var script : Script = cons[key]
			BOTTOM_PANEL_TAB.remove_errors_generated_by_script(script)
			var script_name = p_s.resource_path + " : " + key
			var need_update = BOTTOM_PANEL_TAB.configure_script(script,p_s,script_name)
			var _i = inst.get(key).new()
			var inner_class_constants = script.get_script_constant_map()
			if _i is BasicInterface:
				_read_internal_interface(_i,interface_global_name+"."+key)
			elif "IMPLEMENTS" in inner_class_constants:
				_read_implementing_class(_i,inner_class_constants["IMPLEMENTS"],script)
			if need_update:
				BOTTOM_PANEL_TAB.update_script_list(script)
			if not _i is RefCounted:
				if _i.has_method("free"):
					_i.free()
	if inst is BasicInterface:
		var spec = InterfaceSpecification.new()
		for met in p_s.get_script_method_list():
			var n = met["name"]
			met.erase("name")
			spec.methods[n] = met
		for sig in p_s.get_script_signal_list():
			spec.signals.append(sig["name"])
		for prop in p_s.get_script_property_list():
			if prop["usage"] & PROPERTY_USAGE_CATEGORY or prop["usage"] & PROPERTY_USAGE_GROUP:
				continue
			if prop["name"].ends_with(".gd"):
				continue
			var n = prop["name"]
			prop.erase("name")
			spec.variables[n] = prop
		interfaces[interface_global_name] = spec
		return
	if "IMPLEMENTS" in cons and not p_s.has_script_signal(Interfaces.NOT_IMPLEMENT):
		_read_implementing_class(inst,cons["IMPLEMENTS"],p_s)
	if not inst is RefCounted:
		if inst.has_method("free"):
			inst.free()

func find_code_edits(parent:Node=SE) -> Array[CodeEdit]:
	var _to_return : Array[CodeEdit] = []
	var _nodes = parent.find_children("*",&"CodeEdit",true,false)
	for n in _nodes:
		_to_return.append(n as CodeEdit)
	return _to_return

func _readd_static_typing(p_script:Script,p_info:String):
	if p_info == "":
		return
	p_info = p_info.erase(0,1)
	var slices : Array = p_info.split("'")
	for i in range(len(slices)):
		var s = slices[i] as String
		if s.ends_with("-"):
			slices[i] = s.trim_suffix("-").to_int()
	var s_c = p_script.source_code
	var code_edit : CodeEdit
	if len(slices) > 1:
		var candidates = find_code_edits()
		for c in candidates:
			if c.text == s_c:
				code_edit = c
				break
	for i in range(1,len(slices),2):
		var pos = slices[i-1] as int
		var typing = slices[i] as String
		if not pos or not typing:
			continue
#		print(pos," - ",typing)
		var search = r"\s"
		for c in typing:
			search += r"\s"
		var regex = RegEx.create_from_string(search)
#		for m in regex.search_all(p_script.source_code,pos,pos+len(typing)):
#			print(m.get_string(0))
		s_c = regex.sub(s_c,":"+typing,true,pos,pos+len(typing)+1)
	if code_edit:
		print("Readed static typing in '",p_script.resource_path,"' successfully.")
		code_edit.text = s_c.trim_suffix("\n#"+p_info)
#	print(p_script.source_code)

func _read_internal_interface(inst:BasicInterface,interface_global_name:StringName):
	var spec = InterfaceSpecification.new()
	for met in inst.get_method_list():
		var n = met["name"]
		met.erase("name")
		spec.methods[n] = met
	for sig in inst.get_signal_list():
		spec.signals.append(sig["name"])
	for prop in inst.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_CATEGORY or prop["usage"] & PROPERTY_USAGE_GROUP:
			continue
		if prop["name"].ends_with(".gd"):
			continue
		var n = prop["name"]
		prop.erase("name")
		spec.variables[n] = prop
	interfaces[interface_global_name] = spec

func _read_implementing_class(inst:Object,implements:Array,p_s:Script):
	if not implements:
		return
	var methods = {}
	var variables = {}
	for method in inst.get_method_list():
		methods[method["name"]] = method
	for prop in inst.get_property_list():
		variables[prop["name"]] = prop
	for i_name in implements:
		if i_name is Script:
			if i_name.get_global_name() == "":
				i_name = i_name.resource_path
			else:
				i_name = i_name.get_global_name()
		if not interfaces.has(i_name):
			if load_interface_from_path(i_name) != OK:
				show_error(p_s,UNKNOWN_INTERFACE % [i_name])
				continue
		var spec = interfaces[i_name]
		for sig in spec.signals:
			if inst.has_signal(sig):
				continue
			show_error(p_s,LACK_OF_SIGNAL % [i_name,sig])
		for key in spec.variables.keys():
			if not variables.has(key):
				show_error(p_s,LACK_OF_PROPERTY % [i_name,key])
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
			show_error(p_s,INVALID_PROPERTY_TYPE % [key,i_name,type_string])
		for key in spec.methods.keys():
			if not methods.has(key):
				show_error(p_s,LACK_OF_METHOD % [i_name,key])
				continue
			var args = methods[key]["args"]
			var iargs = spec.methods[key]["args"]
			if len(args) < len(iargs):
				show_error(p_s,METHOD_NEED_MORE_ARGS % [key,i_name,len(iargs)])
				continue
			for i in range(len(iargs)):
				var type = args[i]["type"]
				var itype = iargs[i]["type"]
				if type == TYPE_NIL:
					continue
				if itype == TYPE_NIL:
					show_error(p_s,ARGUMENT_EXCESSIVE_TYPE % [args[i]["name"],key,i_name])
					continue
				if itype == TYPE_OBJECT:
					if args[i]["class_name"] == iargs[i]["class_name"]:
						continue
					var c_type = args[i]["class_name"]
					if c_type == "":
						c_type = type_string(type)
					show_error(p_s,INVALID_ARGUMENT_TYPE % [c_type,args[i]["name"],key,iargs[i]["class_name"],i_name])
					continue
				if itype != type:
					show_error(p_s,INVALID_ARGUMENT_TYPE % [type_string(type),args[i]["name"],key,type_string(itype),i_name])
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
			show_error(p_s,INVALID_RETURN_TYPE % [i_name,key,required_type])

func _build() -> bool :
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
	var to_readd := {}
	for i_name in interfaces.keys():
		var empty = ""
		for _i in range(len(i_name)):
			empty += " "
		var regex = RegEx.create_from_string(r":(\s*)"+i_name+r"(\s*[\s,#])")
		for m in regex.search_all(s_c):
			to_readd[m.get_start()] = m.get_string(1) + i_name
		s_c = regex.sub(s_c," $1"+empty+"$2",true)
	file = FileAccess.open(path, FileAccess.WRITE)
	if s_c.ends_with("\n#\n"):
		s_c = s_c.trim_suffix("\n")
	elif not s_c.ends_with("\n#"):
		s_c += "\n#"
	var to_readd_keys = to_readd.keys()
	to_readd_keys.sort()
	for key in to_readd_keys:
		s_c += str(key) + "-'" + to_readd[key] + "'"
	file.store_string(s_c)
	file.close()

func build_script(p_s:Script):
	if not p_s or p_s == get_script():
		return
	build_from_path(p_s.resource_path)

func show_error(p_script:Script,p_message:String):
	var ES = get_editor_interface().get_editor_settings()
	var c :Color = ES.get_setting("interface/theme/accent_color")
	p_message = p_message.format({"color":"#"+c.to_html(false)})
	BOTTOM_PANEL_TAB.add_error(p_message,p_script)
	#printerr(p_script.resource_path+" - "+p_message)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(GLOBAL_NAME)
	remove_control_from_bottom_panel(BOTTOM_PANEL_TAB)
	BOTTOM_PANEL_TAB.free()
