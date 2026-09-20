extends Control
class_name StatsPanel

## 【UI 层 · 属性面板】显示玩家数值 + 三个加点按钮。
## 铁律：数据来源只有 Actor 的汇总函数（`GameData.get_player().get_stat("attack")`），
##       面板不自己算 —— 否则会出现"面板 +2、实战 +3"这种几乎发现不了的错。
## 加点只调 PlayerStats.upgrade_stat()，失败就发 EventBus.hint_requested 提示。
## 完整说明见《脚本说明.md》→ ui/stats/panel.gd

## ——— 接口清单（待实现）———
# @onready var grid: GridContainer = $Grid
# var player: Actor                     # 从 GameData.get_player() 拿，随时可能变
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
