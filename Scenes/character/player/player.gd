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
@export var hold_orbit := Vector2(9.0, 6.0)   # 武器绕角色转的椭圆：x = 左右半轴，y = 上下半轴

var spawn_pos: Vector2 = Vector2.ZERO      # 出生点，复活用
var weapon_locked := false


func _ready() -> void:
	spawn_pos = global_position            # 必须在 _apply_saved_position() 之前记！
	add_to_group(&"player")          # 主角只此一只，用组标记身份
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

	if not weapon_locked:
		var aim := Actor.aim_angle(get_global_mouse_position() - global_position)
		hand_pivot.rotation = lerp_angle(hand_pivot.rotation, aim, 0.35)
		weapon_sprite.flip_h = sin(aim) > 0.0
	# ↓ 挥砍和平时都要更新：位置跟随"手"的实际角度，前后关系也一样
	var dir := Actor.aim_vector(hand_pivot.rotation)
	var orbit := Vector2(dir.x * hold_orbit.x, dir.y * hold_orbit.y)
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



# func _physics_process(delta: float) -> void   # 输入 → velocity → 状态机切换
# func attack() -> void                          # 左键：查冷却、播动画、生成判定
# func gain_exp(value: int) -> void              # 转发给 PlayerStats
# func _on_animation_frame_changed() -> void     # 攻击动画播到判定帧才真正伤害
