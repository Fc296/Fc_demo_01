extends State

# 判定框伸多远、多宽，都写在场景里：Hitbox/CollisionShape2D 的 position 与 shape.size

@onready var hurt_box: Area2D = %HurtBox
@onready var hit_box: Area2D = %HitBox
# 从 hit_box 这个节点自己去找子节点（不要写 "%HitBox/CollisionShape2D"：唯一名后面再跟子路径，
# 在 HitBox 挂到别的父节点下面之后会解析失败）
@onready var hit_shape_node: CollisionShape2D = hit_box.get_node("CollisionShape2D")

var _hit_time := 0.06          # 没有武器时的默认值 = 现在的常量
var _recover_time := 0.2
var _move_scale := 0.0         # 0 = 站桩（第 3 小步才用它）
var _element := Element.Type.NONE
var _element_amount := 0.0
var _knockback := 0.0
var _t : float = 0.0
var _has_hit : bool = false
var _swing: Tween
var _hit_offset := Vector2.ZERO    # "往前伸"多少：每次攻击由 _apply_weapon() 填，这里只是占位
var _base_shape: Shape2D           # 场景里原本配好的判定形状（空手 / 怪 要还原它）


func enter_state(msg_in: Dictionary = {}) -> void:
	super(msg_in)
	_t = 0.0
	_has_hit = false
	_apply_weapon()
	# ① 算这次攻击的方向角（下=0 约定）：玩家朝鼠标，怪朝玩家
	var aim: float
	if actor.is_player():
		# ⚠️ State 是 Node，没有 get_global_mouse_position()；借 hit_box（Area2D 是 CanvasItem）来拿世界坐标
		aim = Actor.aim_angle(hit_box.get_global_mouse_position() - actor.global_position)
	else:
		var p := get_tree().get_first_node_in_group(&"player") as Actor
		aim = Actor.aim_angle(p.global_position - actor.global_position) if p != null else actor.last_dir_angle()
	# ② 判定框朝向：玩家的判定框挂在"手"下，跟着挥砍一起扫；怪没武器，锁在朝向上（决定 13：攻击期间不再改）
	if not actor.is_player():
		hit_box.rotation = aim
	# ③ 身体动画：玩家不播四方向 attack 帧（挥砍交给武器）；怪保留原样
	if actor.is_player():
		# 攻击也要转身：站着不动往左边砍，身体得跟着转过来
		# face() 是四方向判定，但只有左右会改 last_facing —— 正好对上两向身体
		actor.face(Actor.aim_vector(aim))
		var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		actor.play_anim(&"walk" if not dir.is_zero_approx() else &"idle")
	else:
		actor.play_anim(&"attack")        # 怪只有 chase_*/attack_* 这些帧，必须走这条
		var len := actor.anim_length()
		if len > 0.0:
			_recover_time = len
		_hit_time = actor.anim_frame_start(actor.base_attack_hit_frame)
	# ④ 让武器"挥"起来（玩家才有武器）
	_swing_weapon(aim)


func exit_state(msg_out: Dictionary = {}) -> void:
	super(msg_out)
	if actor != null and actor.is_player():
		(actor as Player).weapon_locked = false            # 收招 → 武器交还鼠标控制


func physics_update(delta: float) -> void:
	# ⚠️ 只有玩家。怪也共用这个脚本：怪没有武器（_move_scale = 0）→ 必须站桩，
	#    而且绝不能去读玩家的键盘输入（否则怪会跟着你的 WASD 走）
	if actor.is_player() and _move_scale > 0.0:
		var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir.is_zero_approx():
			actor.velocity = Vector2.ZERO
		else:
			actor.velocity = dir * actor.move_speed() * _move_scale
			actor.move_and_slide()
	else:
		actor.velocity = Vector2.ZERO        # 怪 / 空手：站桩
	_t += delta
	if not _has_hit and _t >= _hit_time:      # ← 用变量，不再用常量
		_has_hit = true
		_do_hit()
	if _t >= _recover_time:
		if actor.is_player() and not Input.get_vector("move_left", "move_right", "move_up", "move_down").is_zero_approx():
			fsm.transition_to(&"move")           # 手还按着方向键 → 直接接上走路，不闪那一帧 idle
		else:
			fsm.transition_to(actor.idle_state)


func _do_hit() -> void:
	var pack := DamagePack.make(actor.attack(), _element, _element_amount)   # ← 不再写死 NONE
	for area in hit_box.get_overlapping_areas():
		var possible_target := area.get_parent()
		if possible_target is Actor:
			var t := possible_target as Actor
			t.take_damage(pack, actor.global_position)     # ← 这个参数一直留着没人用，现在用上
			if _knockback > 0.0:
				t.apply_knockback(actor.global_position, _knockback)


func _apply_weapon() -> void:
	var _hit_angle := 0.0              # 判定框自身的偏转角（没有武器时归 0）
	if _base_shape == null:
		_base_shape = hit_shape_node.shape         # 第一次攻击时记下"场景原本的形状"，空手/怪靠它
	_hit_time = 0.06
	_recover_time = 0.2
	_move_scale = 0.0
	_element = Element.Type.NONE
	_element_amount = 0.0
	_knockback = 0.0
	_hit_offset = actor.base_hit_offset            # ← 唯一来源：玩家 (0,9) / 熊 (0,16)
	hit_shape_node.shape = _base_shape             # 先还原，再让武器覆盖（修"脱了斧子还留着斧子判定框"）
	var w : WeaponData = actor.current_weapon()
	if w != null:
		_hit_time = w.hit_time
		_recover_time = w.recover_time
		_move_scale = w.move_scale_while_attack
		_element = w.element
		_element_amount = w.element_amount
		_knockback = w.knockback
		_hit_offset = w.hit_offset
		_hit_angle = w.hit_angle                   # ← 武器给的偏转
		if w.hit_shape != null:
			hit_shape_node.shape = w.hit_shape     # 直接共用资源：没人会改它，不必 duplicate()
	# 偏移统一由"形状节点"承担 —— 它会跟着 HitBox.rotation 自动转
	hit_shape_node.position = _hit_offset
	hit_shape_node.rotation = _hit_angle           # ← 形状自己再转


func _swing_weapon(aim: float) -> void:
	if not actor.is_player():
		return                                     # 怪没有武器
	var p := actor as Player
	var w := actor.current_weapon()
	if w == null or w.hold_texture == null:
		return
	var sweep : Vector2 = w.swing_angles(aim)               # ← 起手/收招一起来
	p.weapon_locked = true
	p.hand_pivot.rotation = sweep.x
	if _swing != null and _swing.is_valid():
		_swing.kill()                              # 连砍时打断上一次，否则两个 Tween 抢角度
	_swing = create_tween()
	_swing.tween_property(p.hand_pivot, "rotation", sweep.y, w.swing_time)
