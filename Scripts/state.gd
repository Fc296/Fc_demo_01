extends Node
class_name State

## 【通用逻辑层 · 状态基类】
##
## 一个状态 = 一段行为（待机 / 移动 / 攻击 / 受击 / 死亡 / 追击 / 施法……）。
## 所有角色共用这个基类：谁需要什么行为，就继承它写一个脚本。
##
## ★ 只有 5 个函数可以重写，写哪些用哪些，用不到的完全不用管：
##   enter()                  进入时执行一次（播动画、重置计时器、connect 信号）
##   exit()                   离开时执行一次（断开信号、清理，防止状态泄漏）
##   update(delta)            每个渲染帧（动画推进、计时、条件判断）
##   physics_update(delta)    每个物理帧（移动、碰撞 —— 写在会移动的状态里）
##   handle_input(event)      处理输入（只有主角这类要看按键的状态才用）
##
## 三个变量由状态机自动赋值，不用自己写：
##   machine   所属状态机
##   actor     使用者（主角 / 敌人 / NPC）—— 状态里直接写 actor.velocity 就行
##   msg       切进来时带进来的参数，例如 {"from": 伤害来源坐标}，用 msg.get("from", ...) 取
##
## ★ 命名约定：节点名 = 状态名 = 代码里的字符串，三处必须一致。
##   写错的话 transition_to 会静默失败（只在控制台 push_warning），
##   表现为"角色卡在原地不动"，很容易被误判成别的问题。
##
## 状态该多细：一个状态只做一件事。"边走边打"不是加 if 分支，
##   而是让 move 状态里检测到攻击键就切到 attack —— 组合比分支好维护
##
## ——— 接口清单 ———
# var machine: StateMachine
# var actor: Actor
# var msg: Dictionary = {}
#
# func enter() -> void
# func exit() -> void
# func update(delta: float) -> void
# func physics_update(delta: float) -> void
# func handle_input(event: InputEvent) -> void
