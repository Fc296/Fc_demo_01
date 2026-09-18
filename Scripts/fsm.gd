extends Node
class_name FSM

## 【通用逻辑层 · 状态机】
##
## 一个角色同一时刻只做一件事，正在做的那件事就是一个状态节点。
## 本状态机不认识 Player：谁挂了状态节点，谁就能用（主角、敌人、NPC 共用一份）。
##
## 用法三步：
##   1. 角色场景里放一个挂 fsm.gd 的节点，命名 FSM
##   2. 把状态节点（脚本 extends State）挂成它的子节点，节点名就是状态名：idle / move / attack / hurt / die / chase
##   3. 角色在 _ready 里调用 start()；之后任何地方 transition_to("状态名") 就能切
##
## （类名叫 FSM、节点名也叫 FSM，和文件名 fsm.gd 对得上；
##   之前类名是 StateMachine，和文件名不一致，找文件、看报错都容易绕。）
##
## ★ 待办：状态机"我是谁"要由宿主显式赋值，不要靠猜。
##   写 Actor._ready() 时加一行：  state_machine.actor = self
##   为什么必须显式：如果靠"取当前场景根节点（owner）"来猜，
##   遇到"角色节点直接摆进关卡场景"或者用了编辑器的"可编辑子节点"，
##   owner 会变成关卡根 —— 状态机就会把整个关卡当成角色，症状是
##   "状态的 actor.velocity 改了但没人动"，报错也不明显。
##   显式赋值只有一行，换掉的是后面几个小时的排查。
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
# var actor: Actor          # 状态机属于谁（由宿主的 _ready 显式赋值，别靠猜）
# var current: State        # 当前状态
# var previous: State       # 上一个状态（需要"回到上一状态"时用）
#
# func start() -> void
# func transition_to(state_name: StringName, msg: Dictionary = {}) -> void
