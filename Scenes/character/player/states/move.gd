extends State

## 【状态 · 主角移动】进状态播 walk 动画；每物理帧按输入移动，松开就切回 idle。
## 移动一定写在 physics_update（物理帧固定步长），写在 update 里会随帧率漂。
## 详见《脚本说明.md》→ states

func enter_state(msg_in: Dictionary = {}):
	actor.play_anim(&"walk")
	super(msg_in)

func physics_update(delta: float):
	var input_dir: Vector2 = Input.get_vector("move_left","move_right","move_up","move_down")
	# 松开按键，没有输入切回idle
	if input_dir.is_zero_approx():
		actor.velocity = Vector2.ZERO
		fsm.transition_to(&"idle")
		return

	# 设置朝向
	actor.face(input_dir)
	# 朝向变了立刻换动画（进 move 状态时播的是"上一次的朝向"）
	actor.play_anim(&"walk")
	# 获取移动速度数值
	var spd:float = actor.move_speed()
	actor.velocity = input_dir * spd * actor.move_speed_scale   # 面板打开时 ×0.4
	# 物理帧执行移动，只调用一次move_and_slide
	actor.move_and_slide()


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and actor.attack_enabled:
		fsm.transition_to(&"attack")
