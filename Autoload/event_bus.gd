extends Node

## 【Autoload · 全局事件总线】
##
## 已在 project.godot 的 [autoload] 里注册为 EventBus。
## 之后任何脚本直接写 EventBus.xxx 即可用，不需要 get_node("/root/EventBus")。
##
## ★ 它解决什么问题：
##   捡到东西要更新背包 UI、受伤要更新血条、金币变化要让商店重算价格……
##   如果让这些对象互相引用，改一个名字就会牵连一串脚本。
##   约定变成一句话：谁状态变了 → 往 EventBus 发一条（emit）；
##   谁关心 → 自己在 _ready 里 connect。两边互不认识，却能保持同步。
##
## 四条使用纪律：
##   1. 只放"广播"，不放状态。EventBus 里不存数据 —— 存数据是 GameData 的事
##   2. 信号名用"已经发生的事"（过去式）：item_added、gold_changed，别用 do_xxx
##   3. 参数带上接收方需要的值，别让接收方再去 get_node 查（那又耦合回去了）
##   4. 连接只在接收方的 _ready 里做一次。到处 connect 会导致一次事件触发多遍，
##      表现为"数字涨两倍"，非常难查
##
## 什么时候不要用它：只在两个对象之间、一对一的关系，直接 connect 就好。
##   只有"跨系统"（背包 ↔ UI ↔ 战斗）的才值得广播。
##
## 计划中的信号（按系统分组）：
##   物品/背包   item_added / item_removed / inventory_changed
##   战斗        damage_dealt / actor_died
##   角色        health_changed / stats_changed / leveled_up
##   经济        gold_changed
##   流程        game_saved / game_loaded
##
## ——— 接口清单 ———
# signal item_added(item: ItemBase, count: int)
# signal item_removed(item: ItemBase, count: int)
# signal inventory_changed(who: InventoryData)
#
# signal health_changed(current: float, maximum: float)
# signal stats_changed
# signal leveled_up(level: int)
#
# signal damage_dealt(target: Actor, amount: float)
# signal actor_died(actor: Actor)
#
# signal gold_changed(amount: int)
#
# signal game_saved
# signal game_loaded
