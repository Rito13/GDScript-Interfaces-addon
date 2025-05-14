extends Node

var test : I6 # comment
@export var s : A.SubR

func use(i  ,_b:='lol'):
	i.foo()
	i.bar(randi())

## the argument i of type : 	I4  is ver important

func _ready() -> void:
	var a := A.new()
	add_child(a)
	use(Interfaces.as_interface(a))
	#test = Interfaces.an_enumeration.MINUS_TWO
	print(Interfaces.implements($Node2,"BasicInterface"))
	print("Main: I, J, K, L")
