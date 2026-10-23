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


# 读档：拿字典里的 id 换回真正的物品对象，再造成一格。
# find_item 是一个"给 id、还物品"的函数（GameData.find_item 的方法引用）——
# 数据层只认识这个函数，不认识 Autoload，也不认识物品表长什么样。
# static = 属于"类"本身而不是某个格子，所以不用先有对象就能调（它本身就是用来造格子的）
static func from_dict(data: Dictionary, find_item: Callable) -> SlotData:
	# 空格子在存档里就是一个空字典 —— 直接返回 null，
	# 别拿空 id 去查表，否则每读一次档就刷一屏"找不到 id = "的警告
	if data.is_empty():
		return null
	var wanted := StringName(data.get("id", ""))   # 存档里存的是 id 字符串，先统一成 StringName 再比
	if wanted == &"":
		return null                                # 防御：id 是空的（手改过存档）也当空格子
	var it: ItemBase = find_item.call(wanted)
	if it == null:
		return null                                # 找不到时 find_item 自己会 push_warning，这里不重复报
	return SlotData.new(it, int(data.get("count", 1)))   # JSON 数字会变成 float，所以一律 int()
