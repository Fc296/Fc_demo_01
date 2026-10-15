extends HBoxContainer
class_name PanelHeader

## 【UI 层 · 面板标题栏】一行标题 + 一个关闭按钮，三个面板共用。
## 它只做两件事：显示标题、把鼠标操作翻译成信号。
## "关掉谁、把谁拖走"由面板基类接信号去处理 —— 标题栏不认识面板。

signal close_pressed
signal dragged(relative: Vector2)

@onready var title_label: Label = %Title
@onready var close_button: Button = %Close_Button

var _dragging := false


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	close_pressed.emit()


func set_title(text: String) -> void:
	title_label.text = text


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		dragged.emit(event.relative)     # 只报"拖了多少像素"，不关心拖的是谁
