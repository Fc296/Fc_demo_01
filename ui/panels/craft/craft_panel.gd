extends PanelBase
class_name CraftPanel

## 【UI 层 · 锻造面板】左选配方、右看需求、点打造。
## 它只读容器（数素材）、只写容器（扣素材 + 加成品）—— 打造规则全在 RecipeData 里。

var recipes: Array[RecipeData] = []     # 显示用，由 rebuild_list() 从 GameData.recipe_db 复制

@onready var recipe_list: ItemList = %RecipeList
@onready var need_label: Label = %NeedLabel
@onready var craft_button: Button = %CraftButton


func _setup() -> void:
	var bag := GameData.inventory
	bag.changed.connect(_refresh)
	rebuild_list()                                   # ← 建列表这段抽成函数
	recipe_list.item_selected.connect(_on_recipe_selected)
	craft_button.pressed.connect(_on_craft_pressed)
	_refresh()


## 重建显示列表（以后"升级解锁了新配方"就再调一次它）
func rebuild_list() -> void:
	recipes = GameData.recipe_db.duplicate()
	recipe_list.clear()                              # ← 先擦干净，否则第二次调用会重复追加
	for r in recipes:
		recipe_list.add_item(_title_of(r))
	if recipe_list.item_count > 0:
		recipe_list.select(0)


func _current() -> RecipeData:
	var picked := recipe_list.get_selected_items()
	return recipes[picked[0]] if not picked.is_empty() else null


func _title_of(r: RecipeData) -> String:
	return r.result.display_name if r != null and r.result != null else "（空配方）"


func _name_of(id: StringName) -> String:
	var item := GameData.find_item(id)
	return item.display_name if item != null else String(id)


func _on_recipe_selected(_index: int) -> void:
	_refresh()


func _refresh() -> void:
	var r := _current()
	var bag := GameData.inventory
	if r == null or bag == null:
		need_label.text = ""
		craft_button.disabled = true
		return
	var parts: Array[String] = []
	for i in mini(r.material_ids.size(), r.material_counts.size()):
		var id := r.material_ids[i]
		var have := bag.count_of(id)
		var need := r.material_counts[i]
		parts.append("%s%s %d/%d" % ["⚠" if have < need else "", _name_of(id), have, need])
	if r.gold_cost > 0:
		var gold := GameData.player_stats.gold
		parts.append("%s金币 %d/%d" % ["⚠" if gold < r.gold_cost else "", gold, r.gold_cost])
	var code := r.check(bag, GameData.player_stats.gold)
	craft_button.disabled = code != RecipeData.Result.OK
	if code == RecipeData.Result.BAG_FULL:
		parts.append("（背包放不下成品）")      # ← 补在赋值给 need_label.text 之前
	need_label.text = "需要：" + "，".join(parts)
	craft_button.disabled = r.check(bag, GameData.player_stats.gold) != RecipeData.Result.OK


func _on_craft_pressed() -> void:
	var r := _current()
	if r == null:
		return
	match GameData.craft(r):
		RecipeData.Result.OK:
			EventBus.on_hint_requested.emit("打造完成")          # 用提示条，别写 need_label（会被 _refresh 覆盖）
		RecipeData.Result.LACK_MATERIAL:
			EventBus.on_hint_requested.emit("材料不够")
		RecipeData.Result.LACK_GOLD:
			EventBus.on_hint_requested.emit("金币不够")
		RecipeData.Result.BAG_FULL:
			EventBus.on_hint_requested.emit("背包放不下成品")
		_:
			EventBus.on_hint_requested.emit("配方有问题")
	_refresh()
