extends Control
class_name InventoryPanel

## 【UI 层 · 背包面板】
##
## "容器的投影"这句话的意思：这个脚本里不存任何物品数组，
## 它只持有**一个引用** —— inventory。界面上的每一格都是 InventoryData 当前状态画出来的。
##
## 三件事：
##   1. 开局  按 inventory.slot_count 生成 slot 场景，第 i 个 Slot 绑定 index = i
##   2. 同步  connect inventory.changed → 挨个 Slot 调 refresh()
##            ★ 数据变了就整体重画，而不是"我改这一格、顺手也改一下 UI"。
##              后者是 UI 和逻辑不同步的万恶之源
##   3. 开关  按键（toggle_inventory）显隐；打开时可以 get_tree().paused = true 暂停游戏
##
## 面板之间怎么说话：走 EventBus，不互相 get_node。
##   例如"背包里右键药水" → Slot 转发事件 → PlayerStats 加血 → 广播 stats_changed → 属性面板刷新。
##   背包面板从头到尾不知道"属性面板"这个东西存在
##
## 常见坑：面板反复 open/close 时不要重复生成格子（要判空或先清空），
##   否则每开一次界面就多一层 Slot，点一次触发好几次
##
## ——— 接口清单 ———
# @export var slot_scene: PackedScene
# @onready var grid: GridContainer = $Margin/Grid
#
# var inventory: InventoryData        # 由玩家 / 存档系统注入，不在面板里 new
#
# func open() -> void
# func close() -> void
# func toggle() -> void
# func _build_slots() -> void         # 只在第一次打开时建一次
# func _refresh_all() -> void
# func _on_inventory_changed() -> void
