extends PanelBase
class_name SavePanel

## 【UI 层 · 存档面板】列出所有存档槽，选中一个就能保存 / 读取。
## 面板不碰文件，读写全交给 GameData —— 它只负责"显示槽位 + 转发按钮"。

@export var slot_count: int = 6

@onready var slot_list: ItemList = %SlotList
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var delete_button: Button = %DeleteButton
@onready var confirm: ConfirmationDialog = %ConfirmDialog


var _pending: String = ""                 # 这次确认是要干什么："delete" / "overwrite"

func _setup() -> void:
	for i in slot_count:
		slot_list.add_item("")                    # 先占位，文字由 _refresh 填
	slot_list.item_selected.connect(func(_i): _refresh())
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	if slot_list.item_count > 0:
		slot_list.select(0)
	_refresh()
	delete_button.pressed.connect(_on_delete_pressed)
	confirm.confirmed.connect(_on_confirmed)      # 点了"确定"才会走到这


func _current_slot() -> int:
	var picked := slot_list.get_selected_items()
	return picked[0] if not picked.is_empty() else -1


## 一个槽显示成什么文字
func _slot_line(slot: int) -> String:
	var info := GameData.peek_slot(slot)
	if info.is_empty():
		return "存档 %d ·（空）" % (slot + 1)
	var stats: Dictionary = info.get("stats", {})
	return "存档 %d · Lv.%d · %d 金 · %s" % [
		slot + 1,
		int(stats.get("level", 1)),
		int(stats.get("gold", 0)),
		String(info.get("stamp", "无时间"))]


func _refresh() -> void:
	for i in slot_list.item_count:
		slot_list.set_item_text(i, _slot_line(i))
	var slot := _current_slot()
	var has := slot >= 0 and GameData.has_save(slot)
	load_button.disabled = not has
	delete_button.disabled = not has              # 空的槽不能删


func _on_save_pressed() -> void:
	var slot := _current_slot()
	if slot < 0:
		return
	if GameData.has_save(slot):
		_ask("overwrite", "存档 %d 已有内容，覆盖吗？" % (slot + 1))    # ← 顺手做了覆盖确认
	else:
		_do_save(slot)


func _on_load_pressed() -> void:
	var slot := _current_slot()
	if slot < 0:
		return
	if not GameData.load_from_slot(slot):
		return
	get_tree().reload_current_scene()   # 世界重来：敌人复位复活、掉落物清空、HUD 与面板重建


# 两个按钮都改成"先问一句"
func _on_delete_pressed() -> void:
	var slot := _current_slot()
	if slot >= 0 and GameData.has_save(slot):
		_ask("delete", "确定删除「存档 %d」吗？" % (slot + 1))


func _ask(action: String, text: String) -> void:
	_pending = action
	confirm.dialog_text = text
	confirm.ok_button_text = "删除" if action == "delete" else "覆盖"
	confirm.popup_centered()

func _on_confirmed() -> void:
	var slot := _current_slot()
	if _pending == "delete" and GameData.delete_slot(slot):
		EventBus.on_hint_requested.emit("已删除存档 %d" % (slot + 1))
	elif _pending == "overwrite":
		_do_save(slot)
	_pending = ""
	_refresh()


# 原来的 _on_save_pressed 内容抽成这个（去掉开头的取槽和 return）
func _do_save(slot: int) -> void:
	GameData.save_to_slot(slot)
	_refresh()
	EventBus.on_hint_requested.emit("已保存到存档 %d" % (slot + 1))
