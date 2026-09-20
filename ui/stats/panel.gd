extends Control
class_name StatsPanel

## 【UI 层 · 角色属性面板】
##
## 显示玩家的数值，并负责"加属性点"这一个操作。
##
## ★ 数据来源只有一个：**Actor 的汇总函数**。
##   面板不自己算公式 —— 面板算的值和战斗用的值一旦不一致，
##   就会出现"面板 +2、实战 +3"，玩家会发现，你却几乎发现不了。
##   拿值的写法固定为：`GameData.get_player().get_stat("attack")` 这类调用。
##
## ★ 刷新时机：监听 EventBus 的 stats_changed / leveled_up / exp_changed / points_changed /
##   gold_changed。它们都带"是谁"，所以第一件事是判一下是不是当前玩家。
##
## ★ 加点按钮只做一件事：调 PlayerStats.upgrade_stat("strength" / "agility" / "intelligence")。
##   返回 false（点数不够）就发 EventBus.hint_requested 提示一句，
##   不要在面板里自己扣点数、也不要自己改三围 —— 那是数据类的事。
##
## ★ 面板里要显示的项（照 my-01 的 stats_panel 清单，一项都不少）：
##   最大生命 / 最大法力 / 攻击力 / 防御力 / 闪避率 / 暴击率 / 暴击伤害 / 移动速度 / 攻击速度
##   + 等级 / 经验 / 可用属性点
##   + 三围：力量 / 敏捷 / 智力（每个后面跟一个 "+" 按钮）
##
## ⚠ 两条"暂时只显示、不参与战斗"的数值（my-01 里也是这个状态，别以为是 bug）：
##   闪避率 miss、攻击速度 att_sp —— 目前没有任何战斗判定读它们，
##   等做命中判定和攻击间隔的时候再接上。
##
## ——— 接口清单 ———
# @onready var grid: GridContainer = $Grid
#
# var player: Actor                     # 当前玩家（从 GameData.get_player() 拿，随时可能变）
#
# func refresh() -> void                # 打开面板时整体刷一遍
# func _on_stats_changed(actor: Actor) -> void
# func _on_leveled_up(actor: Actor, level: int) -> void
# func _on_exp_changed(actor: Actor, current: int, need: int) -> void
# func _on_points_changed(actor: Actor, remain: int) -> void
# func _on_gold_changed(current: int, change: int) -> void
#
## 三个加点按钮（场景里连好信号）
# func _on_strength_button_pressed() -> void      # upgrade_stat("strength")
# func _on_agility_button_pressed() -> void       # upgrade_stat("agility")
# func _on_intelligence_button_pressed() -> void  # upgrade_stat("intelligence")
