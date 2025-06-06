extends Node

var test      # comment
var test_array            = []
var test_dict #                       = {}
@export var s : A.SubR

func use(i  ,_b:='lol'):
	i.foo()
	i.bar(randi())
	if _b == "return":
		return
	var s = i

## the argument i of type  	    is ver important

func _ready() -> void:
	var a := A.new()
	add_child(a)
	use(Interfaces.as_interface(a))
	use(Interfaces.as_interface(a),"return")
	#test = Interfaces.an_enumeration.MINUS_TWO
	print(Interfaces.implements($Node2,"BasicInterface"))
	print("Main   , J, K, L")
	
	print("")
	
	for i in [1,3,4,7]:
		test_array.append(A.new())
		var inter   = test_array[len(test_array)-1]
		inter.bar(i)

#23-' I6'53-' Array[I]'84-' Dictionary[String,I]'146-'I'252-' 	I4'519-' I'610-'I'