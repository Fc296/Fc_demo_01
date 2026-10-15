extends Actor
class_name Enemy

## 【角色层 · 敌人】只加"AI 参数 + 掉落表"，跑动/受击/死亡完全复用 Actor + State。
## 死亡流程：connect Actor.died → 抽掉落 → 生成掉落物 → queue_free（顺序反了会拿到已释放坐标）。
## 不同"性格"靠换状态节点组合，不加 if 分支。完整说明见《脚本说明.md》→ Scenes/character/enemy/enemy.gd

## ——— 接口清单（待实现）———
@export var detect_range: float = 160.0     # 多远开始追
@export var attack_range: float = 24.0      # 多近开始打
@export var lose_sight_time: float = 2.0    # 丢失目标后放弃追击的秒数
@export var loot_table: LootTable


func _ready() -> void:
	super()
	died.connect(_on_died)


func distance_to_player() -> float:
	var player := get_tree().get_first_node_in_group(&"player") as Actor
	# 判空：玩家不存在/已死亡，返回一个极大距离
	if player == null or player.health <= 0:
		return INF
	return global_position.distance_to(player.global_position)


func _on_died() -> void:
	# 掉落坐标要在销毁之前拿到 —— queue_free() 之后再读 global_position 就晚了
	var drop_pos := global_position
	if loot_table != null:
		LootSpawner.spawn(loot_table.roll(), drop_pos)      # 抽签在敌人这边做
		var gold := loot_table.roll_gold()
		if gold > 0:
			GameData.add_gold(gold)                          # 金币直接进钱包
			EventBus.on_hint_requested.emit("获得 %d 金币" % gold)
	fsm.transition_to(&"dead")
