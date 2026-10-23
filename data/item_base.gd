extends Resource
class_name ItemBase

## 【数据层 · 物品基类】所有物品的根：长什么样、能不能叠、属于哪一类。纯数据，无行为。
## 铁律：子类只加数据不上逻辑；id 发布后不能改；type 与 max_stack 要自洽。
## 完整说明见《脚本说明.md》→ data/item_base.gd

enum ItemType { MATERIAL, POTION, WEAPON, EQUIPMENT, SKILL, QUEST, KEY }   # 物品大类：素材/药水/武器/装备/技能/任务品/钥匙

## 身份证号：存档、掉落表、配方都靠它认出是哪件物品（发布后不能改）。
@export var id: StringName = &""
## 界面上显示的名字。
@export var display_name: String = ""
## 描述文本（装备的"怪物碎片记忆"就写在这里）。
@export_multiline var description: String = ""
## 背包格子里显示的小图标。
@export var icon: Texture2D
## 一格最多叠几个；1 = 不能叠。
@export var max_stack: int = 1
## 物品大类（素材 / 消耗品 / 武器 / 装备…）。
@export var type: ItemType = ItemType.MATERIAL
## 自定义标签，用来做额外分类查询。
@export var tags: Array[StringName] = []
## 允许玩家丢掉吗（任务品建议设 false）。
@export var can_discard: bool = true
## 卖给商店的底价（市场实际价格会按存量浮动）。
@export var sell_price: int = 0


# 能不能叠加：叠加上限大于 1 就能
func is_stackable() -> bool:
	return max_stack > 1


# 能不能和另一件物品堆进同一格
func can_stack_with(other: ItemBase) -> bool:
	# 按 id 比，不按对象比：duplicate() 出来的副本也要能叠
	return other != null and id == other.id


# 身上有没有这个标签
func has_tag(tag: StringName) -> bool:
	return tags.has(tag)
