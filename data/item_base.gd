extends Resource
class_name ItemBase

## 【数据层 · 物品基类】所有物品的根：长什么样、能不能叠、属于哪一类。纯数据，无行为。
## 铁律：子类只加数据不上逻辑；id 发布后不能改；type 与 max_stack 要自洽。
## 完整说明见《脚本说明.md》→ data/item_base.gd

enum ItemType { MATERIAL, POTION, WEAPON, EQUIPMENT, SKILL, QUEST, KEY }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var max_stack: int = 1
@export var type: ItemType = ItemType.MATERIAL
@export var tags: Array[StringName] = []
@export var can_discard: bool = true
@export var sell_price: int = 0


func is_stackable() -> bool:
	return max_stack > 1


func can_stack_with(other: ItemBase) -> bool:
	# 按 id 比，不按对象比：duplicate() 出来的副本也要能叠
	return other != null and id == other.id


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)
