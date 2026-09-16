extends Actor
class_name Player

## 【角色层 · 主角】
##
## 只加"只有主角才有的东西"。凡是敌人也有的（血量、动画、受击、死亡），一律在 Actor 里 ——
## 这条是判断代码该写哪儿的唯一标准。
##
## 主角独有的三件事：
##   1. 输入     读 Input Map（move_left/right/up/down、attack、interact、toggle_inventory），
##                转成 velocity，再驱动状态机在 idle / move 之间切
##   2. 经验     收到经验 → 交给 PlayerStats 加值；升级表现走 EventBus 广播，谁想听谁听
##   3. 鼠标攻击 左键按下 → 查手上武器的冷却 → 切到攻击状态 →
##                由攻击动画的帧回调生成 Hitbox 判定
##
## 和 Actor 的配合：
##   移动  用 actor.velocity + actor.face(方向)，朝向别自己写（Actor 里还要翻攻击框）
##   受击  完全不用管，Actor.take_damage() 已经把 hurt / die 状态接好了
##
## 经验、金币为什么先走 PlayerStats：
##   它们都是"玩家的数字"，和背包内容一样属于数据，不属于这个节点。
##   节点被销毁重建（换地图、进战斗场景）时，数字不会跟着消失
##
## ——— 接口清单 ———
# const SPEED := 120.0
# @onready var weapon_sprite: Sprite2D = $WeaponSprite
# @onready var state_machine: StateMachine = $StateMachine
#
# func _physics_process(delta: float) -> void   # 输入 → velocity → 状态机切换
# func attack() -> void                          # 鼠标左键：查冷却、播动画、生成判定
# func gain_exp(amount: int) -> void             # 转发给 PlayerStats
# func _on_animation_frame_changed() -> void     # 攻击动画播到判定帧才真正伤害，不要一按就掉血
