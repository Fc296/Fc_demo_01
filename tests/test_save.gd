@tool
extends McpTestSuite

## 【自动化验收 · 存档】数据层的"字典往返"。
## 跑法：让 AI 调 Godot AI 的 test_run（suite="save"），或在编辑器里用 Godot AI 面板跑。
## 这里只测"数据 ↔ 字典"，不碰 user:// 文件；文件层（写盘 / 坏档）靠手测。


func suite_name() -> String:
	return "save"


## 造一个临时物品。不 load .tres：@tool 测试里拿到的是 placeholder（见 test_market 的说明）
func _item(id: StringName, stack: int = 99) -> ItemBase:
	var it := ItemBase.new()
	it.id = id
	it.max_stack = stack
	return it


## 模拟 GameData.find_item：给 id、还物品；找不到返回 null
func _finder(items: Array[ItemBase]) -> Callable:
	return func(id: StringName) -> ItemBase:
		for it in items:
			if it != null and it.id == id:
				return it
		return null


func test_empty_slot() -> void:
	assert_eq(SlotData.from_dict({}, _finder([])), null, "空格子应该还是 null")


func test_slot_round_trip() -> void:
	var iron := _item(&"iron")
	var data := SlotData.new(iron, 7).to_dict()
	assert_eq(data.get("id"), "iron", "只存 id 字符串")
	assert_eq(int(data.get("count", 0)), 7)

	var back := SlotData.from_dict(data, _finder([iron]))
	assert_true(back != null)
	assert_eq(back.item.id, &"iron")
	assert_eq(back.count, 7)


func test_unknown_id_becomes_empty() -> void:
	var data := {"id": "nope", "count": 3}
	assert_eq(SlotData.from_dict(data, _finder([])), null, "找不到 id 应该当空格子，而不是崩")


func test_inventory_round_trip() -> void:
	var iron := _item(&"iron")
	var wood := _item(&"wood")
	var bag := InventoryData.new(4)
	bag.slots[0] = SlotData.new(iron, 99)
	bag.slots[3] = SlotData.new(wood, 1)
	var data := bag.to_dict()

	var loaded := InventoryData.new(4)
	loaded.from_dict(data, _finder([iron, wood]))
	assert_eq(loaded.slots[0].item.id, &"iron")
	assert_eq(loaded.slots[0].count, 99)
	assert_eq(loaded.slots[1], null, "空格子保持空格子")
	assert_eq(loaded.slots[3].item.id, &"wood")


func test_json_round_trip_keeps_ids_and_counts() -> void:
	# JSON 解析出来的数字是 float，所以 from_dict 里一律 int() —— 这条用例就是守这个
	var iron := _item(&"iron")
	var bag := InventoryData.new(2)
	bag.slots[1] = SlotData.new(iron, 5)
	var parsed = JSON.parse_string(JSON.stringify(bag.to_dict()))
	assert_true(typeof(parsed) == TYPE_DICTIONARY)

	var loaded := InventoryData.new(2)
	loaded.from_dict(parsed, _finder([iron]))
	assert_eq(loaded.slots[1].item.id, &"iron")
	assert_eq(loaded.slots[1].count, 5)


func test_market_round_trip() -> void:
	var m := MarketData.new()
	m.stock[&"iron"] = 7

	var loaded := MarketData.new()
	loaded.from_dict(JSON.parse_string(JSON.stringify(m.to_dict())))
	assert_eq(int(loaded.stock.get(&"iron", 0)), 7, "id 存成字符串再读回来要还原成 StringName")
