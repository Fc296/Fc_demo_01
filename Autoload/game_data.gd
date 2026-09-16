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
# var player: Actor                       # 当前玩家节点，方便别的系统找到他
# var unlocked_skills: Array[StringName] = []
# var play_time: float = 0.0              # 从开局到现在累计的秒数（按 _process 累加）
#
# func reset() -> void                    # 重新开局：把上面的值全部恢复默认
# func save_to_slot(slot: int) -> void
# func load_from_slot(slot: int) -> void
