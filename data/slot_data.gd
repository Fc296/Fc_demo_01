extends Resource
class_name SlotData

## 【数据层 · 格子内容】一格 = 一件物品 + 数量，就这两样。
## 约定：空格子 = null（不造 count=0 的空壳）。完整说明见《脚本说明.md》→ data/slot_data.gd

@export var item: ItemBase      # 这一格里装的是哪件物品
@export var count: int = 1      # 装了几个


# 构造函数：SlotData.new(物品, 数量) 直接造出一格
func _init(_item: ItemBase = null, _count: int = 1) -> void:
	item = _item
	count = _count


# 是不是空格子（没物品，或数量小于等于 0）
func is_empty() -> bool:
	return item == null or count <= 0


# 清空这一格
func clear() -> void:
	item = null
	count = 0


# 存档：把这一格写成字典（只写 id + 数量，不写整个物品对象）
func to_dict() -> Dictionary:
	# 存档只存 id + 数量：存整个 Resource 的话，改字段/换脚本后旧档就崩
	if item == null:
		return {}
	return {"id": String(item.id), "count": count}


# 读档：拿字典里的 id 去物品表里找回真正的物品对象，再造成一格
# static = 属于"类"本身而不是某个格子，所以不用先有对象就能调（它本身就是用来造格子的）
static func from_dict(data: Dictionary, item_db: Array[ItemBase]) -> SlotData:
	# 空格子在存档里就是一个空字典 —— 直接返回 null，
	# 别拿空 id 去物品表里找，否则每读一次档就刷一屏"找不到 id = "的警告
	if data.is_empty():
		return null
	# item_db 由调用方传进来，不由数据层去问 Autoload（分层：数据层不依赖游戏）
	var wanted := StringName(data.get("id", ""))   # 存档里存的是 id 字符串，先统一成 StringName 再比
	if wanted == &"":
		return null                                # 防御：id 是空的（手改过存档）也当空格子
	for entry in item_db:
		if entry != null and entry.id == wanted:
			return SlotData.new(entry, int(data.get("count", 1)))
	push_warning("读档失败：物品表里找不到 id = %s" % wanted)
	return null
