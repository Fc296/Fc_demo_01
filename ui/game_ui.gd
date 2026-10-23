extends CanvasLayer

## 【UI 层 · 界面总管】所有面板的开关只有这一个入口。
## 规则（10-23 改版）：
##   1）面板可以同时开多个（像桌面窗口）；点按钮只开关它自己，不影响别人；
##   2）ESC 只关"最后操作的那一个"—— 开面板、或点面板里的任何地方，都会把它记成最后操作，
##      并提到最上层（视觉上也能看出 ESC 会关谁）；
##   3）点箱子 = 箱子 + 背包一起开（换东西两边都要看得见）；关箱子不强制关背包；
##   4）只要有任意面板开着，就广播 on_ui_blocking_changed(true) —— 玩家移动 ×0.4、不能攻击。
## 面板自己不知道这些规则；按钮也只知道"我想开哪个"，由这里决定。

@onready var bag_panel: ContainerPanel = %Conta_Panel
@onready var equip_panel: ContainerPanel = %Equip_Panel
@onready var stats_panel: PanelBase = %Stats_Panel
@onready var craft_panel: CraftPanel = %Craft_Panel
@onready var market_panel: MarketPanel = %Market_Panel
@onready var save_panel: SavePanel = %Save_Panel
@onready var chest_panel: ContainerPanel = %Chest_Panel

var _recent: Array[PanelBase] = []   # 最近操作顺序：末尾 = 最后操作（ESC 关它）
var _blocked := false                # 上一次广播出去的状态（只在变化时广播）


func _ready() -> void:
	add_to_group(&"game_ui")
	equip_panel.open(GameData.equipment)
	bag_panel.open(GameData.inventory)      # 绑容器 + 建格子，只做一次
	for p in _all_panels():
		p.hide()
		p.closed.connect(_on_panel_closed.bind(p))   # 标题栏的叉 / 代码 close() 都会走这里


## 唯一入口：开 / 关一个菜单面板（同一个再点一次 = 关）
func open_panel(p: PanelBase) -> void:
	if p == null:
		return
	if p.visible:
		p.close()                           # 再点一次同一个按钮 = 关
		return
	p.show()
	_touch(p)
	_apply_blocking()


## 箱子开口：箱子 + 背包一起显示（别的面板不受影响）
func open_chest(target: InventoryData) -> ContainerPanel:
	chest_panel.open(target)
	if not bag_panel.visible:
		bag_panel.show()
		_touch(bag_panel)                   # 背包是"顺带打开的"
	_touch(chest_panel)                     # 按 E 这次操作的是箱子 → ESC 先关箱子
	_apply_blocking()
	return chest_panel


## 全部关掉（目前只有调试 / 换场景用；ESC 走 _close_last）
func close_all() -> void:
	for p in _all_panels():
		if p.visible:
			p.close()
	_recent.clear()
	_apply_blocking()


func is_any_panel_open() -> bool:
	for p in _all_panels():
		if p.visible:
			return true
	return false


## ESC：只关最后操作的那一个；没有面板时什么也不做
func _close_last() -> void:
	while not _recent.is_empty():
		var p: PanelBase = _recent.pop_back()
		if p.visible:
			p.close()
			_apply_blocking()
			return
	_apply_blocking()                       # 栈里剩下都是已经关掉的 → 刷新一次状态


## 记成"最后操作"，并提到最上层（画在同一层的面板靠 tree 顺序决定谁在上）
func _touch(p: PanelBase) -> void:
	if p == null or not p.visible:
		return
	_recent.erase(p)
	_recent.append(p)
	var parent := p.get_parent()
	if parent != null:
		parent.move_child(p, -1)


func _on_panel_closed(p: PanelBase) -> void:
	_recent.erase(p)
	_apply_blocking()


## 只在"有没有面板"真的变化时广播 —— 每帧发一次没人需要
func _apply_blocking() -> void:
	var blocked := is_any_panel_open()
	if blocked == _blocked:
		return
	_blocked = blocked
	EventBus.on_ui_blocking_changed.emit(blocked)


## 鼠标按在哪个面板里，就把哪个记成"最后操作"。
## 不用 gui_input：按钮会把点击吃掉；这里从"悬停的控件"往上找最近的 PanelBase。
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var c := get_viewport().gui_get_hovered_control()
		while c != null:
			if c is PanelBase:
				_touch(c)
				return
			c = c.get_parent() as Control


## ESC 是 Godot 内置动作（ui_cancel），不用自己在输入映射里配
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_any_panel_open():
		_close_last()
		get_viewport().set_input_as_handled()


func _all_panels() -> Array:
	return [bag_panel, equip_panel, stats_panel, craft_panel, market_panel, save_panel, chest_panel]
