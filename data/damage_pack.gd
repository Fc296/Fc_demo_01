extends Resource
class_name DamagePack

@export var physical: float = 0.0
@export var element: Element.Type = Element.Type.NONE
@export var element_amount: float = 0.0

static func make(physical_damage: float, element_type := Element.Type.NONE, element_damage := 0.0) -> DamagePack:
	var pack := DamagePack.new()
	pack.physical = physical_damage
	pack.element = element_type
	pack.element_amount = element_damage
	return pack
