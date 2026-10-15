extends DeadState

## 【状态 · 主角死亡】进去以后玩家彻底失去控制，等 death_delay 秒（本节点在检查器里填的是 6 秒）再复活。
## 和敌人 dead.gd 的关键区别：**这里绝对不能 queue_free()**——
## 玩家一消失，Camera2D、出生点、HUD 身上所有引用全跟着废掉。
## 详见《脚本说明.md》→ states

func physics_update(delta: float) -> void:
	actor.velocity = Vector2.ZERO    # 死人站定，不给任何输入机会


func _on_death_done() -> void: 
	_revive()


func _revive() -> void:
	%HurtBox.monitorable = true
	%HitBox.monitoring = true
	var p: Player = actor
	p.global_position = p.spawn_pos      # 回出生点
	p.health = p.max_health()            # 必须手动补满！见下面说明
	EventBus.on_health_changed.emit(p, p.health, p.max_health())
	fsm.transition_to(actor.idle_state)
