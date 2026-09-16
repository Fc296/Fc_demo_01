extends Node
class_name StateMachine

## 【通用逻辑层 · 状态机】
##
## 一个角色同一时刻只做一件事，正在做的那件事就是一个状态节点。
## 本状态机不认识 Player：谁挂了状态节点，谁就能用（主角、敌人、NPC 共用一份）。
##
## 用法三步：
##   1. 角色场景里放一个挂 fsm.gd 的节点，命名 StateMachine
##   2. 把状态节点（脚本 extends State）挂成它的子节点，节点名就是状态名：idle / move / attack / hurt / die / chase
##   3. 角色在 _ready 里调用 start()；之后任何地方 transition_to("状态名") 就能切
##
## ★ 核心规则：切换"本帧排队、下一帧生效"。
##   好处有三：
##     - 一个状态正在执行时，不会被自己又切走（避免递归进入）
##     - 一帧之内只会切换一次，逻辑不会跳步
##     - 不会出现"前一个状态的 exit 晚了、后一个的 enter 早了"这种最难查的错位 bug
##
## 状态可以做成"一整组公共状态"的子场景直接塞进来复用：
## 内部用递归查找子节点，所以嵌套一层 Group 也没问题。
##
## 调试技巧：勾上 debug_print，每次切换都会打印 "角色名 A -> B"，
##   角色行为不对时先看这行日志，八成能立刻定位。
##
## ——— 接口清单 ———
# signal state_changed(from_name: StringName, to_name: StringName)
#
# @export var initial_state: StringName = &"idle"
# @export var debug_print: bool = false
#
# var actor: Actor          # 状态机属于谁（自动取当前场景根节点）
# var current: State        # 当前状态
# var previous: State       # 上一个状态（需要"回到上一状态"时用）
#
# func start() -> void
# func transition_to(state_name: StringName, msg: Dictionary = {}) -> void
