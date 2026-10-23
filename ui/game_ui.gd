extends CanvasLayer

## 【UI 层 · 界面总管】所有面板的开关只有这一个入口。
## 规则：
##   1）菜单面板互斥：背包 / 装备 / 属性 / 锻造 / 拍卖 / 存档 同时只开一个；
##   2）箱子例外：箱子和背包成对显示；换到别的面板时两个一起关；
##   3）ESC 关掉所有面板；I 键不接（10-23 决定去掉）；
##   4）有面板打开时广播 on_ui_blocking_changed(true) —— 玩家移动 ×0.4、不能攻击。
## 面板自己不知道这些规则；按钮也只知道"我想开哪个"，由这里决定。

@onready var bag_panel: ContainerPanel = %Conta_Panel
@onready var equip_panel: ContainerPanel = %Equip_Panel
@onready var stats_panel: PanelBase = %Stats_Panel
@onready var craft_panel: CraftPanel = %Craft_Panel
@onready var market_panel: MarketPanel = %Market_Panel
@onready var save_panel: SavePanel = %Save_Panel
@onready var chest_panel: ContainerPanel = %Chest_Panel

var _current: PanelBase = null      # 当前打开的"菜单面板"；箱子模式下为 null
var _blocked := false               # 上一次广播出去的状态（只在变化时广播）


func _ready() -> void:
	add_to_group(&"game_ui")
	equip_panel.open(GameData.equipment)
	bag_panel.open(GameData.inventory)      # 绑容器 + 建格子，只做一次
	for p in [chest_panel, bag_panel, equip_panel, stats_panel, craft_panel, market_panel, save_panel]:
		p.hide()
		p.closed.connect(_on_panel_closed.bind(p))   # 标题栏的叉 / 代码 close() 都会走这里


## 唯一入口：开 / 关一个菜单面板（同一个再点一次 = 关）
func open_panel(p: PanelBase) -> void:
	if p == null:
		return
	if chest_panel.visible:
		chest_panel.close()                 # 换到菜单面板 → 箱子模式退出（背包由 closed 处理器收起）
	if p.visible:
		p.close()                           # 再点一次同一个按钮 = 关
		return
	if _current != null and _current != p:
		_current.close()
	_current = p
	p.show()
	_apply_blocking()


## 箱子开口：箱子 + 背包成对显示；菜单面板先收起
func open_chest(target: InventoryData) -> ContainerPanel:
	if _current != null:
		var p := _current
		_current = null                     # 先清，避免 closed 处理器再把它当成"当前面板"
		p.close()
	chest_panel.open(target)
	bag_panel.show()
	_apply_blocking()
	return chest_panel


## ESC：关掉所有面板（箱子 + 背包一起关）
func close_all() -> void:
	if chest_panel.visible:
		chest_panel.close()                 # 它的 closed 处理器会顺手把背包收起
	if _current != null:
		var p := _current
		_current = null
		p.close()
	_apply_blocking()


func is_any_panel_open() -> bool:
	return _current != null or chest_panel.visible


func _on_panel_closed(p: PanelBase) -> void:
	if p == chest_panel:
		bag_panel.hide()                    # 箱子关了 → 配对的背包也收
	elif p == _current:
		_current = null
	_apply_blocking()


## 只在"有没有面板"真的变化时广播 —— 每帧发一次没人需要
func _apply_blocking() -> void:
	var blocked := is_any_panel_open()
	if blocked == _blocked:
		return
	_blocked = blocked
	EventBus.on_ui_blocking_changed.emit(blocked)


## ESC 是 Godot 内置动作（ui_cancel），不用自己在输入映射里配
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_any_panel_open():
		close_all()
		get_viewport().set_input_as_handled()
