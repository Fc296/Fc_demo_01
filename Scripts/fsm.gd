extends Node
class_name FSM

## 【通用逻辑层 · 状态机】一个角色同一时刻只做一件事，那件事就是一个状态节点。
## 不认识 Player：谁挂了状态节点谁就能用（主角 / 敌人 / NPC 共用一份）。
## 用法：① 角色场景里放一个挂本脚本的节点，命名 FSM ② 状态节点（extends State）挂成子节点，
## 节点名就是状态名 ③ 宿主在 _ready 里 start()，之后 transition_to("状态名") 切换。
##
## 待办：状态机的"我是谁"由宿主显式赋值（`$FSM.actor = self`），不要靠猜场景根节点。
## 完整说明（为什么本帧排队、状态怎么递归收集、debug_print 怎么用）见《脚本说明.md》→ Scripts/fsm.gd

## ——— 接口清单（待实现）———
# signal state_changed(from_name: StringName, to_name: StringName)
#
# @export var initial_state: StringName = &"idle"
# @export var debug_print: bool = false
#
# var actor: Actor          # 由宿主的 _ready 显式赋值
# var current: State        # 当前状态
# var previous: State       # 上一个状态
#
# func start() -> void
# func transition_to(state_name: StringName, msg: Dictionary = {}) -> void
#        # ★ 开头先判"同状态直接 return"（重入保护），否则每帧切回自己会白做功、日志刷屏
