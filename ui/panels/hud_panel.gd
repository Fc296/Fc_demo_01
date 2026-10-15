extends Control
class_name HudPanel

## 【UI 层 · 常驻状态栏】目前只有血条；蓝条 / 经验条 / 金币 / 提示文字按同样套路加。
## 铁律：只听 EventBus，而且**必须按 actor 过滤**（`if not actor.is_player()`），
##       否则加第二只怪物时，怪物掉血你的血条也会掉。
## 提示文字照 my-01 的写法：自增 id 比较，只有最后一条负责隐藏。
## 完整说明见《脚本说明.md》→ ui/panels/hud_bar.gd
const DAMAGE_NUMBER := preload("res://ui/effects/damage_number.tscn")

@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var coin_label: Label = %CoinLabel
@onready var hint_label: Label = %HintLabel

var _hint_id: int = 0                       # 当前显示的是第几条提示

func _ready() -> void:
	EventBus.on_health_changed.connect(_on_health_changed)
	EventBus.on_gold_changed.connect(_on_gold_changed)
	EventBus.on_hint_requested.connect(_on_hint_requested)
	EventBus.on_damage_dealt.connect(_on_damage_dealt)
	hint_label.hide()                        # 开局不显示
	# 信号只在"值变化时"发，所以进场要自己先拉一次当前值，
	# 否则血条要等到第一次挨打才会显示正确数字
	var player := get_tree().get_first_node_in_group(&"player") as Actor
	if player != null:
		_on_health_changed(player, player.health, player.max_health())
		# 信号只在"变化时"发，所以进场先自己拉一次
	_on_gold_changed(GameData.player_stats.gold if GameData.player_stats else 0, 0)


func _on_health_changed(who: Actor, current: float, maximum: float) -> void:
	# 这是全局广播：怪物掉血也会发。不过滤的话，你砍怪一刀自己的血条也会掉
	if not who.is_player():      # who 的静态类型就是 Actor，可以直接调
		return
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "%d / %d" % [roundi(current), roundi(maximum)]


func _on_gold_changed(current: int, change: int) -> void:
	coin_label.text = "金币 %d" % current


func _on_hint_requested(text: String) -> void:
	_hint_id += 1
	var my_id := _hint_id                    # 记住"我是第几条"
	hint_label.text = text
	hint_label.show()
	# 等 1.5 秒。这期间如果又来了新提示，_hint_id 会变，就说明"现在显示的不是我了"
	await get_tree().create_timer(1.5).timeout
	if my_id == _hint_id:
		hint_label.hide()


func _on_damage_dealt(target: Actor, amount: float) -> void:
	var n := DAMAGE_NUMBER.instantiate()
	add_child(n)                                                        # 先进树，create_tween 才能在 setup 里跑
	# get_global_transform_with_canvas() = 世界坐标换算成"屏幕上的位置"（含相机），
	# 所以 HUD 不用自己算相机偏移
	n.position = target.get_global_transform_with_canvas().origin - n.size / 2.0
	# 玩家挨打显示红色，怪物挨打显示白色
	n.setup(amount, Color(1, 0.35, 0.35) if target.is_player() else Color.WHITE)
