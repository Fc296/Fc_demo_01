extends Resource
class_name LootTable

## 【数据层 · 掉落表】给怪物 / 宝箱挂一张表：**每条掉落各掷一次骰子，互不影响**。
## 为什么不用"权重抽 N 次"：权重模型每次必中一样、掉几样是写死的；
## 独立概率才能出现"这次一次掉两样、下次空手"这种自然的掉落。
## 想让某样必掉，把它的 chance 填 1.0 就行 —— 不需要额外的"必掉区"。
## 每条规则住在 LootEntry 里（item / chance / min_count / max_count），填错类型当场报错。
## 职责边界：本表只"抽签"，生成实物交给 loot_spawner。详见《脚本说明.md》→ data/loot_table.gd

## ——— 接口清单（待实现）———
@export var min_gold: int = 0
@export var max_gold: int = 0

@export var entries: Array[LootEntry] = []      # 每一条各掷一次骰子，互不影响

## 抽签结果：[{"item": ItemBase, "count": int}]
func roll() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for e in entries:
		if e == null or e.item == null:
			continue                                # 检查器里没填完的条目直接跳过，不崩
		if randf() > e.chance:
			continue                                # 每条独立判定：可能一条都不中，也可能全中
		var hi: int = maxi(e.min_count, e.max_count)   # 防手滑把 max 填得比 min 小
		result.append({"item": e.item, "count": randi_range(e.min_count, hi)})
	return result


## 这只怪掉多少金币（0 = 不掉）
func roll_gold() -> int:
	var hi := maxi(min_gold, max_gold)
	return randi_range(min_gold, hi) if hi > 0 else 0
