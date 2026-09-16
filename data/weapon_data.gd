extends ItemBase
class_name WeaponData

## 【数据层 · 武器】
##
## WeaponData : ItemBase —— 在"一件物品"的基础上，多出"怎么打人"的数值，
## 和"拿在手里长什么样"的贴图。它依然只是数据，不会自己挥出去。
##
## 本类多出来的字段：
##   damage        这一下的基础伤害
##   cooldown      两次攻击之间的间隔（秒），越小攻速越快
##   attack_range  挥砍能打到多远（生成判定框时用）
##   hold_texture  角色手上要显示的那张图。可以和图标的 icon 是两张不同的图
##                 （背包里看小图，手上拿大图，这是像素游戏常见的做法）
##   hold_offset   贴图挂在手上时相对手部的偏移，用来对准像素
##
## 谁用它：
##   - Player 的"鼠标攻击"分支读 damage / cooldown / attack_range 决定伤害和节奏
##   - Actor 的动画帧回调把 hold_texture 挂到"手"的 Sprite 节点上
##   - 掉落、商店、合成完全把它当普通 ItemBase 处理，不需要认识"武器"这个词
##
## 设计要点：
##   武器不算伤害，武器只是"数值的容器"。真正扣血发生在 Actor.take_damage()，
##   由攻击方主动调用——这样"武器伤害"和"中毒掉血"走的是同一个入口，好排查
##
## ——— 接口清单 ———
# @export var damage: float = 1.0
# @export var cooldown: float = 0.4
# @export var attack_range: float = 24.0
# @export var hold_texture: Texture2D
# @export var hold_offset: Vector2 = Vector2.ZERO
