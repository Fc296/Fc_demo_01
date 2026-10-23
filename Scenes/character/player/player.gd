extends Actor
class_name Player

## 【角色层 · 主角】只加"只有主角才有的东西"：输入、经验、鼠标攻击。
## 敌人也有的（血量、动画、受击、死亡）一律在 Actor 里 —— 这是判断代码写哪儿的唯一标准。
## 本阶段可以一行不写：输入读在状态里（见 states/idle.gd、move.gd）。
## 完整说明见《脚本说明.md》→ Scenes/character/player/player.gd

## ——— 接口清单（待实现）———
# const SPEED := 120.0
# @onready var weapon_sprite: Sprite2D = $WeaponSprite
# @onready var state_machine: FSM = $FSM
@onready var weapon_sprite: Sprite2D = %WeaponSprite
@onready var hand_pivot: Node2D = %HandPivot
const UI_MOVE_SCALE := 0.4                    # 面板打开时的移动倍率（"边走边翻背包"）

var spawn_pos: Vector2 = Vector2.ZERO      # 出生点，复活用
var weapon_locked := false


func _ready() -> void:
	spawn_pos = global_position            # 必须在 _apply_saved_position() 之前记！
	add_to_group(&"player")          # 主角只此一只，用组标记身份
	EventBus.on_ui_blocking_changed.connect(_on_ui_blocking_changed)
	stats = GameData.player_stats
	super()
	died.connect(_on_died)
	# 穿脱装备 → 上限变了 → 让血条重画（属性面板那边是自己连的，HUD 血条只能靠广播）
	if GameData.equipment != null:
		GameData.equipment.changed.connect(refresh_health)
	_apply_saved_position()


func _process(delta: float) -> void:
	# Actor._process() 里是回血 / 回蓝。子类重写 _process 不会自动调父类，这一行必须有
	super._process(delta)

	var w := current_weapon()
	if w != null and w.hold_texture != null:
		weapon_sprite.texture = w.hold_texture
		weapon_sprite.offset = Vector2(0, +w.hold_texture.get_height() / 2.0).rotated(w.hold_angle)
		weapon_sprite.rotation = -w.hold_angle     # 贴图只负责把"天生朝向"补回来（图标朝上 → -PI）
		weapon_sprite.show()
	else:
		weapon_sprite.hide()                       # 空手：只藏贴图；"手"照旧跟着鼠标转（判定框挂在它下面）

	var mouse_dir := get_global_mouse_position() - global_position

	# ① 鼠标在左半边（2、3 象限）→ 身体朝左；右半边（1、4 象限）→ 朝右
	if not mouse_dir.is_zero_approx():
		var side := "left" if mouse_dir.x < 0.0 else "right"
		if side != last_facing:
			last_facing = side
			_sync_body_anim()

	# ② 武器朝向始终贴住鼠标（挥砍期间交给 Tween）
	if not weapon_locked:
		var aim := Actor.aim_angle(mouse_dir)
		hand_pivot.rotation = aim
		weapon_sprite.flip_h = sin(aim) > 0.0

	# ③ 武器绕人物图中心转的椭圆偏移 + 上下遮挡（挥砍期间也跟着"手"的实际角度）
	var dir := Actor.aim_vector(hand_pivot.rotation)
	var orbit_size := w.hold_orbit if w != null else Vector2.ZERO
	var orbit := Vector2(dir.x * orbit_size.x, dir.y * orbit_size.y)
	weapon_sprite.position = orbit.rotated(-hand_pivot.rotation)
	weapon_sprite.z_index = -1 if dir.y < -0.1 else 1


func _apply_saved_position() -> void:      # 读档后：站回存档点
	if not GameData.has_pending_pos:
		return
	global_position = GameData.pending_player_pos
	GameData.has_pending_pos = false       # 取走就清掉，否则下次换地图又会被摆一次
	await get_tree().process_frame         # 等一帧，新的 HUD 才把信号接上
	EventBus.on_hint_requested.emit("已读取存档")


func _on_died() -> void:
	fsm.transition_to(&"dead")


## 鼠标换边时，把"当前动作"按新朝向重播一次（walk 每物理帧会自己刷新，idle 不会）
func _sync_body_anim() -> void:
	if fsm == null or fsm.cur_sta == null:
		return
	match fsm.cur_sta.name:
		&"idle":
			play_anim(&"idle")
		&"move":
			play_anim(&"walk")
		&"attack":
			var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			play_anim(&"walk" if not dir.is_zero_approx() else &"idle")


## 面板开合（GameUi 广播）：移动降到 40%、禁攻击；走路动画一起放慢，否则会出现"脚在走、身体在滑"。
func _on_ui_blocking_changed(blocked: bool) -> void:
	move_speed_scale = UI_MOVE_SCALE if blocked else 1.0
	attack_enabled = not blocked
	anim_sprite.speed_scale = move_speed_scale



# func _physics_process(delta: float) -> void   # 输入 → velocity → 状态机切换
# func attack() -> void                          # 左键：查冷却、播动画、生成判定
# func gain_exp(value: int) -> void              # 转发给 PlayerStats
# func _on_animation_frame_changed() -> void     # 攻击动画播到判定帧才真正伤害
