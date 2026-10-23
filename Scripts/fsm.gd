extends Node
class_name FSM

## 【通用逻辑层 · 状态机】一个角色同一时刻只做一件事，那件事就是一个状态节点。
## 不认识 Player：谁挂了状态节点谁就能用（主角 / 敌人 / NPC 共用一份）。
## 用法：① 角色场景里放一个挂本脚本的节点，命名 FSM ② 状态节点（extends State）挂成子节点，
## 节点名就是状态名 ③ 宿主在 _ready 里 start(self)，之后 transition_to(&"状态名") 切换。
##
## 状态的"我是谁"由 start() 统一注入（state.actor / state.fsm），不要靠猜场景根节点。
## 完整说明（为什么本帧排队、状态怎么递归收集、debug_print 怎么用）见《脚本说明.md》→ Scripts/fsm.gd

## ——— 接口清单（待实现）———
signal state_changed(from_state: StringName, to_state: StringName)

## 状态机启动后先进哪个状态（名字 = 子节点名）。
@export var initial_state: StringName = &"idle"
## 打开后每次切换状态都会打印一行（调试用）。
@export var debug_print: bool = false

var actor: Actor          # 由宿主的 _ready 显式赋值
var cur_sta: State        # 当前状态
var previous: State       # 上一个状态

var _states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			register(child)


## 这个状态机有没有某个状态（状态脚本切之前先问，拼装出来的怪就不会刷警告）
func has_state(state_name: StringName) -> bool:
	return _states.has(state_name)


## 注册一个状态（节点名 = 状态名）。运行时也能调，用来临时挂状态。
func register(state: State, state_name: StringName = &"") -> void:
	var key := state_name if state_name != &"" else state.name
	if _states.has(key):
		push_warning("FSM: 状态名重复 [%s]" % key)
	_states[key] = state
	state.fsm = self
	if actor != null:
		state.actor = actor          # start() 之前调的话，actor 还是 null，等 start 再注入


func unregister(state_name: StringName) -> void:
	if cur_sta != null and cur_sta.name == state_name:
		push_warning("FSM: 不能注销当前正在跑的状态 [%s]" % state_name)
		return
	_states.erase(state_name)


func start(owner_actor: Actor) -> void:
	actor = owner_actor
	# 给每一个状态注入 actor 和 fsm 自身(fsm)
	for state in _states.values():
		state.actor = actor
		state.fsm = self
	transition_to(initial_state)


func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	# 坑1：相同状态直接返回，防止刷屏重复切换
	if cur_sta != null and cur_sta.name == state_name:
		return

	# 坑2：状态不存在，警告退出，不要静默失败
	if not _states.has(state_name):
		push_warning("FSM: 找不到状态 [%s]" % state_name)
		return

	var new_state: State = _states[state_name]

	var old_name: StringName = cur_sta.name if cur_sta != null else &""


	# 退出旧状态
	if cur_sta != null:
		cur_sta.exit_state(msg)

	previous = cur_sta
	cur_sta = new_state

	# 进入新状态
	cur_sta.enter_state(msg)

	state_changed.emit(old_name, state_name)
	if debug_print:
		print("[FSM] 切换状态 %s -> %s" % [old_name, state_name])


func _process(delta: float) -> void:
	if cur_sta == null: return
	cur_sta.update(delta)


func _physics_process(delta: float) -> void:
	if cur_sta == null: return
	cur_sta.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if cur_sta == null: return
	cur_sta.handle_input(event)
