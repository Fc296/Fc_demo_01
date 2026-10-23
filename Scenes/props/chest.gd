extends Area2D
class_name Chest

## 【场景层 · 箱子】我自己那 12 格容器。玩家靠近按 E，就把"容器面板"切到我的容器上。
## 铁律：箱子不自己画格子 —— 面板还是同一个 ContainerPanel，只是把容器换成了我的。
## 注意：箱子内容暂时不进存档（等阶段二第 8 步"存档"统一处理）。

## 这个箱子有多少格。
@export var slot_count: int = 12

var inventory := InventoryData.new(slot_count)     # 我的容器
var _player_inside: bool = false
var _panel: ContainerPanel = null                  # 记住了面板，走远时要把它收起来


func _ready() -> void:
	body_entered.connect(_on_body_entered)         # 有人进圈
	body_exited.connect(_on_body_exited)           # 有人出圈


func _on_body_entered(body: Node2D) -> void:
	var a := body as Actor
	if a != null and a.is_player():
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	var a := body as Actor
	if a != null and a.is_player():
		_player_inside = false
		# 走远了就自动收起面板（前提是：现在显示的正好是我的容器）
		if _panel != null and _panel.container == inventory:
			_panel.close()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if not event.is_action_pressed("interact"):    # interact = E 键，你早就映射好了
		return
	var ui := get_tree().get_first_node_in_group(&"game_ui")
	if ui != null:
		_panel = ui.open_chest(inventory)      # 原来是 open_container()
