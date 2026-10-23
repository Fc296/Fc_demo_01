extends PanelBase
class_name MarketPanel

## 【UI 层 · 拍卖行面板】卖素材换金币、花金币买素材。
## 价格和存量全在 MarketData 里算；这里只负责"显示 + 把买卖串起来"。

## 这个市场上架哪些物品（按物品 id，检查器里填）。
@export var tradable_ids: Array[StringName] = []

@onready var market_list: ItemList = %MarketList
@onready var info_label: Label = %InfoLabel
@onready var sell_button: Button = %SellButton
@onready var buy_button: Button = %BuyButton


func _setup() -> void:
	GameData.inventory.changed.connect(_refresh)
	EventBus.on_gold_changed.connect(func(_c, _d): _refresh())   # 金币变了也重画
	for id in tradable_ids:
		market_list.add_item(_title_of(id))
	market_list.item_selected.connect(func(_i): _refresh())
	sell_button.pressed.connect(_on_sell_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	if market_list.item_count > 0:
		market_list.select(0)
	_refresh()


func _current() -> ItemBase:
	var picked := market_list.get_selected_items()
	return GameData.find_item(tradable_ids[picked[0]]) if not picked.is_empty() else null


func _title_of(id: StringName) -> String:
	var item := GameData.find_item(id)
	return item.display_name if item != null else String(id)


func _refresh() -> void:
	var item := _current()
	var bag := GameData.inventory
	if item == null or bag == null:
		info_label.text = ""
		return
	var unit := GameData.market.price_of(item)
	var gold := GameData.player_stats.gold
	var mark := "" if gold >= unit else "（⚠金币不够）"
	info_label.text = "你有 %d 个 · 市价 %d 金%s" % [bag.count_of(item.id), unit, mark]
	sell_button.disabled = GameData.market.check_sell(item, 1, bag) != MarketData.Result.OK
	buy_button.disabled = GameData.market.check_buy(item, 1, bag, gold) != MarketData.Result.OK


func _on_sell_pressed() -> void:
	var item := _current()
	if item == null:
		return
	match GameData.trade_sell(item, 1):
		MarketData.Result.OK:            EventBus.on_hint_requested.emit("卖出成功")
		MarketData.Result.LACK_ITEM:     EventBus.on_hint_requested.emit("你没有这个")
		MarketData.Result.NOT_TRADABLE:  EventBus.on_hint_requested.emit("这东西市场不收")
		_:                               EventBus.on_hint_requested.emit("卖不了")


func _on_buy_pressed() -> void:
	var item := _current()
	if item == null:
		return
	match GameData.trade_buy(item, 1):
		MarketData.Result.OK:            EventBus.on_hint_requested.emit("买好了")
		MarketData.Result.LACK_GOLD:     EventBus.on_hint_requested.emit("金币不够")
		MarketData.Result.BAG_FULL:      EventBus.on_hint_requested.emit("背包放不下")
		MarketData.Result.NOT_TRADABLE:  EventBus.on_hint_requested.emit("这东西市场不卖")
		_:                               EventBus.on_hint_requested.emit("买不了")
