extends CharacterBody2D
class_name Actor

## 【通用逻辑层 · 角色基类】会动、有血有蓝、有朝向、能播动画，兜里揣着一个状态机。
## 它不认识"玩家"：主角 / 敌人 / NPC 都继承它，子类只管"脑子"（输入 / AI / 掉落）。
##
## 属性最终值 = Actor.base_xxx（天生，@export）+ PlayerStats 的成长（可存档）+ 装备加成；
## 出口只有 get_stat() 与 max_health() / attack() 这几个函数，面板和战斗都读它。
## 场景骨架（节点名别改）：AnimSprite(AnimatedSprite2D) / Hitbox(可选) / HurtBox / FSM
## _ready 顺序（已实现）：先算 health / mana（此时 stats 必须已经注入），最后 fsm.start(self) 开状态机
## 完整说明（为什么不搬 HpComponent、上限变化时怎么处理血量）见《脚本说明.md》→ Scripts/actor.gd

## ——— 接口清单（待实现）———
signal died                                        # 一对一，留在本类
#
## ── 基础值（天生，检查器里调；怪物也靠它）──
## 基础生命上限。玩家填 0（数值全部来自 PlayerStats）；怪物填具体值。
@export var base_max_health: float = 10.0
## 基础法力上限。0 = 这个角色没有蓝条。
@export var base_max_mana: float = 0.0
## 基础移动速度（像素/秒）。
@export var base_move_speed: float = 120.0
## 基础攻击力。玩家填 0（靠三围成长）；怪物填具体值。
@export var base_attack: float = 0.0
## 基础防御力。只减物理伤害，不减元素伤害。
@export var base_defense: float = 0.0
## 攻击 / 受击结束后回到哪个状态。怪可以改成 &"chase" 直接继续追。
@export var idle_state: StringName = &"idle"
## 自身元素（光 / 岩 / 风）。它决定别人打你时的克制关系；NONE = 无属性。
@export var element: Element.Type = Element.Type.NONE
## 光抗性（%）。结算时夹在 -50 ~ +75 之间（负数 = 易伤）。
@export var base_resist_light: float = 0.0
## 岩抗性（%）。结算时夹在 -50 ~ +75 之间（负数 = 易伤）。
@export var base_resist_rock: float = 0.0
## 风抗性（%）。结算时夹在 -50 ~ +75 之间（负数 = 易伤）。
@export var base_resist_wind: float = 0.0
## 全局伤害减免（%）：物理和元素都吃，最多 50。
@export var base_damage_reduction: float = 0.0
## 判定框沿攻击方向往前伸多远（"下=0"约定）。故意默认 0：漏填的怪判定框会盖在身上，一眼看得出。
@export var base_hit_offset: Vector2 = Vector2(0, 0)
## 这只角色"攻击打到第几帧"（0 = 抬手那一帧）。怪在检查器里调；玩家用不到（玩家的前摇由武器给）
@export_range(0, 8, 1) var base_attack_hit_frame: int = 1
## true = 身体只有左右两套帧（玩家）；false = 四方向（普通怪）。
@export var two_way_body: bool = false

## ── 运行期状态 ──
var last_facing: String = "right"            # 视觉用的水平朝向（只记左右）
var stats: PlayerStats = null                      # 玩家的成长数据；怪物留空
var health: float = 0.0
var mana: float = 0.0
var last_dir: String = "down"
var move_speed_scale: float = 1.0       # 临时减速倍率：UI 面板打开时 0.4（以后的体力系统也能复用）
var attack_enabled: bool = true         # false = 不响应攻击输入（UI 面板打开时）
@onready var anim_sprite: AnimatedSprite2D = $AnimSprite
@onready var fsm: FSM = $FSM


## 世界方向 → 判定框该转的角度。
## 约定：判定形状是"按朝下绘制"的，所以下 = 0、右 = −90°（和 last_dir_angle() 同一套）
static func aim_angle(dir: Vector2) -> float:
	if dir.is_zero_approx():
		return 0.0
	return dir.angle() - PI / 2


## "下=0"的攻击角 → 世界方向。aim_angle() 的逆运算，给所有"要把角变回方向"的地方用。
static func aim_vector(aim: float) -> Vector2:
	return Vector2(0, 1).rotated(aim)


