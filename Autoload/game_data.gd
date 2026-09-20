extends Node

## 【Autoload · 全局游戏数据】负责"记住"，不负责"通知"（通知走 EventBus）。
## 判断标准：切换场景之后这个值还应不应该在？应该，就放这儿。
## 完整说明与玩家引用为何要注册/注销见《脚本说明.md》→ Autoload/game_data.gd

## 它持有这些"必须活过换场景"的数据对象（Resource，不是节点）：
##   player_stats / inventory / equipment（9 格容器，序号 = 部位枚举）/ item_db
## 铁律：持有 ≠ 往里面塞逻辑；player 引用只由 register/unregister 改。

## ——— 接口清单（待实现）———
# enum GameState { PLAYING, PAUSED, GAME_OVER }
#
# var game_state: GameState = GameState.PLAYING
# var save_slot: int = 0
# var player: Actor                        # 只由 register/unregister 改
# var player_stats: PlayerStats            # 金币 / 经验 / 三围 / 装备加成 / 冷却
# var inventory: InventoryData             # 玩家背包
# var equipment: InventoryData             # 装备栏：9 格，序号 = EquipType 序号
# var item_db: Array[ItemBase] = []        # 物品表（编辑器里把 .tres 拖进来）
# var unlocked_skills: Array[StringName] = []
# var play_time: float = 0.0
#
# func register_player(who: Actor) -> void
# func unregister_player(who: Actor) -> void
# func get_player() -> Actor                    # 内部带 is_instance_valid() 兜底
# func find_item(id: StringName) -> ItemBase    # 读档 / 掉落表 / 合成配方都靠它
# func setup_new_game() -> void                 # new 出 stats/背包/装备栏，并 stats.setup(equipment)
# func reset() -> void
# func save_to_slot(slot: int) -> void
# func load_from_slot(slot: int) -> void
