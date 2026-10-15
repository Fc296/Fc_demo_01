extends Resource
class_name InventoryData

## 【通用逻辑层 · 容器】背包 / 箱子 / 商店货架 / 装备栏 / 锻造材料格，都是"一堆格子"。
## 分工：**容器只管"哪里放了什么"，"这一格能收什么"归 Slot 管**。
## 铁律：Resource 默认共享引用 —— 运行时必须 `InventoryData.new()`（或 .tres.duplicate()），
## 否则玩家背包和箱子会指向同一份数据。
## 完整说明（为什么用 Resource 不用 Node、为什么 filter 不放这里）见《脚本说明.md》→ Scripts/inventory_data.gd

## 内容变化 → 直接用 Resource 自带的 changed 信号（不必自己声明）：
## 一对一关系，只有它自己的面板关心，所以不进 EventBus
@export var slot_count: int = 24
var slots: Array[SlotData] = []            # 空格子写 null
var slot_rule: Callable = Callable()        # (index: int, item: ItemBase) -> bool；空 = 什么都收

## ——— 已实现 ———
## _init(count)            建格子（默认 24 格）
## add_item(item, count)   返回"没装下"的数量，0 = 全装下


## ——— 接口清单（S3 的面板与拖拽要用，待实现）———
# signal item_used(item: ItemBase, index: int)
# func transfer_to(target: InventoryData, from_index: int) -> bool   # 跨容器搬运（背包 → 箱子）
# func use_item(index: int) -> void

func _init(count: int = 24) -> void:
	slot_count = count
	slots.resize(slot_count)      # ← 少了这行，slots 是空数组，slots[0] 直接越界


func can_place(index: int, item: ItemBase) -> bool:
	if item == null:
		return false
	if not slot_rule.is_valid():
		return true                          # 没规则 = 背包，什么都收
	return slot_rule.call(index, item)


## 装得下 count 个吗？（把每格的剩余空间加起来算，不看就不知道背包是不是真的满了）
func can_add(item: ItemBase, count: int = 1) -> bool:
	if item == null or count <= 0:
		return true
	var room := 0
	for slot in slots:
		if slot == null:
			room += item.max_stack                       # 空格子能放一整叠
		elif slot.item.can_stack_with(item):
			room += item.max_stack - slot.count          # 同类格子还有多少空
		if room >= count:
			return true
	return false


func add_item(item: ItemBase, count: int = 1) -> int:
	if item == null or count <= 0:
		return count
	var remaining := count
	# ① 先找已有的同类格子叠加
	if item.is_stackable():
		for slot in slots:
			if remaining <= 0:
				break
			if slot == null or not slot.item.can_stack_with(item):
				continue
			var space: int = item.max_stack - slot.count
			if space <= 0:
				continue
			var put: int = mini(space, remaining)
			slot.count += put
			remaining -= put
	# ② 还有剩的，找空格开新格
	for i in slots.size():
		if remaining <= 0:
			break
		if slots[i] != null:
			continue
		var put: int = mini(item.max_stack, remaining)
		slots[i] = SlotData.new(item, put)
		remaining -= put
	if remaining != count:
		changed.emit()            # 有变化才发，没变化别浪费
	return remaining              # 返回"没装下的数量"，0 = 全装下


func count_of(id: StringName) -> int:
	var total := 0
	for slot in slots:
		if slot != null and slot.item != null and slot.item.id == id:
			total += slot.count
	return total


func is_empty(index: int) -> bool:
	return get_slot(index) == null


func get_slot(index: int) -> SlotData:
	if index < 0 or index >= slots.size():
		return null
	return slots[index]


func swap(a: int, b: int) -> bool:
	if a == b or a < 0 or b < 0 or a >= slots.size() or b >= slots.size():
		return false
	var sa := slots[a]
	var sb := slots[b]
	if sa != null and not can_place(b, sa.item):      # a 的东西要塞得进 b
		return false
	if sb != null and not can_place(a, sb.item):      # b 的东西要塞得进 a
		return false
	slots[a] = sb
	slots[b] = sa
	changed.emit()
	return true


func merge(from_index: int, to_index: int) -> bool:
	var from := get_slot(from_index)
	var to := get_slot(to_index)
	if from == null or to == null or not to.item.can_stack_with(from.item):
		return false
	if not can_place(to_index, from.item):            # ★ 合并也要过规则
		return false
	var space: int = to.item.max_stack - to.count
	if space <= 0:
		return false
	var put: int = mini(space, from.count)
	to.count += put
	from.count -= put
	if from.count <= 0:
		slots[from_index] = null
	changed.emit()
	return true


func transfer_to(target: InventoryData, from_index: int, to_index: int) -> bool:
	if target == null or target == self:
		return false
	var from := get_slot(from_index)
	if from == null:
		return false
	if not target.can_place(to_index, from.item):     # ★ 问的是**目标容器**的规则
		return false
	var to := target.get_slot(to_index)
	if to == null:                                   # 目标空着 → 整格搬过去
		target.slots[to_index] = from
		slots[from_index] = null
	elif to.item.can_stack_with(from.item):          # 同类 → 尽量叠
		var space: int = to.item.max_stack - to.count
		var put: int = mini(space, from.count)
		if put <= 0:
			return false
		to.count += put
		from.count -= put
		if from.count <= 0:
			slots[from_index] = null
	else:                                            # 不同的东西 → 两边对调
		if not can_place(from_index, to.item):       # ★ 我这边也要放得下对方的东西
			return false
		target.slots[to_index] = from
		slots[from_index] = to
	changed.emit()
	target.changed.emit()
	return true


func remove_item(index: int, count: int = 1) -> void:
	var slot := get_slot(index)
	if slot == null:
		return
	slot.count -= count
	if slot.count <= 0:
		slots[index] = null
	changed.emit()


## 按 id 扣若干个（从前往后扫是安全的：remove_item 只改当前那一格）
func remove_item_by_id(id: StringName, count: int) -> void:
	var left := count
	for i in slots.size():
		if left <= 0:
			break
		var slot := get_slot(i)
		if slot == null or slot.item == null or slot.item.id != id:
			continue
		var take: int = mini(slot.count, left)
		remove_item(i, take)
		left -= take


func to_dict() -> Dictionary:
	var arr: Array = []
	for s in slots:
		arr.append(s.to_dict() if s != null else {})     # 空格子存空字典
	return {"slots": arr}


func from_dict(data: Dictionary, item_db: Array[ItemBase]) -> void:
	# ⚠️ 原地改，**不要 new 一个新容器** —— 面板连的就是这个对象
	var saved: Array = data.get("slots", [])
	for i in slots.size():
		slots[i] = SlotData.from_dict(saved[i], item_db) if i < saved.size() else null
	changed.emit()
