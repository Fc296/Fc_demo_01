extends Node
class_name PlayerStats

## 【通用逻辑层 · 角色属性汇总 + 金币】
##
## 背包里放的是"物品"，这里是"物品生效之后，角色身上剩下的数字"。
## 一件装备穿上时把加成加进来，脱下时减回去。
##
## ★ 属性计算唯一正确的写法：基础值 + 所有加成，每次重算。
##     base_attack 5.0，戴上 +3 的剑 → 8.0；再戴上 +2 的戒指 → 10.0。
##   不要在东一件西一件时直接往最终值上 += ——那样脱装顺序一变，数值就会漂，
##   而且会漂得悄无声息（这是数值类 bug 的头号来源）。
##
## 负责：攻击 / 防御 / 移速等基础属性、经验与等级、金币
## 不负责：显示（面板来读）、存盘（存档系统来读）—— 它只管算
##
## 金币为什么在这里，而不是做成一个物品：
##   金币是"玩家的一个数字"，不是背包里的一格。
##   做成物品就要处理"叠满 999 怎么办、钱包装不下怎么办"，纯属自找麻烦。
##   将来要做"钱袋"道具，那也只是个道具，点开时给 gold += N 而已。
##
## 和 GameData 的分工（很容易搞混）：
##   PlayerStats  角色自己的战斗数值（攻击/防御/经验等级）
##   GameData     属于这一局游戏、不属于某个角色的东西（存档槽、进度标志位）
##   以后做多角色切换时，PlayerStats 会跟着当前角色换，GameData 不会
##
## ——— 接口清单 ———
# signal stats_changed                    # 任何属性变化后发一次，属性面板据此刷新
# signal gold_changed(amount: int)
# signal leveled_up(level: int)
#
# @export var base_attack: float = 5.0
# @export var base_defense: float = 0.0
# @export var base_speed: float = 120.0
#
# var gold: int = 0
# var level: int = 1
# var exp: int = 0
# var equipped: Dictionary = {}           # EquipmentData.Slot -> EquipmentData
#
# func equip(item: EquipmentData) -> void
# func unequip(slot: EquipmentData.Slot) -> void
# func add_gold(amount: int) -> void
# func add_exp(amount: int) -> void
# func get_attack() -> float              # 基础 + 全部装备加成
# func get_defense() -> float
# func get_speed() -> float
# func _recalc() -> void                  # 统一重算并 emit stats_changed
