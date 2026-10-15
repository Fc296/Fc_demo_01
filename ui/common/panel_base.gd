extends Control
class_name PanelBase

## 【UI 层 · 面板基类】所有"能开关的面板"共用：标题栏 + 拖动 + 关闭。
## 子类只管自己的内容（格子、属性列表…），通用行为一律不用重写。

signal closed

#const DRAG_KEEP_VISIBLE := 24.0        # 拖动时至少留这么多像素在屏幕里

@export var header: PanelHeader        # 检查器里拖：本面板的标题栏


func _ready() -> void:
	if header != null:
		header.close_pressed.connect(close)
		header.dragged.connect(_on_header_dragged)
	_setup()                           # 子类在这里做自己的初始化


## 子类重写这个，**不要重写 _ready**
func _setup() -> void:
	pass


### 拖动标题栏：跟着鼠标挪，但**夹住范围**，不让面板被拖出屏幕
func _on_header_dragged(relative: Vector2) -> void:
	var view := get_viewport_rect().size          # 512 × 360
	var next := position + relative
	#next.x = clampf(next.x, -size.x + DRAG_KEEP_VISIBLE, view.x - DRAG_KEEP_VISIBLE)
	#next.y = clampf(next.y, 0.0, view.y - DRAG_KEEP_VISIBLE)   # 顶部夹死：标题栏必须露出来
	position = next


func close() -> void:
	hide()
	closed.emit()


func toggle_visible() -> void:
	visible = not visible
