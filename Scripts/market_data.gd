extends Resource
class_name MarketData

## 【通用逻辑层 · 市场】卖和买的价格、以及市场存量。
## 价格 = 基准价 × 系数，系数由"市场存量"决定：
##   你卖给市场 → 存量涨 → 价格跌；你向市场买 → 存量跌 → 价格涨。
## 系数夹在 min_rate ~ max_rate 之间，防止崩盘或暴涨。
## 和 RecipeData 一样：它只动传进来的背包，不碰金币（金币由调用方加）。

enum Result { OK, NO_ITEM, NOT_TRADABLE, LACK_ITEM, LACK_GOLD, BAG_FULL }

## 基准存量：市场里有这么多时，价格系数 = 1。
@export var base_stock: int = 20
## 价格系数下限（存量再多也不会更便宜）。
@export var min_rate: float = 0.5
## 价格系数上限（存量再少也不会更贵）。
@export var max_rate: float = 1.5
## 卖出时扣的手续费比例（0.05 = 5%）。
@export var fee_rate: float = 0.05

var stock: Dictionary = {}                # id → 市场存量（运行时数据，不填检查器）


## 能不能卖（纯判定，不改任何数据）
func check_sell(item: ItemBase, count: int, bag: InventoryData) -> Result:
	if item == null:
		return Result.NO_ITEM
	if price_of(item) <= 0:
		return Result.NOT_TRADABLE          # ★ 卖价 0 的东西不许卖，否则等于白扔
	if bag == null or bag.count_of(item.id) < count:
		return Result.LACK_ITEM
	return Result.OK


## 能不能买（纯判定，不改任何数据）
func check_buy(item: ItemBase, count: int, bag: InventoryData, gold: int) -> Result:
	if item == null:
		return Result.NO_ITEM
	if price_of(item) <= 0:
		return Result.NOT_TRADABLE
	if gold < price_of(item) * count:
		return Result.LACK_GOLD
	if not bag.can_add(item, count):        # ★ 只算不改，别拿 add_item 试塞
		return Result.BAG_FULL
	return Result.OK


## 当前单价（至少 1 块）
func price_of(item: ItemBase) -> int:
	if item == null or item.sell_price <= 0:
		return 0
	var s := int(stock.get(item.id, base_stock))
	var rate := clampf(float(base_stock) / maxf(s, 1.0), min_rate, max_rate)
	return maxi(int(round(item.sell_price * rate)), 1)


## 卖给市场：扣背包 + 涨存量，返回"该给你多少金币"（已扣手续费）
func sell(bag: InventoryData, item: ItemBase, count: int = 1) -> int:
	var n: int = mini(count, bag.count_of(item.id))     # 最多卖你有的
	if n <= 0:
		return 0
	var gross := price_of(item) * n
	var net := int(floor(gross * (1.0 - fee_rate)))
	bag.remove_item_by_id(item.id, n)                   # 见下面第 3 步
	stock[item.id] = int(stock.get(item.id, base_stock)) + n
	return maxi(net, 0)


## 从市场买：加背包 + 降存量，返回"该花多少钱"（0 = 买不了，背包放不下）
func buy(bag: InventoryData, item: ItemBase, count: int = 1) -> int:
	if bag == null or item == null or count <= 0:
		return 0
	# ⚠️ 先塞背包：装不下就直接退出，一分钱不花
	#    顺序反了会出现"钱花了、东西没拿到"
	if bag.add_item(item, count) != 0:
		return 0
	stock[item.id] = maxi(int(stock.get(item.id, base_stock)) - count, 0)
	return price_of(item) * count


func to_dict() -> Dictionary:
	# JSON 的字典键只能是字符串，所以 id 要转成 String 存
	var out := {}
	for id in stock:
		out[String(id)] = stock[id]
	return out


func from_dict(data: Dictionary) -> void:
	stock.clear()
	for key in data:
		stock[StringName(key)] = int(data[key])
