extends Resource
class_name DamagePack

## 物理伤害（会先减目标防御）。
@export var physical: float = 0.0
## 元素种类（光 / 岩 / 风）；NONE = 不带元素。
@export var element: Element.Type = Element.Type.NONE
## 元素伤害量（会先乘克制、再乘抗性）。
@export var element_amount: float = 0.0

static func make(physical_damage: float, element_type := Element.Type.NONE, element_damage := 0.0) -> DamagePack:
	var pack := DamagePack.new()
	pack.physical = physical_damage
	pack.element = element_type
	pack.element_amount = element_damage
	return pack
