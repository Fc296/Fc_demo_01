extends Resource
class_name LootTable

## 【数据层 · 掉落表】
##
## 给怪物、宝箱、木桶挂一张表；被击杀 / 被打开时，按规则抽出"掉什么、掉几个、掉多少金币"。
##
## 表里一行 = 一段内容 + 一个权重：
##   { item: ItemBase, weight: 概率权重, min_count: 最少几个, max_count: 最多几个 }
##
## 为什么用"权重"而不是"百分比"：
##   百分比要时刻保证加起来等于 100，删掉一行就得重算全部；
##   权重只比大小，加一行、删一行都不用动别人 —— 改数值时省一半的心思
##
## 两个区域都要有：
##   guaranteed      必掉区：一定会出现的东西（任务道具、保底金币、Boss 核心）
##   random_entries  随机区：抽 random_rolls 次，每次按权重决定掉什么
##
## 金币单独用 min_gold / max_gold 两个整数表示，在区间内随机取一个值。
## 金币为什么不放物品表里：金币是"玩家的数字"，不是背包里的一个格子
## （做成物品就要处理"叠满 999 怎么办"，纯属自找麻烦）
##
## 谁用它：Enemy（死亡时）、ChestPanel（打开箱子时）
## 职责边界：掉落表只"抽签"，不负责生成节点 —— 把签交给 loot_spawner 去生成实物
##
## ——— 接口清单 ———
# @export var guaranteed: Array[Dictionary] = []
# @export var random_entries: Array[Dictionary] = []
# @export var random_rolls: int = 1
# @export var min_gold: int = 0
# @export var max_gold: int = 0
#
# func roll() -> Array[Dictionary]        # 抽签结果：[{ "item": ItemBase, "count": int }]
# func roll_gold() -> int                 # 在 min_gold ~ max_gold 之间随机
# func _pick_by_weight() -> Dictionary    # 按权重轮盘赌
