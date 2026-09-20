extends Resource
class_name SlotData

## 【数据层 · 格子内容】一格 = 一件物品 + 数量，就这两样。
## 约定：空格子 = null（不造 count=0 的空壳）。完整说明见《脚本说明.md》→ data/slot_data.gd

@export var item: ItemBase
@export var count: int = 1


func _init(_item: ItemBase = null, _count: int = 1) -> void:
	item = _item
	count = _count


func is_empty() -> bool:
	return item == null or count <= 0


func clear() -> void:
	item = null
	count = 0


func to_dict() -> Dictionary:
	# 存档只存 id + 数量：存整个 Resource 的话，改字段/换脚本后旧档就崩
	if item == null:
		return {}
	return {"id": String(item.id), "count": count}


static func from_dict(data: Dictionary, item_db: Array[ItemBase]) -> SlotData:
	# item_db 由调用方传进来，不由数据层去问 Autoload（分层：数据层不依赖游戏）
	var wanted := StringName(data.get("id", ""))
	for entry in item_db:
		if entry != null and entry.id == wanted:
			return SlotData.new(entry, int(data.get("count", 1)))
	push_warning("读档失败：物品表里找不到 id = %s" % wanted)
	return null
