extends State

## 【状态 · 主角待机】进状态播 idle 动画；检测到移动输入就切到 move。
## 状态名 = 节点名 = 代码里的字符串 "idle"，三处必须一致（写错会静默失败）。
## 详见《脚本说明.md》→ states

func enter_state(msg_in: Dictionary = {}):
	# 进入空闲，播放idle动画
	actor.play_anim(&"idle")
	super(msg_in)

func update(delta: float):
	# 获取WASD归一化输入向量
	var input_dir: Vector2 = Input.get_vector("move_left","move_right","move_up","move_down")
	if not input_dir.is_zero_approx():
		# 有移动输入 → 切move状态
		fsm.transition_to(&"move")


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and actor.attack_enabled:
		fsm.transition_to(&"attack")
