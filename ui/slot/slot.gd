extends Panel
class_name Slot

## 【UI 层 · 一个格子】
##
## 背包、装备栏、技能栏、商店、箱子，格子里画的都是同一个东西 —— 所以只写这一个 Slot，
## 靠参数决定它的行为，不为每种界面各写一份。
##
## ★ 它自己"不存数据"，只干两件事：
##   1. 显示（投影）
##      面板告诉它"第 3 格是 5 个苹果"，它就去画图标和数量角标；画完就忘。
##      绝不在 Slot 里留一份 item 副本 —— 存两处必然有一天不同步
##   2. 接受规则 + 拖拽
##      filter 决定这个格子"收什么"：装备栏的武器格只收 WeaponData/EquipmentData。
##      拖进来不匹配就弹回去。★ 这是唯一防止"药水塞进头盔格"的地方，
##      所以规则写在 Slot 里，不要写成一堆 if 散在各个面板
##
## 拖拽流程（Godot 4 官方做法，三个虚函数）：
##   _get_drag_data()  被拖的格子交出"我是哪个容器的第几格"
##   _can_drop_data()  目标格子检查 filter，说不
##   _drop_data()      目标格子调 InventoryData.swap() / merge()
##   → 数据改了 → 容器发 changed → 双方面板自动重画
##
## ★ 关键认知：拖拽搬的是"第几格"，不是 ItemBase 对象本身。
##   而且要"数据先改、UI 后刷新"。反过来做（先动 UI 再改数据），
##   会出现"看起来换过来了，一存档全乱"这种最恶心的 bug
##
## ——— 接口清单 ———
# signal slot_clicked(index: int, button: int)      # 右键使用 / 双击使用都靠这个转发出去
#
# @export var accept_filter: Array = []             # 留空 = 什么都收；填 [ItemType.POTION] 之类
# @export var slot_index: int = -1
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
