extends PanelBase
class_name StatsPanel

## 【UI 层 · 属性面板】显示玩家的最终数值（只读）。
## 铁律：数据来源只有 Actor 的汇总函数，面板一行公式都不许写
##       —— 否则会出现"面板 +2、实战 +3"这种几乎发现不了的错。
## 加点按钮待做（PlayerStats.upgrade_stat() 已经能用，接上按钮就行）。

## 场景里那五个 Label，都开了唯一名
@onready var hp_label: Label = %HpLabel
@onready var mp_label: Label = %MpLabel
@onready var attack_label: Label = %AttackLabel
@onready var defense_label: Label = %DefenseLabel
@onready var speed_label: Label = %SpeedLabel


func _setup() -> void:
	# 装备栏一变就重画 —— 穿脱装备是目前唯一会改数值的事
	if GameData.equipment != null:
		GameData.equipment.changed.connect(refresh)
	refresh()

func refresh() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Actor
	if player == null:
		return
	# 只读 Actor 的汇总函数 —— 面板一行业公式都不许写
	hp_label.text = "生命：%d / %d" % [roundi(player.health), roundi(player.max_health())]
	mp_label.text = "法力：%d / %d" % [roundi(player.mana), roundi(player.max_mana())]
	attack_label.text = "攻击：%d" % roundi(player.attack())
	defense_label.text = "防御：%d" % roundi(player.defense())
	speed_label.text = "移速：%d" % roundi(player.move_speed())
