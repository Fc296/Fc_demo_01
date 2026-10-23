extends Resource
class_name RecipeData

## ── 以后要加锻造功能时的扩展点（照着做，面板一行都不用改）──
##   1. 成功率 / 打造耗时：加字段 → 在 check() 里判定 → 在 GameData.craft() 里执行
##   2. 解锁条件（等级 / 图纸 / 声望）：加 required_xxx 字段，check() 多收一个参数
##   3. 一次产出多个：已有（result_count）
##   4. 配方分类 / 分页：加 category 字段，面板按它过滤
##   铁律：**判定写在 check()、执行写在 craft()、显示交给面板**

## 打造产出什么（成品物品资源）。
@export var result: ItemBase
## 一次产出几个。
@export var result_count: int = 1
## 需要哪些素材（按物品 id，和 material_counts 一一对应）。
@export var material_ids: Array[StringName] = []
## 每种素材各需要几个（和 material_ids 一一对应）。
@export var material_counts: Array[int] = []
## 打造消耗多少金币（0 = 免费）。
@export var gold_cost: int = 0

enum Result { OK, NO_RESULT, LACK_MATERIAL, LACK_GOLD, BAG_FULL }

func check(bag: InventoryData, gold: int) -> Result:
	if result == null:
		return Result.NO_RESULT
	if bag == null:
		return Result.BAG_FULL
	var n := mini(material_ids.size(), material_counts.size())
	for i in n:
		if bag.count_of(material_ids[i]) < material_counts[i]:
			return Result.LACK_MATERIAL
	if gold < gold_cost:
		return Result.LACK_GOLD
	if not bag.can_add(result, result_count):             # ★ 只问"装得下吗"，不真的塞
		return Result.BAG_FULL
	return Result.OK


## 扣材料（调用前先 check 通过）
func consume(bag: InventoryData) -> void:
	var n := mini(material_ids.size(), material_counts.size())
	for i in n:
		bag.remove_item_by_id(material_ids[i], material_counts[i])
