extends State
class_name DeadState

## 进死亡状态后多久触发收尾：敌人销毁 / 玩家复活。
@export var death_delay: float = 1.2
var _t: float = 0.0

func enter_state(msg_in: Dictionary = {}) -> void:
	super(msg_in)
	actor.velocity = Vector2.ZERO
	%HurtBox.monitorable = false       # 别人探不到我。monitoring 是"我去探别人"，两个别搞反
	%HitBox.monitoring = false         # 我也不再去探别人
	actor.play_anim(&"dead")
	_t = 0.0

func update(delta: float) -> void:
	_t += delta
	if _t >= death_delay:
		_on_death_done()          # ← 子类只写这一件事

func _on_death_done() -> void:    # 交给子类：敌人 queue_free、玩家复活
	pass
