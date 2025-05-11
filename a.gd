extends Label
class_name A
#signal does_not_implement_interfaces
const IMPLEMENTS = [preload("res://inter3.gd")]
signal sig_1

var alfa : String
var beta : Vector2
var gamma : int = NAN
var delta := ""
@onready var epsilon : A = $"."
var binary     :	   I2.Enum

# class can have more properties
var custom_name = "B"
var child_position := Vector2(100,10)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(I2.Enum.ONE)
	text = "A is ready"

func foo():
	print("A's foo")

func bar(num:int):
	text += "  " + str(num) 
	print("The number: ", num)

func get_id(obj = self) -> int:
	return obj.get_instance_id()

func is_i4() -> bool:
	return "I4" in IMPLEMENTS

func _on_go_pressed():
	pass
