extends Resource
class_name InventoryData

## 【通用逻辑层 · 一个容器】
##
## "背包"、"箱子"、"商店货架"、"装备栏"、"合成台的材料格"，
## 在代码里其实是同一个东西：一堆格子的容器。所以只写这一个类，靠参数决定它长什么样：
##   slot_count     有几格
##
## ★ "这一格能收什么"（filter）**不归容器管，归 Slot 管**。
##   原因：装备栏 6 个格子各收各的（头盔 / 胸甲 / 腿 / 戒指 / 工具 / 武器），
##   一个"容器级"的规则根本表达不了；写成"第 0 格收头盔、第 1 格收胸甲"
##   又等于把界面的布局塞进了数据里，改一次布局要改两个地方。
##   分工：容器只管"哪里放了什么"，Slot 管"我这里能放什么"。
##
## ★ 为什么是 Resource，而不是 Node：
##   容器是纯数据（第几格放了什么、放了几个）。UI 只是它的"投影"。
##   做成 Node 的话，它必须挂在场景树的某个父节点下 —— 而父节点（玩家、关卡）
##   一换场景就被销毁，背包内容会跟着一起没。做成 Resource 就没有"生命周期"这回事：
##   谁持有它，它就活多久。典型做法是交给常驻的 GameData 持有。
##   面板可以随手开关、销毁重建，数据一点都不会丢 —— 反过来，如果数据挂在 UI 节点上，
##   一关界面东西就没了，这是新手最常踩的坑。
##   附加好处：存档 = 把 slots 转成字典写文件，不用去场景树里翻节点。
##
## ★ 但 Resource 有一个必须知道的坑：**默认是共享引用**。
##   如果玩家背包和箱子都指向同一个 .tres（或者两处 preload 同一个文件），
##   那它们其实是同一份数据 —— 一个捡了东西，另一个也跟着变。
##   两种正确写法，二选一：
##     var bag := InventoryData.new()             # 代码里造（最常用）
##     var chest := chest_template.duplicate()    # 复制一份 .tres 当模板
##   什么时候才用 .tres：只用来定义"模板"（几格、默认放什么）。
##   运行时的实例，一定要 new() 或 duplicate()。
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
# var slots: Array[SlotData] = []              # 每格一个 SlotData；空格子写 null（不要造空壳对象）
#
# func add_item(item: ItemBase, count := 1) -> int    # 返回"没装下"的数量，0 表示全装下了
# func remove_item(index: int, count := 1) -> void
# func swap(a: int, b: int) -> void
# func merge(from_index: int, to_index: int) -> bool
# func transfer_to(target: InventoryData, from_index: int) -> bool
#                                             # 跨容器搬运（背包 → 箱子 / 装备栏），拖拽用
# func use_item(index: int) -> void
# func count_of(id: StringName) -> int                # 全容器里某物品的总数（合成要用）
# func is_empty(index: int) -> bool
