extends State

var lose_timer: float = 0.0   # 跟丢计时


func enter_state(msg_in: Dictionary = {}) -> void:
	super(msg_in)
	lose_timer = 0.0  # 进入追击状态重置跟丢计时器


func physics_update(delta: float) -> void:
	var e : Enemy = actor
	var dist = e.distance_to_player()

	# 分支1：已经进入攻击距离 → 切attack
	if dist <= e.attack_range:
		fsm.transition_to("attack")
		return

	# 分支2：目标超出探测范围，开始累计跟丢时间
	if dist > e.detect_range:
		lose_timer += delta
		if lose_timer >= e.lose_sight_time:
			# 超时，切回idle放弃追击
			fsm.transition_to("idle")
		return
	else:
		# 还在探测范围内，重置丢失计时
		lose_timer = 0.0

	# 分支3：正常追击，朝玩家移动
	var player := get_tree().get_first_node_in_group(&"player") as Actor
	# 防御判空，防止null
	if player == null:
		fsm.transition_to("idle")
		return
		
	var dir: Vector2 = (player.global_position - e.global_position).normalized()
	e.face(dir)                 # 转向朝向玩家
	e.velocity = dir * e.move_speed()    # 速度统一从 Actor 出口取（base_move_speed + 装备加成）
	e.play_anim(&"chase")
	e.move_and_slide()
	

func exit_state(msg_out: Dictionary = {}) -> void:
	# 退出追击状态清零速度，防止残留移动
	actor.velocity = Vector2.ZERO
