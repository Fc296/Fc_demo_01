extends Control
class_name ContainerPanel

## 【UI 层 · 容器面板】背包 / 箱子 / 商店 / 锻造材料区都是它 —— 谁的容器传进来就画谁。
## 分工：面板不存数据，只做投影；容器变了 → 容器发 changed → 这里重画。
## 用法：panel.open(player.inventory) / panel.open(chest_inventory)；商店的买卖规则压在它外面。
## 完整说明与两个坑见《脚本说明.md》→ ui/container/panel.gd

## ——— 接口清单（待实现）———
# signal closed
#
# @export var slot_scene: PackedScene
# @onready var grid: GridContainer = $Margin/Grid
# @onready var title_label: Label = $Margin/Title
#
# var container: InventoryData        # open() 注入，面板里不 new
#
# func open(target: InventoryData) -> void    # 绑定容器 → 建格子 → 显示 → connect changed
# func close() -> void                        # 隐藏 + 断开 changed（换容器前必须断旧的）
# func toggle(target: InventoryData) -> void
# func _build_slots() -> void                 # 格子数变了才重建
# func _refresh_all() -> void
# func _on_container_changed() -> void
