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
##   5. ★ 同名信号只有一个来源：**跨系统通知一律走 EventBus，类自己不再重复声明**。
##      也就是说 Actor 里不写 health_changed、PlayerStats 里不写 gold_changed，
##      只在值变化时调用 EventBus.xxx.emit()。
##      为什么这条最重要：一旦"类自己的信号"和"EventBus 的信号"同时存在，
##      界面连了 A、数据发的是 B，表现就是"数字永远不刷新"，
##      而且两边代码单独看都没错，非常难查。
##      判断标准：这一对关系是"一对一"（父传子、自己传给自己），还是"跨系统"？
##        一对一  → 直接 connect 类自己的信号（例如 Actor.died 给 Enemy 用）
##        跨系统  → 只走 EventBus（例如血量变化要给 HUD 用）
##      这条规则对 my-01 和 my_02 两个工程同时生效 —— 老工程里
##      Player 自己 emit 血蓝信号、EventBus 也有同名信号，就是典型的"两个来源"。
##      （补充：my-01 现在只是参考样本，不用去改它；规则以 my_02 为准。）
##
## 什么时候不要用它：只在两个对象之间、一对一的关系，直接 connect 就好。
##   只有"跨系统"（背包 ↔ UI ↔ 战斗）的才值得广播。
##
## ★ 信号归属表（照着写就不会出现"两个来源"）：
##
##   信号                          归谁                谁监听
##   Actor.died                    类自己（一对一）     敌人的死亡处理、掉落、成就
##   FSM.state_changed             类自己（一对一）     调试打印、角色自己
##   InventoryData.changed         类自己（一对一）     它自己的那个面板
##   Slot.slot_clicked             类自己（一对一）     它所属的面板
##   ------------------------------------------------ 以上都不进 EventBus
##   EventBus.health_changed       总线（跨系统）       HUD / 血条（自己判断是不是当前玩家）
##   EventBus.gold_changed         总线（跨系统）       金币显示、商店价格、任务统计
##   EventBus.item_added/removed   总线（跨系统）       任务、成就、统计
##   EventBus.actor_died           总线（跨系统）       掉落、成就、关卡进度
##
## ★ 为什么"背包变了"不放进 EventBus（这里改过一次）：
##   容器本身就是数据对象，谁关心哪个容器，直接 connect 那个容器的 changed 就行。
##   挂到总线上反而要每个监听方写一句 if (who == 我的背包)，等于把一对一伪装成广播，
##   还容易出现"面板刷新两次"。所以 EventBus 里没有 inventory_changed 这个信号。
##   （item_added / item_removed 保留 —— 它们是给任务、成就这类真正的跨系统听众用的；
##     界面刷新请不要用它们，用容器的 changed。）
##
## 计划中的信号（按系统分组）：
##   物品/背包   item_added / item_removed
##   战斗        damage_dealt / actor_died
##   角色        health_changed / mana_changed / stats_changed / exp_changed / leveled_up / points_changed
##   经济        gold_changed
##   流程        game_saved / game_loaded
##   提示        hint_requested（屏幕中上方一条短提示，例如"属性点不足"）
##
## ★ 多角色相关：凡是"某个人身上的数值变了"，参数里**必须带上是哪个人**。
##   不带的话，加第二只怪物时血条就会串（玩家受伤，怪物的血条也跟着掉）。
##   监听方自己判断"这个 actor 是不是我在意的那个"。
##
## ——— 接口清单 ———
# signal item_added(item: ItemBase, count: int)
# signal item_removed(item: ItemBase, count: int)
#
# （背包/容器"内容变了"不走总线 —— 见上面"为什么背包变了不放进 EventBus"，
#   直接 connect 容器的 changed 信号。）
#
# signal health_changed(actor: Actor, current: float, maximum: float)
# signal mana_changed(actor: Actor, current: float, maximum: float)
# signal stats_changed(actor: Actor)          # 只广播"谁的属性变了"，要值去问 Actor.get_stat()
# signal exp_changed(actor: Actor, current: int, need: int)
# signal leveled_up(actor: Actor, level: int)
# signal points_changed(actor: Actor, remain: int)
# signal skill_cast(skill: SkillData)          # 施放成功（扣完蓝、开完冷却）才发
#
# signal damage_dealt(target: Actor, value: float)
# signal actor_died(actor: Actor)
#
# signal hint_requested(text: String)          # 谁想弹一句提示就调它（HUD 负责显示）
#
# signal gold_changed(current: int, change: int = 0)
#        # current = 现在有多少（界面直接显示它，不用自己再算）
#        # change  = 这一次增减了多少（可正可负）：飘字"+12"、音效大小、任务统计用
#        # 只要其中一个是你要的，另一个写 0 即可；不需要飘字就只传 current
#        #
#        # ★ 参数命名约定 —— "变化量"这一类只保留 change 一个词，不再用近义词：
#        #     current   当前值（界面直接显示它，不用自己再算）
#        #     maximum   上限
#        #     change    ★相对上一次的增减量，可正可负（飘字 / 音效 / 任务统计）
#        #     value     一次动作造成的量（伤害值、回复量）
#        #     count     个数（物品数量、掉落个数）
#        #   为什么不用 delta：它在 Godot 里专指 _process(delta) 的"帧间隔秒数"，
#        #   在 _process 里读到这个信号时两个 delta 会撞在一起，极容易看错。
#        #   value / count 不是"变化量"，是"这次发生的量"和"个数"，语义不同所以保留；
#        #   count 不建议并进 value（"个数"和"数值"混进同一个词，读起来更费劲）。
#        #   注意：value 在 Godot 的 UI 里被 Range 系列占用（ProgressBar.value / Slider.value），
#        #   在面板脚本里同时用到两者时，别把血量数值和进度条数值写混。
#
# signal game_saved
# signal game_loaded
