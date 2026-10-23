extends Node

## 【Autoload · 全局游戏数据】负责"记住"，不负责"通知"（通知走 EventBus）。
## 判断标准：切换场景之后这个值还应不应该在？应该，就放这儿。
## 完整说明与玩家引用为何要注册/注销见《脚本说明.md》→ Autoload/game_data.gd

## 它持有这些"必须活过换场景"的数据对象（Resource，不是节点）：
##   player_stats / inventory / equipment（9 格容器，序号 = 部位枚举）/ item_db
## 铁律：持有 ≠ 往里面塞逻辑；player 引用只由 register/unregister 改。

## ——— 接口清单（待实现）———
# enum GameState { PLAYING, PAUSED, GAME_OVER }

## ── 存档版本 ──
## 改一次"存档结构"（加 / 删 / 改字段、换 id）就 +1，并在下面记一行原因。
## 策略：**不做逐版本迁移** —— 老档缺哪个键，就用 from_dict 里的 get(key, 默认) 补。
## 比游戏还新的档直接拒绝读（fail fast），别硬读出一份"看起来对"的数据。
##   v1 初版：stats / inventory / market / player_pos
##   v2 加装备栏（9 格容器）与 stamp（存档时间）
const SAVE_VERSION := 2
const SAVE_PATH := "user://save_%d.json"

# var game_state: GameState = GameState.PLAYING
# var save_slot: int = 0
# var unlocked_skills: Array[StringName] = []
# var play_time: float = 0.0

var _recipe_index: Dictionary = {}                   # result.id → RecipeData
var _item_index: Dictionary = {}          # id → ItemBase，find_item 从 O(n) 变 O(1)
var market: MarketData = MarketData.new()     # 市场状态要活过换场景
var pending_player_pos := Vector2.ZERO    # 读档后"该站哪儿"；先存着，等新场景里的玩家自己来取
var has_pending_pos := false              # 用 bool 判断"有没有"，别拿 ZERO 当"没有"——(0,0) 本身是合法坐标
var player_stats: PlayerStats            # 金币 / 经验 / 三围 / 装备加成 / 冷却
var inventory: InventoryData             # 玩家背包
var equipment: InventoryData             # 装备栏：9 格，序号 = EquipType 序号
## 物品总表：所有物品 .tres 都要拖进来（存档 / 掉落 / 配方靠它把 id 还原成对象）。
@export var item_db: Array[ItemBase] = []
## 新游戏时背包有多少格。
@export var inventory_slot_count: int = 36

## 开局赠送的物品 id（和 starter_item_counts 一一对应）。
@export var starter_item_ids: Array[StringName] = []
## 每项开局物品各送几个（和 starter_item_ids 一一对应）。
@export var starter_item_counts: Array[int] = []
## 所有配方 .tres（锻造面板列的就是这张表）。
@export var recipe_db: Array[RecipeData] = []

func _ready() -> void:
	_build_item_index()
	_build_recipe_index()
	setup_new_game()


func setup_new_game() -> void:   # new 出 stats/背包/装备栏，并 stats.setup(equipment)
	player_stats = PlayerStats.new()
	equipment = InventoryData.new(9)      # ← 先建装备栏
	player_stats.setup(equipment)         # ← 再交给 stats（原来是 setup(null)）
	equipment.slot_rule = func(i: int, item: ItemBase) -> bool:
		var e := item as EquipmentData
		return e != null and e.equip_type == i and e.meets(player_stats.attrs)
	inventory = InventoryData.new(inventory_slot_count)
	_give_starter_items()                 # ← 开局送的素材（内容在检查器里填）


## 卖给市场：判定 → 扣背包 + 涨存量 → 加金币
func trade_sell(item: ItemBase, count: int = 1) -> MarketData.Result:
	var code := market.check_sell(item, count, inventory)
	if code != MarketData.Result.OK:
		return code
	add_gold(market.sell(inventory, item, count))
	return MarketData.Result.OK


## 从市场买：判定 → 加背包 + 降存量 → 扣金币
func trade_buy(item: ItemBase, count: int = 1) -> MarketData.Result:
	var code := market.check_buy(item, count, inventory, player_stats.gold)
	if code != MarketData.Result.OK:
		return code
	add_gold(-market.buy(inventory, item, count))
	return MarketData.Result.OK


## 一次完整打造：校验 → 给成品 → 扣素材 → 扣金币（顺序不能反）
func craft(r: RecipeData) -> RecipeData.Result:
	if r == null:
		return RecipeData.Result.NO_RESULT
	var code := r.check(inventory, player_stats.gold)
	if code != RecipeData.Result.OK:
		return code
	inventory.add_item(r.result, r.result_count)   # check 已经确认装得下，这里不会半途而废
	r.consume(inventory)
	if r.gold_cost > 0:
		add_gold(-r.gold_cost)                     # ← 顺手修掉"打造不扣钱"
	return RecipeData.Result.OK


## 开局送的东西：两个数组一一对应，内容从检查器里填
func _give_starter_items() -> void:
	var n := mini(starter_item_ids.size(), starter_item_counts.size())
	for i in n:
		var item := find_item(starter_item_ids[i])
		if item == null:
			push_warning("开局物品：物品表里找不到 id = %s" % starter_item_ids[i])
			continue
		inventory.add_item(item, starter_item_counts[i])


