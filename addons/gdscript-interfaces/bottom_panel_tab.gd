@tool
extends HBoxContainer

class _Error:
	var line := -1
	var description := ""
	var item_text := ""

class ErrorArray:
	var errors : Array[_Error] = []

var scripts : Array[Script] = []
var indexes : Dictionary = {}
var errors : Array[ErrorArray] = []
var Editor_Interface : EditorInterface
var selected_script : int = 0

func _ready() -> void:
	$List.clear()

func remove_errors_generated_by_script(p_script:Script):
	if not indexes.has(p_script):
		return
	errors[indexes[p_script]].errors = []
	if selected_script == indexes[p_script]:
		$List.clear()
	$List/Timer.start()

func add_error(p_message:String,p_script:Script,p_line:=-1):
	if not indexes.has(p_script):
		indexes[p_script] = len(scripts)
		$Scripts.add_item(p_script.resource_path)
		scripts.append(p_script)
		errors.append(ErrorArray.new())
	var i = indexes[p_script]
	var item_text = "Error" + str(len(errors[i].errors))
	if p_line != -1:
		item_text += " in line " + str(p_line)
	var e := _Error.new()
	e.line = p_line
	e.description = p_message
	e.item_text = item_text
	errors[i].errors.append(e)
	if i == selected_script:
		$List.add_item(e.item_text)

func _on_list_item_selected(index: int) -> void:
	$Description.text = errors[selected_script].errors[index].description

func _on_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	pass # Replace with function body.

func _on_list_item_activated(index: int) -> void:
	Editor_Interface.edit_script(scripts[selected_script])

func _on_scripts_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	pass # Replace with function body.

func _on_scripts_item_selected(index: int) -> void:
	$Description.text = ""
	selected_script = index
	$List.clear()
	for e in errors[index].errors:
		$List.add_item(e.item_text)

func _on_timer_timeout() -> void:
	var i = 0
	while i < len(errors):
		if errors[i].errors.is_empty():
			errors.remove_at(i)
			indexes.erase(scripts[i])
			scripts.remove_at(i)
			$Scripts.remove_item(i)
			if i == selected_script:
				selected_script = -1
				$Description.text = ""
			i -= 1
		i += 1