# ============ _ready 严格固定初始化顺序！ ============
func _ready() -> void:
	health = max_health()
	mana = max_mana()
	fsm.start(self)
	add_to_group(&"actors")          # 所有角色（玩家 / 怪 / 以后的 NPC）都在这组里


func is_player() -> bool:
	return is_in_group(&"player")


func _process(delta: float) -> void:
	# 没有stats直接退出
	if stats == null:
		return
	# 已经死亡退出
	if health <= 0:
		return

	# 每帧基于delta做生命、魔力自然回复
	var heal_gain = stats.health_regen * delta
	var mana_gain = stats.mana_regen * delta

	# 只有真的变了才广播：满血时每帧发一次信号是白做功
	var health_before := health
	health = minf(health + heal_gain, max_health())
	mana = minf(mana + mana_gain, max_mana())
	if health != health_before:
		EventBus.on_health_changed.emit(self, health, max_health())


## ── 汇总口（面板与战斗的唯一数据来源）──
func max_health() -> float:
	return base_max_health + (stats.health_bonus if stats != null else 0.0)

func max_mana() -> float:
	return base_max_mana + (stats.mana_bonus if stats != null else 0.0)

func move_speed() -> float:
	return base_move_speed + (stats.speed_bonus if stats != null else 0.0)

func attack() -> float:
	return base_attack + (stats.attack_bonus if stats != null else 0.0)

func defense() -> float:
	return base_defense + (stats.defense_bonus if stats != null else 0.0)


# 通用取值包装
func get_stat(stat_name: StringName) -> float:
	match stat_name:
		&"max_health": return max_health()
		&"max_mana": return max_mana()
		&"move_speed": return move_speed()
		&"attack": return attack()
		&"defense": return defense()
		_: return 0.0


## ── 行为 ──
## 我手上拿的武器（怪物没有 → null，判定框就沿用场景里配好的）
func current_weapon() -> WeaponData:
	if not is_player():
		return null
	var slot : SlotData = GameData.equipment.get_slot(EquipmentData.EquipType.WEAPON)   # 8 号格
	return slot.item as WeaponData if slot != null else null


func take_damage(pack: DamagePack, from_position := Vector2.ZERO) -> void:  # 收伤害包（物理 + 元素），不是单个数字
	# 第一步：已经死亡直接返回，不再承受伤害
	if health <= 0:
		return

	# 元素伤害计算
	var resist_val: float = resist(pack.element)
	var element_part: float = pack.element_amount * Element.multiplier(pack.element, element) * (1.0 - resist_val / 100.0)

	# 物理伤害，maxf保证不能为负数
	var physical_part: float = maxf(pack.physical - defense(), 0.0)

	# 先总和，再应用全局伤害减免damage_reduction()
	var total_before_reduction: float = element_part + physical_part
	var final_damage: float = total_before_reduction * (1.0 - damage_reduction() / 100.0)
	# 保底至少1点伤害，防止减伤堆到100完全无敌
	final_damage = maxf(final_damage, 1.0)

	health = maxf(health - final_damage, 0.0)
	EventBus.on_health_changed.emit(self, health, max_health())
	EventBus.on_damage_dealt.emit(self, final_damage)
	if health <= 0:
		died.emit()


# ============ face() 4方向朝向逻辑（坑B，输入Vector2） ============
## 当前朝向对应的旋转角度（供"形状按朝下绘制"的判定框使用）。
## 下 = 0、左 = 90°、上 = 180°、右 = -90°。Godot 里正角度是顺时针。
func last_dir_angle() -> float:
	match last_dir:
		"left":  return PI / 2
		"up":    return PI
		"right": return -PI / 2
	return 0.0                      # down


func last_dir_vector() -> Vector2:
	match last_dir:
		"up":    return Vector2.UP
		"left":  return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.DOWN 


func face(dir: Vector2) -> void:
	if dir.is_zero_approx():
		return
	# 判断横向纵向绝对值谁更大，四方向
	var abs_x:float = abs(dir.x)
	var abs_y:float = abs(dir.y)
	if abs_x > abs_y:
		if dir.x > 0:
			last_dir = "right"
		else:
			last_dir = "left"
	else:
		if dir.y > 0:
			last_dir = "down"
		else:
			last_dir = "up"
	if last_dir == "left":
		last_facing = "left"
	elif last_dir == "right":
		last_facing = "right"


