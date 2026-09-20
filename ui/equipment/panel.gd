extends Control
class_name EquipmentPanel

## 【UI 层 · 装备面板】比通用容器面板多两样：人形立绘、9 个固定部位格子（靠 filter 限制部位）。
## 数据来源是 GameData.equipment 那个 9 格容器；穿脱后的属性重算由 PlayerStats 负责。
## 完整说明见《脚本说明.md》→ ui/equipment/panel.gd

## ——— 接口清单（待实现）———
# @export var slot_scene: PackedScene
# @onready var body_sprite: TextureRect = $BodyPreview   # 人形立绘
#
# var equipment: InventoryData        # 9 格容器（序号 = EquipType 序号）
# var stats: PlayerStats
# var inventory: InventoryData        # 背包，用来做"自动替换到背包"
#
# func refresh_slots() -> void
# func _on_stats_changed(actor: Actor) -> void   # 顺便刷新立绘上的装备贴图叠加
