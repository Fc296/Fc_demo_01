extends Button
class_name UiButton

## 【UI 层 · 菜单按钮】点一下开关它负责的那个面板；鼠标悬停 / 按下时整体弹缩。
## 谁负责哪个面板，在检查器里拖 —— 按钮自己不需要知道 game_ui 在哪。

const SCALE_NORMAL  := Vector2.ONE
const SCALE_HOVER   := Vector2(1.09, 1.09)     # 悬停：放大 12%
const SCALE_PRESSED := Vector2(0.94, 0.94)     # 按下：缩到 94%
const SCALE_TIME    := 0.08                    # 过渡时长（秒）

@export var target_panel: PanelBase

var _scale_tween: Tween


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

	# target_panel 是检查器里拖的引用：漏拖时按钮会静默没反应，开局就喊一声
	if target_panel == null:
		push_warning("菜单按钮没绑定面板：%s" % name)

	# 缩放必须以"按钮中心"为基准，否则会往右下角长
	_center_pivot()
	resized.connect(_center_pivot)


func _on_pressed() -> void:
	# 自己不判断开/关 —— 互斥、箱子例外、ESC 都在 GameUi 一处管
	var ui := get_tree().get_first_node_in_group(&"game_ui")
	if ui != null and target_panel != null:
		ui.open_panel(target_panel)


func _center_pivot() -> void:
	pivot_offset = size / 2.0


func _tween_scale(target: Vector2) -> void:
	# 上一个动画没跑完就打断它，否则快速进出鼠标会让两个 Tween 抢同一个 scale
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", target, SCALE_TIME)


func _on_mouse_entered() -> void:
	_tween_scale(SCALE_HOVER)


func _on_mouse_exited() -> void:
	_tween_scale(SCALE_NORMAL)


func _on_button_down() -> void:
	_tween_scale(SCALE_PRESSED)


func _on_button_up() -> void:
	# 松手时鼠标可能还在按钮上，也可能已经移开
	_tween_scale(SCALE_HOVER if is_hovered() else SCALE_NORMAL)