func _build_item_index() -> void:
	_item_index.clear()
	for it in item_db:
		if it == null:
			push_error("物品表里有空格子")
			continue
		if _item_index.has(it.id):
			push_error("物品表 id 重复：%s" % it.id)      # 重复 id 会让读档认错东西
			continue
		_item_index[it.id] = it


func find_item(id: StringName) -> ItemBase:
	var it: ItemBase = _item_index.get(id)
	if it == null:
		push_warning("物品表里找不到 id = ⚠%s" % id)
	return it


## 改金币的唯一入口：改完 PlayerStats 再广播，界面才知道要刷新
func add_gold(value: int) -> void:
	if player_stats == null:
		return
	player_stats.add_gold(value)
	EventBus.on_gold_changed.emit(player_stats.gold, value)


func save_to_slot(slot: int = 0) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Actor
	var pos: Array = []
	var scene_path := ""
	if p != null:
		pos = [p.global_position.x, p.global_position.y]      # 用 [x, y] 存，JSON 里一眼能看懂
		scene_path = p.get_tree().current_scene.scene_file_path
	# 当前血量 / 蓝量故意不存：读档 = 重载场景 = 回满（见《框架说明》→ 存档契约 → 不存清单）
	var data := {
		"version": SAVE_VERSION,
		"stamp": Time.get_datetime_string_from_system(false, true),   # ← 新增："2026-10-03 14:30:00"
		"stats": player_stats.to_dict(),
		"inventory": inventory.to_dict(),
		"equipment": equipment.to_dict(),
		"market": market.to_dict(),
		"scene": scene_path,          # 现在只有一张图，先存着不用；以后多地图靠它决定切哪张
		"player_pos": pos,            # ← B 方案的核心
	}
	var path := SAVE_PATH % slot
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("存不了档：%s" % path)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	print("[存档] 已保存到 ", path)


func load_from_slot(slot: int = 0) -> bool:
	var path := SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		push_warning("没有存档：%s" % path)
		return false

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("读不了存档：%s" % path)
		return false
	var text := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("存档损坏：%s" % path)
		return false
	var data: Dictionary = parsed

	# 版本号：老档靠默认值补齐，比游戏还新的档直接拒（fail fast）
	# 缺 version 键 = 最老的档（v1），不是损坏
	var version := int(data.get("version", 1))
	if version > SAVE_VERSION:
		push_error("存档版本 %d 比游戏(%d)还新，拒绝读取：%s" % [version, SAVE_VERSION, path])
		return false
	if version < SAVE_VERSION:
		push_warning("存档版本 %d 偏旧，缺的键会用默认值补齐" % version)

	# ⚠️ 顺序有讲究：先把装备栏恢复好，再恢复 stats
	#    因为 player_stats.from_dict() 内部会 recalc()，而 recalc 要读装备栏
	#    find_item 是方法引用（不带括号）：数据层靠它把 id 换成对象，自己不依赖 Autoload
	inventory.from_dict(data.get("inventory", {}), find_item)
	equipment.from_dict(data.get("equipment", {}), find_item)
	market.from_dict(data.get("market", {}))
	player_stats.from_dict(data.get("stats", {}))
	player_stats.recalc()          # 兜底再算一次，确保属性和装备一致
	# 这里不广播金币：读档后 SavePanel 会 reload_current_scene()，HUD / 面板全部重建，
	# 各自在 _ready / open() 里自己拉当前值（HudPanel 已经这么做）。手动补一发只会刷到一个马上销毁的界面。
	print("[存档] 已读取 ", path)
	
	# 读档只"寄存"坐标，绝不自己去动节点。两个原因：
	#   1）Autoload 不该认识场景节点（架构铁律）
	#   2）这一刻的玩家马上要被重载销毁，现在设了也是白设
	pending_player_pos = Vector2.ZERO
	has_pending_pos = false
	var raw: Array = data.get("player_pos", [])    # 用 get + 默认值，旧存档没这个键也不会崩
	if raw.size() == 2:
		pending_player_pos = Vector2(float(raw[0]), float(raw[1]))
		has_pending_pos = true
	return true


## 看看某个槽里存了什么（只读摘要，不加载）
## 返回空字典 = 这个槽是空的
func peek_slot(slot: int) -> Dictionary:
	var path := SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_PATH % slot)


## 删掉某个槽的存档文件（全工程只有这里碰 user:// 文件）
## 返回 true = 文件确实被删掉了
func delete_slot(slot: int) -> bool:
	var path := SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		return false                        # 本来就是空的
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("删不掉存档：%s（错误码 %d）" % [path, err])
		return false
	return true


func _build_recipe_index() -> void:
	_recipe_index.clear()
	for r in recipe_db:
		if r == null or r.result == null:
			push_error("配方表里有空配方，或者没填 result")
			continue
		if _recipe_index.has(r.result.id):
			push_error("配方重复：%s" % r.result.id)
			continue
		_recipe_index[r.result.id] = r
