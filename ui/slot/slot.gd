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
##   _get_drag_data()  被拖的格子交出"我是哪个容器的第几格"（见下面的负载格式）
##   _can_drop_data()  目标格子检查 filter，说不
##   _drop_data()      目标格子调 InventoryData.swap() / merge() / transfer_to()
##   → 数据改了 → 容器发 changed → 双方面板自动重画
##
## ★ 拖拽负载的格式（三个函数之间传的就是它，先定死，别各写各的）：
##     { "container": InventoryData, "index": int }
##   为什么必须带上 container，而不只是 index：
##     背包拖到箱子 = 两个不同的容器，只给"第 3 格"的话，
##     目标格根本不知道该去谁的格子里取东西，会变成"在自己容器里找第 3 格"。
##   判断分支（写 _drop_data 时照抄）：
##     源容器 == 目标容器  → 先试 merge()，不行再 swap()
##     源容器 != 目标容器  → transfer_to()（跨容器搬运，仍然要先试合并再搬）
##   跨容器时还要额外处理"装备栏 → 玩家属性"：
##     拖进装备格 = 穿装备（改 PlayerStats），拖出 = 脱装备，见 equipment/panel.gd
##
## ★ 关键认知：拖拽搬的是"哪个容器的第几格"，不是 ItemBase 对象本身。
##   而且要"数据先改、UI 后刷新"。反过来做（先动 UI 再改数据），
##   会出现"看起来换过来了，一存档全乱"这种最恶心的 bug
##
## ★ 拖动期间不要动数据：_get_drag_data 里只"交出去"，不要顺手清空源格。
##   需求里"松手没落在格子上就回原位"就是靠这一点天然成立的 ——
##   数据还在原处，没被搬走，自然回得去，一行代码都不用写。
##
## ★ 空格子直接 return null（表示"没东西可拖"），不要返回空字典。
##   Godot 拿到 null 就不会开始拖拽，省掉一堆判空分支。
##
## ——— 接口清单 ———
# signal slot_clicked(index: int, button: int)      # 右键使用 / 双击使用都靠这个转发出去
#
# @export var accept_filter: Array = []             # 留空 = 什么都收；填 [ItemType.POTION] 之类
#                                                   # 每个格子各管各的（装备格填对应部位）
# var _index: int = -1                              # ★ 私有：只由 set_source() 改
# @onready var icon_rect: TextureRect = $Icon
# @onready var count_label: Label = $Count
# @onready var drag_preview: TextureRect = $DragPreview
#
# var inventory: InventoryData                       # 我显示的是哪个容器
#
## ★ 为什么索引是私有的、初值是 -1：
##   -1 是"哨兵值"，表示"还没绑定到任何容器的任何位置"。
##   没绑定就查不到数据 → 不会误动作。如果默认写 0，一个还没初始化的格子会悄悄操作第 0 格，
##   症状是"刚打开界面，第一格的物品就没了"。
##   私有（下划线开头）是为了堵住"两个入口"：以前 slot_index 和 set_source(inv, index)
##   都能改索引，只改一个就会出现"显示在第 5 格、数据在第 2 格"这种鬼故事。
##   代价只有一个：外部不能直接写 slot.slot_index = i，必须走 set_source()（这正是想要的效果）。
##   唯一要留意：以后若想让索引能在编辑器里手填，就别用下划线开头（Godot 的导出变量惯例不带下划线）。
##
## ★ 下面这几个函数是可直接抄的实现骨架（只改标了"按需"的地方）：
##
# func set_source(inv: InventoryData, index: int) -> void:
#     inventory = inv
#     _index = index
#     refresh()
#
# func _accepts(item: ItemBase) -> bool:
#     if item == null:
#         return false
#     if accept_filter.is_empty():
#         return true                                   # 空 = 什么都收（背包、箱子）
#     return item.type in accept_filter                 # type 是 ItemBase 上的分类枚举
#                                                       # 按需：装备格可改成
#                                                       # item.type == ItemBase.ItemType.EQUIPMENT
#                                                       # and item.equip_slot == 对应部位
#
# func _get_drag_data(_at_position: Vector2) -> Variant:
#     if inventory == null or inventory.is_empty(_index):
#         return null                                   # 空格子：不开始拖拽
#     set_drag_preview(_make_preview())                 # 按需：跟随鼠标的小图标
#     return {"container": inventory, "index": _index}  # ★ 负载格式，三个函数之间传的就是它
#
# func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
#     if inventory == null or typeof(data) != TYPE_DICTIONARY:
#         return false
#     var source: InventoryData = data["container"]
#     var moved: SlotData = source.get_slot(data["index"])
#     return moved != null and _accepts(moved.item)     # "能不能放"只有这一处规则
#
# func _drop_data(_at_position: Vector2, data: Variant) -> void:
#     var source: InventoryData = data["container"]
#     var from: int = data["index"]
#     if source == inventory:
#         if not inventory.merge(from, _index):
#             inventory.swap(from, _index)              # 同容器：先试合并，不行再交换
#     else:
#         source.transfer_to(inventory, from)           # 跨容器：搬运（内部同样先试合并）
#     # 全程没有碰过界面 —— 数据改完，容器发 changed，面板自己重画
#
# func _make_preview() -> Control:                      # 按需：拖拽时跟着鼠标的小图标
#     var p := TextureRect.new()
#     p.texture = icon_rect.texture
#     p.size = icon_rect.size
#     p.position = -p.size / 2                          # 让图标中心对准鼠标（不设会贴左上角）
#     return p
#
# func refresh() -> void                             # 按数据重画：图标 / 数量 / 空格 / 禁用态
#                                                     # （只有这一个没在上面的骨架里展开）
