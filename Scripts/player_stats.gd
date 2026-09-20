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
@export var attrs: Dictionary = {"strength": BASE_ATTR, "agility": BASE_ATTR, "intelligence": BASE_ATTR}
@export var base_up_need_exp: int = 100
@export var up_rate: float = 1.2
@export var up_points: int = 4

## ── 公式基数与系数（照 my-01，检查器可调；改平衡只动这里）──
@export var base_max_hp: float = 100.0
@export var base_max_mp: float = 50.0
@export var base_damage: float = 20.0
@export var base_defense: float = 5.0
@export var base_crit: float = 5.0
@export var base_crit_dam: float = 150.0
@export var base_miss: float = 5.0
@export var base_att_sp: float = 100.0
@export var base_mov_sp: float = 100.0     # 面板上的移速百分比；真正走路用 Actor.base_move_speed
@export var hp_per_strength: float = 0.10
@export var damage_per_agility: float = 0.05
@export var mp_per_intelligence: float = 0.10
@export var defense_per_strength: float = 0.05
@export var crit_per_agility: float = 0.05
@export var miss_per_agility: float = 0.5

## ── 运行期数据 ──
var level: int = 1
var exp: int = 0
var points_total: int = 0
var points_used: int = 0
var gold: int = 0
var equipment: InventoryData = null        # 指向 GameData.equipment（第 3 步接上）
var cooldown_until: Dictionary = {}        # SkillData → 到期时间戳（毫秒）

## ── 重算结果（Actor 汇总时读这些）──
var health_bonus: float = 0.0              # 玩家的 base_max_health 填 0，数值全部来自这里
var mana_bonus: float = 0.0
var attack_bonus: float = 0.0
var defense_bonus: float = 0.0
var speed_bonus: float = 0.0
var crit: float = 0.0
var crit_damage: float = 150.0
var miss: float = 0.0
var attack_speed: float = 100.0


func setup(equipment_container: InventoryData = null) -> void:
	equipment = equipment_container
	recalc()


func bare(stat: StringName) -> int:
	# 裸三围：装备不提供主属性，所以 attrs 就是裸值（门槛判定也用它）
	return int(attrs.get(stat, BASE_ATTR))


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

	# ② 叠加装备加成：等第 3 步（InventoryData + EquipmentData）实现后打开
	# for type in EquipmentData.EquipType.values():
	# 	var slot := equipment.get_slot(type) if equipment else null
	# 	if slot == null:
	# 		continue
	# 	var equip := slot.item as EquipmentData
	# 	if equip == null:
	# 		continue
	# 	health_bonus += equip.bonus_max_hp
	# 	attack_bonus += equip.bonus_damage
	# 	defense_bonus += equip.bonus_defense


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


func need_exp() -> int:
	return int(base_up_need_exp * pow(up_rate, level - 1))


func level_up() -> void:
	level += 1
	points_total += up_points


func points_left() -> int:
	return points_total - points_used


func upgrade_stat(stat: StringName) -> bool:
	if points_left() <= 0 or not attrs.has(stat):
		return false
	points_used += 1
	attrs[stat] = bare(stat) + 1
	recalc()
	return true


func add_gold(value: int) -> void:
	gold = maxi(gold + value, 0)


## ── 技能冷却（存"到期时间戳"，不用每帧 tick）──
## "蓝够不够"不在这里判断：蓝在 Actor 身上，由 Actor 把两件事合起来判断。
func in_cooldown(skill: SkillData) -> bool:
	return skill != null and Time.get_ticks_msec() < int(cooldown_until.get(skill, 0))


func start_cooldown(skill: SkillData) -> void:
	if skill != null:
		cooldown_until[skill] = Time.get_ticks_msec() + int(skill.cooldown * 1000.0)


func cooldown_left(skill: SkillData) -> float:
	if skill == null:
		return 0.0
	var left := int(cooldown_until.get(skill, 0)) - Time.get_ticks_msec()
	return maxf(left / 1000.0, 0.0)


## ── 存档（只存基础类型；装备存 id 的转换放到第 7 步）──
func to_dict() -> Dictionary:
	return {
		"level": level, "exp": exp, "points_total": points_total, "points_used": points_used,
		"attrs": attrs.duplicate(), "gold": gold,
	}


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
