extends Panel
class_name Slot

## 【UI 层 · 格子】背包 / 装备 / 技能 / 商店的格子都是它，靠参数决定行为。
## 只干两件事：显示（投影，自己不存数据）、按 filter 接受拖拽。
## 约定：空格子 `_get_drag_data` 返回 null；拖动期间**不动数据**（松手没落到格子就自动回原位）。
## 拖拽负载固定为 `{"container": InventoryData, "index": int}`。
## 四个拖拽函数的**可抄骨架**、以及索引为什么私有，见《脚本说明.md》→ ui/common/slot.gd

## ——— 接口清单（待实现）———
# signal slot_clicked(index: int, button: int)      # 右键使用 / 双击使用靠这个转发

@onready var icon_rect: TextureRect = $Icon
@onready var count_label: Label = $Count

@export var slot_index: int = -1

var _index: int = -1                       # 私有：只由 set_source() 改，别在外面赋值
var inventory: InventoryData                       # 我显示的是哪个容器


## 找到场上的那只手（它挂在 HUD 上，自己进了 "drag_hand" 组）
func _hand() -> DragHand:
	return get_tree().get_first_node_in_group(&"drag_hand") as DragHand


func set_source(inv: InventoryData, index: int) -> void:
	inventory = inv
	_index = index
	refresh()


func refresh() -> void:   # 按数据重画：图标 / 数量 / 空格 / 禁用态
	var slot := inventory.get_slot(_index) if inventory != null else null
	if slot == null or slot.item == null:
		icon_rect.texture = null
		count_label.text = ""
		icon_rect.modulate.a = 1.0        # ← 空格子把亮度复位，别留上次的残留
		return
	icon_rect.texture = slot.item.icon
	count_label.text = str(slot.count) if slot.count > 1 else ""
	var h := _hand()
	icon_rect.modulate.a = 0.35 if h != null and h.is_holding(inventory, _index) else 1.0


func _accepts(item: ItemBase) -> bool:      # filter 判定，拖拽和高亮都用它
	return inventory.can_place(_index, item)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if inventory == null or _index < 0 or inventory.is_empty(_index):
		return null
	var h := _hand()
	if h != null:
		h.clear()                   # 按下→移动=拖拽，先把"点选中"的状态清掉
	set_drag_preview(_make_preview())
	return {"container": inventory, "index": _index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not (data.has("container") and data.has("index")):
		return false
	var from_inv: InventoryData = data["container"]
	var from_index: int = data["index"]
	if from_inv == inventory and from_index == _index:
		return false                         # 拖回自己身上，什么都不做
	var from_slot := from_inv.get_slot(from_index)
	if from_slot == null:
		return false
	return _accepts(from_slot.item)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var h := _hand()
	if h == null:
		return
	h.move(data["container"], data["index"], inventory, _index)
	h.clear()


func _make_preview() -> Control:    # 跟随鼠标的小图标
	var holder := Control.new()          # 外层：只负责"跟着鼠标走"（Godot 把它的左上角钉在鼠标上）
	var rect := TextureRect.new()
	var slot := inventory.get_slot(_index)
	rect.texture = slot.item.icon if slot != null else null
	rect.size = Vector2(28, 28)          # ★ new 出来的控件不会自己长尺寸，不写这句它是 0×0
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.modulate.a = 0.8
	rect.position = -rect.size / 2.0     # ★ 往左上偏半个尺寸 → 中心正好压在鼠标上
	holder.add_child(rect)
	return holder


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_left_click()


func _on_left_click() -> void:
	var h := _hand()
	if h == null:
		return
	if h.held_index < 0:            # 空着手 → 拿起
		h.pick(inventory, _index, self)
	else:                           # 手上有东西 → 放下
		h.place(inventory, _index)
