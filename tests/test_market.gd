@tool
extends McpTestSuite

## 【自动化验收 · 市场】物价公式与买卖结算。
## 跑法：让 AI 调 Godot AI 的 test_run（suite="market"），或在编辑器里用面板跑。

func suite_name() -> String:
	return "market"


func _market() -> MarketData:
	return MarketData.new()              # 默认：基准存量 20 / 系数 0.5~1.5 / 手续费 5%


## 造一个临时物品给测试用。
## 为什么不 load("res://data/items/xxx.tres")：@tool 测试跑在编辑器里，
## 非 @tool 脚本的 .tres 会变成 placeholder —— 属性读得到、方法调不了（is_stackable 一调就炸）。
func _item(id: StringName, price: int, stack: int = 99) -> ItemBase:
	var it := ItemBase.new()          # ← 直接 new，不走 load
	it.id = id
	it.sell_price = price
	it.max_stack = stack
	return it


func _bag(item: ItemBase, n: int, size: int = 10) -> InventoryData:
	var b := InventoryData.new(size)
	b.add_item(item, n)
	return b


func test_price_starts_at_base() -> void:
	var m := _market()
	var iron := _item(&"iron", 5)
	assert_eq(m.price_of(iron), iron.sell_price, "没交易过时应该等于基准价")


func test_selling_many_times_hits_floor_and_stops() -> void:
	var m := _market()
	var iron := _item(&"iron", 5)
	var b := _bag(iron, 80)
	for i in 40:
		m.sell(b, iron, 1)
	var floor_price := maxi(int(round(iron.sell_price * m.min_rate)), 1)
	assert_eq(m.price_of(iron), floor_price, "连卖 40 次之后应该跌到下限")
	for i in 5:
		m.sell(b, iron, 1)
	assert_eq(m.price_of(iron), floor_price, "到下限之后不能再跌")


func test_buying_many_times_hits_ceiling_and_stops() -> void:
	var m := _market()
	var iron := _item(&"iron", 5)
	var b := _bag(iron, 0, 40)
	for i in 30:
		m.buy(b, iron, 1)
	var ceil_price := maxi(int(round(iron.sell_price * m.max_rate)), 1)
	assert_eq(m.price_of(iron), ceil_price, "连买 30 次之后应该涨到上限")


func test_fee_is_taken() -> void:
	var m := _market()
	var iron := _item(&"iron", 5)
	var b := _bag(iron, 1)
	var got := m.sell(b, iron, 1)
	assert_eq(got, int(floor(iron.sell_price * (1.0 - m.fee_rate))), "卖出所得要扣 5% 手续费")


func test_zero_price_item_is_not_tradable() -> void:
	var m := _market()
	var claw := _item(&"claw", 0)
	var b := _bag(claw, 3)
	assert_eq(m.check_sell(claw, 1, b), MarketData.Result.NOT_TRADABLE,
		"没填 sell_price 的东西不该卖得掉（以前会把东西扣掉还不给钱）")


func test_buy_fails_when_bag_almost_full() -> void:
	var m := _market()
	var iron := _item(&"iron", 5)
	var b := InventoryData.new(1)                 # 只有 1 格
	b.add_item(iron, iron.max_stack)              # 把这格塞满
	assert_eq(m.check_buy(iron, 1, b, 9999), MarketData.Result.BAG_FULL, "塞满时应该报背包满")
	var before := b.count_of(iron.id)
	m.buy(b, iron, 1)
	assert_eq(b.count_of(iron.id), before, "买了失败之后，背包数量不能变（以前会白得一部分）")
