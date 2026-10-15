extends TextureRect
class_name DragHand

## 【UI 层 · 一只手】点击拿起 / 放下物品，顺便当那个"跟着鼠标的图标"。
## 它不认识任何面板：谁把容器和序号告诉它，它就搬谁。
## 铁律：能不能放**问目标容器 can_place()**，这里绝不自己写规则。

signal changed                                    # 拿起 / 放下时广播，格子靠它更新"变淡"高亮

var held_inv: InventoryData = null                # 手里拿的是哪个容器的…
var held_index: int = -1                          # …第几格
var _held_slot: Slot = null              # 记住"从哪个格子拿起来的"，放下 / 取消 / 被拒时把它刷回来

func _ready() -> void:
	add_to_group(&"drag_hand")                    # 让格子能找到我
	hide()
	set_process(false)                            # 没拿东西时不用每帧跟鼠标

## 手里是不是正拿着"这个容器的这一格"（格子的变淡高亮靠它）
func is_holding(inv: InventoryData, index: int) -> bool:
	return held_inv == inv and held_index == index

## 拿起
func pick(inv: InventoryData, index: int, from_slot: Slot) -> void:
	if inv == null or inv.is_empty(index):
		return
	held_inv = inv
	_held_slot = from_slot
	held_index = index
	var slot := inv.get_slot(index)
	if slot != null:
		texture = slot.item.icon
		_follow()                                 # 先摆一次，避免第一帧闪在旧位置
		show()
		set_process(true)
	if is_instance_valid(from_slot):
		from_slot.refresh()              # 让源格立刻变淡
	changed.emit()


## 放下到目标格（点自己 = 原地放下）
func place(to_inv: InventoryData, to_index: int) -> bool:
	if held_inv != null and held_inv == to_inv and held_index == to_index:
		clear()
		return true
	var ok := move(held_inv, held_index, to_inv, to_index)
	clear()                                       # 放不下也松手，别一直黏着
	return ok

## 移动的唯一实现：点击移动和拖拽都走它（原来 Slot._do_move 就是这段）
func move(from_inv: InventoryData, from_index: int, to_inv: InventoryData, to_index: int) -> bool:
	if from_inv == null or to_inv == null or from_index < 0 or to_index < 0:
		return false
	if from_inv == to_inv and from_index == to_index:
		return false
	if from_inv != to_inv:
		return from_inv.transfer_to(to_inv, from_index, to_index)
	if not to_inv.merge(from_index, to_index):
		return to_inv.swap(from_index, to_index)
	return true

## 松手：清状态 + 收起图标（拿起失败、放下、拖拽开始都要调）
func clear() -> void:
	held_inv = null
	held_index = -1
	if is_instance_valid(_held_slot):
		_held_slot.refresh()             # 恢复亮度（放下 / 取消 / 被拒绝都走这里）
	_held_slot = null
	hide()
	set_process(false)
	changed.emit()

func _process(_delta: float) -> void:
	_follow()

## 图标中心压在鼠标上（Godot 把 Control 的左上角摆在鼠标处，所以要往左上偏半个尺寸）
func _follow() -> void:
	global_position = get_global_mouse_position() - size / 2.0
