extends State



# 每帧状态逻辑
func update(delta: float) -> void:
	# 判断：玩家进入探测范围，切换到chase状态
	var e: Enemy = actor
	if e == null:
		return
	# 先问一句"我有 chase 状态吗" —— 稻草人没拼 chase，就不会再每帧报错
	if fsm.has_state(&"chase") and e.distance_to_player() <= e.detect_range:
		fsm.transition_to(&"chase")


func enter_state(msg_in: Dictionary = {}) -> void:
	super(msg_in)
	# 进入idle：清除移动速度，站定
	actor.play_anim(&"idle")
	actor.velocity = Vector2.ZERO
