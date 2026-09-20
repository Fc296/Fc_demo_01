extends Resource
class_name InventoryData

## 【通用逻辑层 · 容器】背包 / 箱子 / 商店货架 / 装备栏 / 锻造材料格，都是"一堆格子"。
## 分工：**容器只管"哪里放了什么"，"这一格能收什么"归 Slot 管**。
## 铁律：Resource 默认共享引用 —— 运行时必须 `InventoryData.new()`（或 .tres.duplicate()），
## 否则玩家背包和箱子会指向同一份数据。
## 完整说明（为什么用 Resource 不用 Node、为什么 filter 不放这里）见《脚本说明.md》→ Scripts/inventory_data.gd

## ——— 接口清单（待实现）———
# signal changed                            # 内容变化 → 它自己的面板重画（一对一，不进 EventBus）
# signal item_used(item: ItemBase, index: int)
#
# @export var slot_count: int = 24
# var slots: Array[SlotData] = []            # 空格子写 null
#
# func add_item(item: ItemBase, count := 1) -> int   # 返回"没装下"的数量，0 = 全装下
# func remove_item(index: int, count := 1) -> void
# func swap(a: int, b: int) -> void
# func merge(from_index: int, to_index: int) -> bool
# func transfer_to(target: InventoryData, from_index: int) -> bool   # 跨容器搬运（背包 → 箱子）
# func use_item(index: int) -> void
# func count_of(id: StringName) -> int
# func is_empty(index: int) -> bool
# func get_slot(index: int) -> SlotData
