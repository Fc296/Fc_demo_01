extends Control
class_name StatsPanel

## 【UI 层 · 角色属性面板】
##
## 纯读面板：把 PlayerStats 里的数字摆到一行行 Label 上
## （攻击 / 防御 / 移速 / 等级 / 经验 / 金币 / 血量）。
##
## 它唯一的动作是"刷新"：
##   connect PlayerStats.stats_changed 和 gold_changed，
##   数字一变就整体重新取一遍值。
##
## ★ 这个面板里**不做任何计算**。
##   面板算出来的数字和战斗里真正用的数字很容易对不上
##   （面板 +2、实战 +3，玩家会发现，你却很难发现），
##   所以显示什么就算什么 —— 计算全部留在 PlayerStats.get_xxx() 里
##
## 新增一项属性的标准三步：
##   1. PlayerStats 里加变量，并在重算函数里算出它
##   2. 这里加一个 Label，在刷新函数里赋一次值
##   3. 完事。不需要碰别的任何地方 —— 这就是分层带来的好处
##
## ——— 接口清单 ———
# @onready var label_attack: Label = $Grid/Attack
# @onready var label_defense: Label = $Grid/Defense
# @onready var label_gold: Label = $Grid/Gold
#
# var stats: PlayerStats
#
# func refresh() -> void
# func _on_stats_changed() -> void