# ============ play_anim() 拼接动画名（坑C：move→walk；拼接动作_朝向，先校验是否存在） ============
func play_anim(action: StringName) -> void:
	var anim_dir := last_facing if two_way_body else last_dir 
	# 动作名是"名字"，用 StringName 传进来；但动画名要和朝向拼接，所以拼完统一成 StringName
	var anim_name := StringName("%s_%s" % [action, anim_dir])
	if anim_sprite.sprite_frames == null or not anim_sprite.sprite_frames.has_animation(anim_name):
		push_error("动画缺失！名字：%s" % anim_name)
		return
	if anim_sprite.animation == anim_name and anim_sprite.is_playing():
		return
	anim_sprite.play(anim_name)


func resist(element_type: Element.Type) -> float:
	var base := 0.0
	var bonus := 0.0
	match element_type:
		Element.Type.LIGHT:
			base = base_resist_light
			bonus = stats.resist_light if stats != null else 0.0
		Element.Type.ROCK:
			base = base_resist_rock
			bonus = stats.resist_rock if stats != null else 0.0
		Element.Type.WIND:
			base = base_resist_wind
			bonus = stats.resist_wind if stats != null else 0.0
		_: 
			return 0.0     # NONE 或未知元素：不受元素抗性影响
	# 抗性区间按设计锁在 -50% ~ +75%
	return clampf(base + bonus, -50.0, 75.0)


func damage_reduction() -> float:
	return minf( base_damage_reduction + (stats.damage_reduction if stats != null else 0.0), 50.0 )


## 上限变了（穿脱装备 / 升级 / 加点 / 读档）→ 广播一次血量，让血条重画。
## 为什么非要这么一道：max_health() 是"按需算"的纯函数，光把数字算出来没有任何人知道，
##   HUD 的血条 max_value 就停在旧值 —— 实测症状是"穿上 +50 生命的铁甲，血条还是 100 / 100"。
func refresh_health() -> void:
	if stats != null:
		stats.recalc()                     # 兜底重算：不依赖"谁先 connect 到 changed"的顺序
	health = minf(health, max_health())    # 换下加血装备时，当前血量不能超过新上限
	EventBus.on_health_changed.emit(self, health, max_health())


# 治疗生命；不会超过血量上限
func heal(amount: float) -> void:
	health = minf(health + amount, max_health())
	EventBus.on_health_changed.emit(self, health, max_health())


# 消耗魔力。蓝足够就扣蓝返回true；不够返回false，不改动mana
func spend_mana(cost: float) -> bool:
	if mana < cost:
		return false
	mana -= cost
	return true


# 直接恢复魔力，不做消耗判断，上限卡住
func restore_mana(amount: float) -> void:
	mana = minf(mana + amount, max_mana())


## 被从 from_pos 方向打中 → 往反方向推开 distance 像素（0.1 秒内走完）
func apply_knockback(from_pos: Vector2, distance: float) -> void:
	if distance <= 0.0:
		return
	var dir := (global_position - from_pos).normalized()   # 背离攻击者的方向
	if dir.is_zero_approx():                                # 完全重叠时 normalized() 会出 NaN
		return
	var t := create_tween()
	t.tween_property(self, "position", position + dir * distance, 0.1)


# 当前正在播的动画一共多少秒（循环动画 = 跑完一圈的长度）
func anim_length(anim_name: StringName = &"") -> float:
	var sf := anim_sprite.sprite_frames
	var key := anim_name if anim_name != &"" else anim_sprite.animation
	if sf == null or not sf.has_animation(key):
		return 0.0
	var total := 0.0
	for i in sf.get_frame_count(key):
		total += sf.get_frame_duration(key, i)
	return total / maxf(sf.get_animation_speed(key), 0.001)


## 这个动画"第 index 帧"从第几秒开始（index 从 0 数；传超过帧数的值 = 整个动画的长度）
func anim_frame_start(index: int, anim_name: StringName = &"") -> float:
	var sf := anim_sprite.sprite_frames
	var key := anim_name if anim_name != &"" else anim_sprite.animation
	if sf == null or not sf.has_animation(key):
		return 0.0
	var speed := maxf(sf.get_animation_speed(key), 0.001)
	var n := clampi(index, 0, sf.get_frame_count(key))   # 夹一次：for 就只会累加前 n 帧
	var total := 0.0
	for i in n:
		total += sf.get_frame_duration(key, i)
	return total / speed

# func _on_stats_changed(actor: Actor) -> void        # 升级/加点/换装后重算上限
