extends Resource
class_name PlayerStats

## 【通用逻辑层 · 玩家成长数值】三围 / 经验等级 / 属性点 / 金币 / 技能冷却。
## 只算"成长那一段"：不认识 Actor、不认识节点（依赖方向：Actor → PlayerStats）。
##
## 铁律 1：重算必须从常量出发（`damage = base_damage * (1 + 系数 * (敏捷 - 5))`），
##        绝不 `damage += 1.5` —— 后者脱装 / 洗点顺序一变，数值就悄悄漂。
## 铁律 2：触发重算只有四个点：升级、加点、穿脱装备、读档，四处都要调 recalc()。
## 铁律 3：**本类不广播任何信号**。广播需要"是谁"（Actor），而 PlayerStats 故意不认识 Actor；
##        所以由 Actor 当门面：Actor.gain_exp() / upgrade_stat() / add_gold() 转发完再广播。
## 完整说明见《脚本说明.md》→ Scripts/player_stats.gd

const BASE_ATTR := 5                      # 1 级基准属性，公式以此为原点（照 my-01 的设定）

## ── 三围与成长 ──
@export var attrs: Dictionary = {&"strength": BASE_ATTR, &"agility": BASE_ATTR, &"intelligence": BASE_ATTR}   # 三围：力量 / 敏捷 / 智力（键是"名字"，用 StringName）
@export var base_up_need_exp: int = 100    # 1 级升 2 级需要多少经验（往后每级乘 up_rate）
@export var up_rate: float = 1.2           # 每级所需经验的增长倍率，1.2 = 每级多两成
@export var up_points: int = 2             # 每升一级发几点属性点

## ── 公式基数与系数（照 my-01，检查器可调；改平衡只动这里）──
@export var base_max_hp: float = 100.0     # 生命基线：三围都是 5 时的血量
@export var base_max_mp: float = 50.0      # 法力基线
@export var base_damage: float = 20.0      # 攻击基线
@export var base_defense: float = 5.0      # 防御基线
@export var base_crit: float = 5.0         # 基础暴击率 %
@export var base_crit_dam: float = 150.0   # 暴击伤害 %（150 = 暴击打 1.5 倍）
@export var base_miss: float = 5.0         # 基础闪避率 %
@export var base_att_sp: float = 100.0     # 攻击速度 %
@export var base_mov_sp: float = 100.0     # 面板上的移速百分比；真正走路用 Actor.base_move_speed
@export var hp_per_strength: float = 0.10        # 力量每高 1 点，生命多 0.10 倍基线（+10 血）
@export var damage_per_agility: float = 0.05     # 敏捷每高 1 点，攻击多 0.05 倍基线（+1 攻）
@export var mp_per_intelligence: float = 0.10    # 智力每高 1 点，法力多 0.10 倍基线（+5 蓝）
@export var defense_per_strength: float = 0.05   # 力量每高 1 点，防御多 0.05 倍基线
@export var crit_per_agility: float = 0.05       # 敏捷每高 1 点，暴击率 +0.05%
@export var miss_per_agility: float = 0.5        # 敏捷每高 1 点，闪避 +0.5%

## ── 运行期数据 ──
var level: int = 1            # 当前等级
var exp: int = 0              # 当前这一级攒了多少经验（不是总经验）
var points_total: int = 0     # 累计拿到多少属性点
var points_used: int = 0      # 已经花掉多少属性点
var gold: int = 0             # 身上有多少金币
var equipment: InventoryData = null        # 指向 GameData.equipment（第 3 步接上）
var cooldown_until: Dictionary = {}        # SkillData → 到期时间戳（毫秒）

## ── 重算结果（Actor 汇总时读这些）──
var health_bonus: float = 0.0              # 玩家的 base_max_health 填 0，数值全部来自这里
var mana_bonus: float = 0.0         # 法力上限加成
var attack_bonus: float = 0.0       # 攻击加成
var defense_bonus: float = 0.0      # 防御加成
var speed_bonus: float = 0.0        # 移速加成
var crit: float = 0.0               # 暴击率 %
var crit_damage: float = 150.0      # 暴击伤害 %
var miss: float = 0.0               # 闪避率 %
var attack_speed: float = 100.0     # 攻击速度 %

var lifesteal: float = 0.0          # 吸血 %
var mana_regen: float = 0.0         # 每秒回魔
var health_regen: float = 0.0       # 每秒回血
var damage_reduction: float = 0.0   # 减伤 %（已锁 50 上限）
var resist_light: float = 0.0       # 光抗性 %
var resist_rock: float = 0.0        # 岩抗性 %
var resist_wind: float = 0.0        # 风抗性 %


# 接上装备栏容器，并立刻重算一次
func setup(equipment_container: InventoryData = null) -> void:
	# 换容器前先断开旧的（否则旧装备栏一变，这份 stats 也会跟着重算）
	if equipment != null and equipment.changed.is_connected(recalc):
		equipment.changed.disconnect(recalc)
	equipment = equipment_container
	if equipment != null:
		equipment.changed.connect(recalc)     # ← 穿脱装备 = 自动重算
	recalc()


func bare(stat: StringName) -> int:
	# 裸三围：装备不提供主属性，所以 attrs 就是裸值（门槛判定也用它）
	return int(attrs.get(stat, BASE_ATTR))


