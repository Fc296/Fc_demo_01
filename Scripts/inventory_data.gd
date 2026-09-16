extends Resource
class_name InventoryData

## 【通用逻辑层 · 一个容器】
##
## "背包"、"箱子"、"商店货架"、"装备栏"、"合成台的材料格"，
## 在代码里其实是同一个东西：一堆格子的容器。所以只写这一个类，靠参数决定它长什么样：
##   slot_count     有几格
##   accept_filter  这一格"接受什么"的规则（装备栏只收装备、商店格只收钱……）
##
## ★ 为什么不是 Node，而是 Resource：
##   容器是纯数据（第几格放了什么、放了几个）。UI 只是它的"投影"。
##   做成 Resource 之后，存档 = 把这个 Resource 存下来，
##   面板可以随手销毁重建（切场景、开关界面），数据一点都不会丢。
##   反过来如果数据挂在 UI 节点上，一关界面东西就没了 —— 新手最常踩的坑。
##
## 它能做的五件事：
##   添加    能叠就叠、叠不下找空格、全满返回没装下的数量
##   移除    按格号或按 id 扣数量，扣到 0 自动清空该格
##   交换    两个格子对调（拖拽最常用）
##   合并    同 id 且目标格没满 → 叠过去（拖拽时优先合并，其次交换）
##   使用    消耗品 → 触发效果（效果本身交给 PlayerStats，容器只负责"找到并通知"）
##
## ★ 每次变化都要做的事：发 changed 信号，让 UI 自己重画。
##   绝不要在数据类里直接去操作 Slot 节点 —— 那是"投影"层的活。
##   数据变了 → 发信号 → 面板刷新，这个方向永远单向，就不会出现显示和实际不一致。
##
## ——— 接口清单 ———
# signal changed                            # 内容有任何变化都发一次，面板据此重画
# signal item_used(item: ItemBase, index: int)
#
# @export var slot_count: int = 24
# @export var accept_filter: Array             # 留空 = 什么都收，用于装备栏/商店格
# var slots: Array[Dictionary] = []            # 每格一个 {"item": ItemBase, "count": int}，空格写 {}
#
# func add_item(item: ItemBase, count := 1) -> int    # 返回"没装下"的数量，0 表示全装下了
# func remove_item(index: int, count := 1) -> void
# func swap(a: int, b: int) -> void
# func merge(from_index: int, to_index: int) -> bool
# func use_item(index: int) -> void
# func count_of(id: StringName) -> int                # 全容器里某物品的总数（合成要用）
# func is_empty(index: int) -> bool
