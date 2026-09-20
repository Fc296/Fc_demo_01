extends Control
class_name ContainerPanel

## 【UI 层 · 容器面板（背包 / 箱子 / 商店 / 锻造材料区 都用它）】
##
## 这个类是从原来的"背包面板 + 箱子面板"合并来的。
## 理由很简单：InventoryData 本身就只是一堆格子，**背包和箱子在数据层里没有任何区别**，
## 区别只在"传进来的是谁的容器"。所以只留一个面板类：给它一个 InventoryData，它就把容器画出来。
##
## 分工（一句话）：**面板不存数据，只做投影**。
##   var container : InventoryData   ← 由外面注入（玩家背包 / 宝箱 / 商店货架 / 锻造材料格）
##   容器变了 → 容器发 changed → 本面板重画
##   拖动格子 → Slot 直接改容器 → 又回到上面那条回路
##   面板从头到尾不知道"东西从哪来、要到哪去"
##
## 三种用法（都不用改这个文件）：
##   背包   panel.open(player.inventory)
##   箱子   panel.open(chest_inventory)        # 换个容器实例而已
##   商店   panel.open(shop_inventory)，再在外面压一层买卖规则
##
## ★ 商店为什么不在这个类里处理：
##   拖过去不只是换位置，还要查价格、扣金币、判断买不起 —— 那是压在"容器"之上的规则。
##   塞进这里，这个通用面板就得认识"金币"，从此只能当商店用。
##
## 常见坑：
##   1. 反复 open/close 不要重复生成格子（先清空再建，或只建一次），
##      否则每开一次界面就多一层 Slot，点一次触发好几次
##   2. open() 换容器时必须先把**旧容器**的 changed 断开，
##      不然旧容器一变，新面板也跟着重画（表现为"打开背包，箱子里的图标乱跳"）
##
## ——— 接口清单 ———
# signal closed
#
# @export var slot_scene: PackedScene
# @onready var grid: GridContainer = $Margin/Grid
# @onready var title_label: Label = $Margin/Title      # 按需：显示"背包"/"箱子"
#
# var container: InventoryData        # 我当前画的是哪个容器（open() 注入，面板里不 new）
#
# func open(target: InventoryData) -> void    # 绑定容器 → 建格子 → 显示 → connect changed
# func close() -> void                        # 隐藏 + 断开 changed
# func toggle(target: InventoryData) -> void
# func _build_slots() -> void                 # 格子数变了才重建（背包 24 格、装备 6 格）
# func _refresh_all() -> void
# func _on_container_changed() -> void
