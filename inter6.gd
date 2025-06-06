extends I
class_name I6

## Interface named I6

func pip(id) -> Variant:
	return id

class SubInterface extends BasicInterface:
	class SubSub:
		var a
	@export var a: float
	var b: Vector4
	const c = 33
	var d : SubSub
	var e : Node

#