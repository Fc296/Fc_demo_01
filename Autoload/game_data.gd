extends Node

## 【Autoload · 全局游戏数据】
##
## 已在 project.godot 的 [autoload] 里注册为 GameData。
## EventBus 负责"通知"，GameData 负责"记住" —— 一个广播，一个持有。
##
## ★ 什么该放到这里：
##   跨场景还要活着的全局值 —— 当前存档槽、游戏状态（进行中 / 暂停 / 结算）、
##   玩家节点引用（外面到处需要找玩家）、已解锁的技能、全局设置。
##   判断标准很简单：切换场景之后，这个值还应不应该在？应该，就放这儿。
##
## ★ 什么不该放到这里：
##   角色血量（跟着角色走，放 Actor）、背包内容（放 InventoryData，本来就存得下来）、
##   只在某个场景里用的临时变量。
##   什么都往全局塞，半年后它会变成一个人人不敢动的大杂烩。
##
## ★ 但它要"持有"那些必须活过换场景的数据对象（这是关键分工）：
##     player_stats : PlayerStats      ← 金币 / 经验 / 装备加成
##     inventory    : InventoryData    ← 玩家背包
##     equipment    : InventoryData    ← 装备栏（6 格容器）
##     item_db      : Array[ItemBase]  ← 物品表：id → 物品，读档和掉落表都要用它
##   这些对象本身是 Resource（纯数据），存在这儿才不会跟着玩家节点一起被销毁。
##   注意：持有 ≠ 往里塞逻辑。GameData 只负责"我记得它们"，业务逻辑还在各自类里。
##
## ★ player 引用要用"注册 / 注销"，不要手动赋值：
##   玩家节点的生命周期和场景绑定，换地图时旧节点会被销毁，
##   此时 GameData.player 会变成一个"指向已死对象的引用"，
##   再访问就是 Invalid access，而且报错位置在别处，很难查。
##   做法：玩家在 _enter_tree 里 register_player(self)，在 _exit_tree 里 unregister_player(self)。
##   读取方再配一句 is_instance_valid() 当兜底（两个方案不是二选一，是搭配使用：
##   注册注销负责"及时清掉"，is_instance_valid 负责"万一漏了也不炸"）。
##
## 和 PlayerStats 的分工：
##   GameData     这一局游戏的全局状态（存档槽、进度、玩家引用）
##   PlayerStats  角色的战斗数值（攻击、防御、经验等级、金币）
##
## 通知纪律：这里改了值不要自己 emit 一堆信号，
##   走 EventBus 广播已知信号（例如 add_gold 里发 EventBus.gold_changed），
##   这样"谁改了值"和"谁发出的通知"只有一条路径，好追。
##
## ——— 接口清单 ———
# enum GameState { PLAYING, PAUSED, GAME_OVER }
#
# var game_state: GameState = GameState.PLAYING
# var save_slot: int = 0
# var player: Actor                       # 当前玩家节点（只由 register/unregister 改）
# var player_stats: PlayerStats           # 金币 / 经验 / 装备加成，活过换场景
# var inventory: InventoryData            # 玩家背包
# var equipment: InventoryData            # 装备栏
# var item_db: Array[ItemBase] = []       # 物品表（编辑器里把 .tres 拖进来），按 id 查
# var unlocked_skills: Array[StringName] = []
# var play_time: float = 0.0              # 从开局到现在累计的秒数（按 _process 累加）
#
# func register_player(who: Actor) -> void     # 玩家在 _enter_tree 里调
# func unregister_player(who: Actor) -> void   # 玩家在 _exit_tree 里调
# func get_player() -> Actor                   # 包一层 + is_instance_valid() 兜底
# func find_item(id: StringName) -> ItemBase   # 读档 / 掉落表 / 合成配方都靠它
# func reset() -> void                    # 重新开局：把上面的值全部恢复默认
# func save_to_slot(slot: int) -> void
# func load_from_slot(slot: int) -> void
