extends Resource
class_name LootTable

## 【数据层 · 掉落表】给怪物 / 宝箱挂一张表，按权重抽出"掉什么、掉几个、掉多少金币"。
## 为什么用权重不用百分比：加一行删一行都不用重算别人；金币单独用 min/max 两个整数表示
## （金币是玩家的数字，不是背包里的一格）。
## 职责边界：本表只"抽签"，生成实物交给 loot_spawner。详见《脚本说明.md》→ data/loot_table.gd

## ——— 接口清单（待实现）———
# @export var guaranteed: Array[Dictionary] = []      # 必掉区
# @export var random_entries: Array[Dictionary] = []  # 随机区：{item, weight, min_count, max_count}
# @export var random_rolls: int = 1
# @export var min_gold: int = 0
# @export var max_gold: int = 0
#
# func roll() -> Array[Dictionary]        # [{"item": ItemBase, "count": int}]
# func roll_gold() -> int
# func _pick_by_weight() -> Dictionary    # 轮盘赌
