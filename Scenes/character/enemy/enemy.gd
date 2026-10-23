extends Actor
class_name Enemy

## 【角色层 · 敌人】只加"AI 参数 + 掉落表"，跑动/受击/死亡完全复用 Actor + State。
## 死亡流程：connect Actor.died → 抽掉落 → 生成掉落物 → queue_free（顺序反了会拿到已释放坐标）。
## 不同"性格"靠换状态节点组合，不加 if 分支。完整说明见《脚本说明.md》→ Scenes/character/enemy/enemy.gd

## ——— 接口清单（待实现）———
## 玩家进入这个距离（像素）就开始追。
@export var detect_range: float = 160.0
## 进入这个距离（像素）就开始攻击。
@export var attack_range: float = 24.0
## 跟丢目标后，过多少秒放弃追击回 idle。
@export var lose_sight_time: float = 2.0
## 死亡掉落表（.tres）。留空 = 不掉任何东西。
@export var loot_table: LootTable
## 挥完一整个攻击动画后还要"喘"多久（秒）。总攻击间隔 = 动画长度 + 它。
@export_range(0.0, 3.0, 0.05) var attack_rest: float = 0.4

var _next_attack_at: int = 0                                  # 毫秒时间戳


func _ready() -> void:
	super()
	died.connect(_on_died)


func can_attack() -> bool:
	return Time.get_ticks_msec() >= _next_attack_at



func lock_attack() -> void:
	_next_attack_at = Time.get_ticks_msec() + int(attack_rest * 1000.0)


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
