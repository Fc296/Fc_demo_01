extends Panel
class_name Slot

## 【UI 层 · 格子】背包 / 装备 / 技能 / 商店的格子都是它，靠参数决定行为。
## 只干两件事：显示（投影，自己不存数据）、按 filter 接受拖拽。
## 约定：空格子 `_get_drag_data` 返回 null；拖动期间**不动数据**（松手没落到格子就自动回原位）。
## 拖拽负载固定为 `{"container": InventoryData, "index": int}`。
## 四个拖拽函数的**可抄骨架**、以及索引为什么私有，见《脚本说明.md》→ ui/slot/slot.gd

## ——— 接口清单（待实现）———
# signal slot_clicked(index: int, button: int)      # 右键使用 / 双击使用靠这个转发
#
# @export var accept_filter: Array = []             # 留空 = 什么都收；装备格填对应部位
# var _index: int = -1                              # 私有：只由 set_source() 改（-1 = 未绑定）
# @onready var icon_rect: TextureRect = $Icon
# @onready var count_label: Label = $Count
# @onready var drag_preview: TextureRect = $DragPreview
#
# var inventory: InventoryData                       # 我显示的是哪个容器
#
# func set_source(inv: InventoryData, index: int) -> void
# func refresh() -> void                             # 按数据重画：图标 / 数量 / 空格 / 禁用态
# func _accepts(item: ItemBase) -> bool              # filter 判定，拖拽和高亮都用它
# func _get_drag_data(_at_position: Vector2) -> Variant
# func _can_drop_data(_at_position: Vector2, data: Variant) -> bool
# func _drop_data(_at_position: Vector2, data: Variant) -> void
# func _make_preview() -> Control                    # 跟随鼠标的小图标
