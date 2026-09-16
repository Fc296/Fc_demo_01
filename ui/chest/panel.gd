extends Control
class_name ChestPanel

## 【UI 层 · 箱子 / 商店这类"外部容器"面板】
##
## 它和背包面板长得几乎一样，区别只有一个：
## 它显示的不是玩家的背包，而是"别人的容器"。
##
## ★ 因为 InventoryData 本来就只是个容器，箱子和背包在数据层里**根本没有区别** ——
##   所以同一个面板既能开宝箱、也能开商店货架、也能开合成台的材料格，
##   区别只是传进来的 InventoryData 不一样。
##   不要为"箱子"再写一个类，那是白干一遍。
##
## 打开方式：把"对面那个容器"塞给自己
##   chest_panel.show_for(chest_inventory)
## 玩家在左右两边拖东西 = 两个 InventoryData 之间搬东西，
## Slot 的拖拽逻辑一行都不用改，因为它本来就只认"容器 + 第几格"
##
## 商店的买卖是唯一需要额外处理的地方：
##   拖过去时不只是换位置，还要查价格、扣金币、判断买不起。
##   这是压在"容器"之上的一层规则，写在商店管理脚本里，
##   不要塞进 Slot（否则 Slot 就要认识"金币"了，破坏它的通用性）
##
## ——— 接口清单 ———
# @export var slot_scene: PackedScene
# @onready var grid: GridContainer = $Margin/Grid
#
# var chest: InventoryData        # 对面的容器
# var inventory: InventoryData    # 玩家背包
#
# func show_for(container: InventoryData) -> void
# func close() -> void
# func _build_slots() -> void
# func _refresh_all() -> void