# 核心：从常量重新推一遍全部数值（升级 / 加点 / 穿脱装备 / 读档后都要调它）
func recalc() -> void:
	var strength := bare(&"strength")
	var agility := bare(&"agility")
	var intelligence := bare(&"intelligence")
	# ① 常量 + 三围：每次都从常量重算，绝不读上一次的结果
	health_bonus = base_max_hp * (1.0 + hp_per_strength * (strength - BASE_ATTR))
	mana_bonus = base_max_mp * (1.0 + mp_per_intelligence * (intelligence - BASE_ATTR))
	attack_bonus = base_damage * (1.0 + damage_per_agility * (agility - BASE_ATTR))
	defense_bonus = base_defense * (1.0 + defense_per_strength * (strength - BASE_ATTR))
	crit = base_crit + crit_per_agility * (agility - BASE_ATTR)
	crit_damage = base_crit_dam
	miss = base_miss + miss_per_agility * (agility - BASE_ATTR)
	attack_speed = base_att_sp
	speed_bonus = 0.0                      # 移速暂不受三围影响；想接就照上面加一行

	# 生存 / 元素：玩家的这几项只有"装备"一个来源，所以 ① 段一律从 0 起算。
	# "天生值"那一份归 Actor 的 base_resist_* / base_damage_reduction 管，别在这儿再放一份
	lifesteal = 0.0
	mana_regen = 0.0
	health_regen = 0.0
	damage_reduction = 0.0
	resist_light = 0.0
	resist_rock = 0.0
	resist_wind = 0.0

	# ② 叠加装备加成：等第 3 步（InventoryData + EquipmentData）实现后打开
	for type in EquipmentData.EquipType.values():
		var slot := equipment.get_slot(type) if equipment else null
		if slot == null:
			continue
		var equip := slot.item as EquipmentData
		if equip == null:
			continue
		health_bonus += equip.bonus_max_hp
		mana_bonus += equip.bonus_max_mp
		attack_bonus += equip.bonus_damage
		defense_bonus += equip.bonus_defense
		speed_bonus += equip.bonus_move_speed
		lifesteal += equip.bonus_lifesteal
		mana_regen += equip.bonus_mana_regen
		health_regen += equip.bonus_health_regen
		damage_reduction += equip.bonus_damage_reduction
		resist_light += equip.bonus_resist_light
		resist_rock += equip.bonus_resist_rock
		resist_wind += equip.bonus_resist_wind

	# ③ 封顶：所有累加都做完之后才夹上限（放在前面等于白夹）
	damage_reduction = minf(damage_reduction, 50.0)


## 返回"升了几级"（0 = 没升级）。广播交给 Actor。
func add_exp(value: int) -> int:
	if value <= 0:
		return 0
	exp += value
	var gained := 0
	while exp >= need_exp():
		exp -= need_exp()
		level_up()
		gained += 1
	return gained


# 升下一级需要多少经验（每级按 up_rate 递增）
func need_exp() -> int:
	return int(base_up_need_exp * pow(up_rate, level - 1))


# 升一级：等级 +1，发属性点
func level_up() -> void:
	level += 1
	points_total += up_points


# 还剩几点属性点没分配
func points_left() -> int:
	return points_total - points_used


# 花 1 点加某条三围；没点数、或属性名写错，都返回 false
func upgrade_stat(stat: StringName) -> bool:
	if points_left() <= 0 or not attrs.has(stat):
		return false
	points_used += 1
	attrs[stat] = bare(stat) + 1
	recalc()
	return true


# 加金币（传负数就是扣钱，最低扣到 0）
func add_gold(value: int) -> void:
	gold = maxi(gold + value, 0)


## ── 技能冷却（存"到期时间戳"，不用每帧 tick）──
## "蓝够不够"不在这里判断：蓝在 Actor 身上，由 Actor 把两件事合起来判断。
# 这个技能还在冷却里吗
func in_cooldown(skill: SkillData) -> bool:
	return skill != null and Time.get_ticks_msec() < int(cooldown_until.get(skill, 0))


# 开始冷却：记下"什么时候能再放"（当前时间 + 冷却秒数）
func start_cooldown(skill: SkillData) -> void:
	if skill != null:
		cooldown_until[skill] = Time.get_ticks_msec() + int(skill.cooldown * 1000.0)


# 还剩几秒冷却（给界面画遮罩用）
func cooldown_left(skill: SkillData) -> float:
	if skill == null:
		return 0.0
	var left := int(cooldown_until.get(skill, 0)) - Time.get_ticks_msec()
	return maxf(left / 1000.0, 0.0)


## ── 存档（只存基础类型；装备本身由 InventoryData 存 id）──
## 冷却（cooldown_until）故意不存：它的键是 SkillData 对象，JSON 存不了。
## 等技能系统做起来时改成存 skill.id；现在读档 = 冷却清零。
# 存档：把数值写成一堆基础类型（数字 / 字典），不写对象
func to_dict() -> Dictionary:
	return {
		"level": level, "exp": exp, "points_total": points_total, "points_used": points_used,
		"attrs": attrs.duplicate(), "gold": gold,
	}


# 读档：把存下来的值塞回来，最后重算一次
func from_dict(data: Dictionary) -> void:
	level = int(data.get("level", 1))
	exp = int(data.get("exp", 0))
	points_total = int(data.get("points_total", 0))
	points_used = int(data.get("points_used", 0))
	gold = int(data.get("gold", 0))
	var saved: Dictionary = data.get("attrs", {})
	for key in attrs.keys():
		attrs[key] = int(saved.get(key, BASE_ATTR))
	recalc()
