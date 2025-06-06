extends Node

var test : I6 # comment
var test_array : Array[I] = []
var test_dict #: Dictionary[String,I] = {}
@export var s : A.SubR

func use(i:I,_b:='lol'):
	i.foo()
	i.bar(randi())
	if _b == "return":
		return
	var s = i

## the argument i of type: 	I4  is ver important

func _ready() -> void:
	var a := A.new()
	add_child(a)
	use(Interfaces.as_interface(a))
	use(Interfaces.as_interface(a),"return")
	#test = Interfaces.an_enumeration.MINUS_TWO
	print(Interfaces.implements($Node2,"BasicInterface"))
	print("Main: I, J, K, L")
	
	print("")
	var __s := "\"Nineteen Eighty-Four\" is a book"
	var __s2 = '"Dune" is too'
	
	for i in [1,3,4,7]:
		test_array.append(A.new())
		var inter:I = test_array[len(test_array)-1]
		inter.bar(i)
