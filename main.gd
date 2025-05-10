extends Node

var test     # comment

func use(i  ,_b:='lol'):
	i.foo()
	i.bar(randi())

## the argument i of type  	  is ver important

func _ready() -> void:
	var a := A.new()
	add_child(a)
	use(Interfaces.as_interface(a))
	#test = Interfaces.an_enumeration.MINUS_TWO
	print(Interfaces.implements(a,"I2"))
	print("Main  , J, K, L")
