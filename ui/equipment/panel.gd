extends Control
class_name EquipmentPanel

## 【UI 层 · 装备面板】
##
## 结构和背包面板一模一样，区别只有两点：它要画"人形立绘 + 六个固定部位格子"，
## 而且格子有明确的接受规则。
##
## 六个格子固定，一格对应 EquipmentData.Slot 的一个枚举值：
##   头盔 / 身体 / 腿 / 戒指 / 工具 / 武器
##   （对应素材 Sprites/Equipment/placeholder_helmet|body|legs|ring|tool|weapon.png）
##
## ★ 格子用的还是同一个 Slot，只是 filter 不一样：
##   武器格只收 Slot.WEAPON 的装备。接受规则写在 Slot 里，面板不写任何 if 判断 ——
##   这样"能不能放进去"这个规则永远只有一处，改一次就全线生效
##
## 穿脱流程：
##   拖进格子 → 通知装备容器 → PlayerStats 加减属性（重新计算）→
##   广播 stats_changed → 本面板和属性面板一起刷新
##
## 装备栏在数据层就是一个 slot_count = 6 的 InventoryData，没有什么特殊容器类型。
## 想加"戒指可以戴两个"，就把它改成 7 格 —— 一行数据的事，不用改任何代码
##
## ——— 接口清单 ———
# @export var slot_scene: PackedScene
# @onready var body_sprite: TextureRect = $BodyPreview   # 人形立绘
#
# var equipment: InventoryData        # 六格容器（slot_count = 6）
# var stats: PlayerStats
# var inventory: InventoryData        # 背包，用来做"自动替换到背包"
#
# func refresh_slots() -> void
# func _on_stats_changed() -> void    # 顺便刷新立绘上的装备贴图叠加
