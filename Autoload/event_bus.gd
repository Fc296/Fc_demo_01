extends Node

## 【Autoload · 事件总线】只放广播，不放数据（数据在 GameData）。
## 铁律：跨系统通知走这里、且**同名信号只有一个来源**；一对一关系直接 connect 类自己的信号。
## 信号归属表与完整纪律见《脚本说明.md》→ Autoload/event_bus.gd

## 信号归属（写代码时照这张表选）：
##   Actor.died / FSM.state_changed / InventoryData.changed / Slot.slot_clicked
##        → 一对一，留在各自的类里，不进总线
##   EventBus.health_changed / mana_changed / gold_changed / item_added / actor_died …
##        → 跨系统（数据 ↔ 界面 ↔ 战斗），只在总线声明一次
##   凡是"某个人身上的数值变了"，参数必须带上是哪个 Actor（否则多角色会串）。

## 参数命名约定：变化量 change ／ 一次动作的量 value ／ 个数 count ／ 当前值与上限 current, maximum
##   （delta 专指 _process 的帧间隔，别拿来当变化量）

## ——— 接口清单（待实现）———
# signal item_added(item: ItemBase, count: int)
# signal item_removed(item: ItemBase, count: int)
#        # 背包"内容变了"不走总线 —— 直接 connect 那个容器的 changed
#
signal on_health_changed(actor: Actor, current: float, maximum: float)
signal on_actor_died(actor: Actor)
signal on_gold_changed(current: int, change: int)   # current = 现在有多少（界面直接显示）；change = 这次增减多少（飘字/音效/统计）  # 只要其中一个时，另一个写 0
signal on_hint_requested(text: String)          # 弹一句提示（HUD 负责显示）
signal on_damage_dealt(target: Actor, value: float)   # 谁挨了多少（伤害数字 / 受击反馈）
# signal on_game_saved
# signal on_game_loaded
# signal on_mana_changed(actor: Actor, current: float, maximum: float)
# signal on_stats_changed(actor: Actor)          # 只说"谁的属性变了"，要值问 Actor.get_stat()
# signal on_exp_changed(actor: Actor, current: int, need: int)
# signal on_leveled_up(actor: Actor, level: int)
# signal on_points_changed(actor: Actor, remain: int)
# signal on_skill_cast(skill: SkillData)          # 施放成功（扣蓝、开冷却）才发
