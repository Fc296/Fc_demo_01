extends Node
class_name State

## 【通用逻辑层 · 状态基类】一个状态 = 一段行为（待机 / 移动 / 攻击 / 受击 / 死亡 / 追击…）。
## 只有 5 个函数可以重写，用不到的不用管；machine / actor / msg 由状态机自动赋值。
## 约定：节点名 = 状态名 = 代码里的字符串，三处必须一致（写错会静默失败）。
## 完整说明见《脚本说明.md》→ Scripts/state.gd

## ——— 接口清单（待实现）———
# var machine: FSM
# var actor: Actor
# var msg: Dictionary = {}
#
# func enter() -> void                 # 进入时一次：播动画、重置计时器、connect
# func exit() -> void                  # 离开时一次：断开信号、清理
# func update(delta: float) -> void    # 每渲染帧：计时、条件判断
# func physics_update(delta: float) -> void   # 每物理帧：移动、碰撞（会移动的都写这里）
# func handle_input(event: InputEvent) -> void  # 输入（只有要看按键的状态才用）
