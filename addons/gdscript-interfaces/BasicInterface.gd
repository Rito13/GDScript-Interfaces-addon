class_name BasicInterface
extends RefCounted

## This is base class for all interfaces.
##
## Extend this class in order to create new interface
## then to implement it in class write following code:
## [codeblock lang=gdscript]
## # Class of this file implements two interfces:
## # 1. NamedInterface
## # 2. "res://un_named_interface.gd"
##
## const IMPLEMENTS = ["NamedInterface",preload("res://un_named_interface.gd")]
## [/codeblock]

## Class can't be empty in order to generate class description [br]
## Constants are implemented in Interfaces them self,
## so this will not have any effect on definition of Interfaces.
const ___DUMMY___ = "DUMMY"

#