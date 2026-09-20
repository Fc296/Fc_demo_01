extends Actor
class_name Player

## 【角色层 · 主角】只加"只有主角才有的东西"：输入、经验、鼠标攻击。
## 敌人也有的（血量、动画、受击、死亡）一律在 Actor 里 —— 这是判断代码写哪儿的唯一标准。
## 本阶段可以一行不写：输入读在状态里（见 states/idle.gd、move.gd）。
## 完整说明见《脚本说明.md》→ Scenes/character/player/player.gd

## ——— 接口清单（待实现）———
# const SPEED := 120.0
# @onready var weapon_sprite: Sprite2D = $WeaponSprite
# @onready var state_machine: FSM = $FSM
#
# func _physics_process(delta: float) -> void   # 输入 → velocity → 状态机切换
# func attack() -> void                          # 左键：查冷却、播动画、生成判定
# func gain_exp(value: int) -> void              # 转发给 PlayerStats
# func _on_animation_frame_changed() -> void     # 攻击动画播到判定帧才真正伤害
