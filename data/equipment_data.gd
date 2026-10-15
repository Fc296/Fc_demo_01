extends ItemBase
class_name EquipmentData

## 【数据层 · 可穿戴物】加三样：戴在哪（部位）、穿得上吗（门槛）、穿上多强（加成）。
## 铁律：枚举顺序 = 装备栏格子序号 = 存档格式，加部位只能往后追加；门槛只看裸三围。
## 完整说明见《脚本说明.md》→ data/equipment_data.gd

## ——— 接口清单 ———

## 铁律：枚举顺序 = 装备栏格子序号 = 存档格式。加部位只能往后追加，不能插在中间。
enum EquipType {
	HELMET,           # 0 头盔
	CHESTPLATE,       # 1 胸甲
	LEGGINGS,         # 2 护腿
	LEFT_GAUNTLET,    # 3 左护手
	RIGHT_GAUNTLET,   # 4 右护手
	LEFT_BOOT,        # 5 左靴
	RIGHT_BOOT,       # 6 右靴
	SHIELD,           # 7 盾牌
	WEAPON,           # 8 武器
}
#
## 穿脱结果码：给 UI 显示失败原因用，别静默失败
enum Result { OK, NOT_EQUIPMENT, REQUIREMENT_NOT_MET, BAG_FULL }

@export var equip_type: EquipType = EquipType.HELMET

## ── 穿戴门槛（读裸三围；0 = 无要求）──
@export var required_strength: int = 0
@export var required_agility: int = 0
@export var required_intelligence: int = 0



## ── 加成（脱下时由 PlayerStats.recalc 自动减回去）──
# 基础属性加成（命名规则：装备上是 bonus_xxx，PlayerStats 里的结果是 xxx_bonus，一眼看出住在哪一边）
@export var bonus_max_hp: float = 0.0             # 生命上限
@export var bonus_max_mp: float = 0.0             # 法力上限
@export var bonus_damage: float = 0.0             # 攻击
@export var bonus_defense: float = 0.0            # 防御
@export var bonus_move_speed: float = 0.0         # 移速

# 生存回复类加成
@export var bonus_lifesteal: float = 0.0          # 吸血百分比
@export var bonus_mana_regen: float = 0.0         # 每秒魔力回复
@export var bonus_health_regen: float = 0.0       # 每秒生命回复
@export var bonus_damage_reduction: float = 0.0   # 伤害减免%

# 三元素抗性加成（光、岩、风）
@export var bonus_resist_light: float = 0.0       # 光抗性
@export var bonus_resist_rock: float = 0.0        # 岩抗性
@export var bonus_resist_wind: float = 0.0        # 风抗性


## ── 外观（阶段 4 才用）──
# @export var sprite_frame: Texture2D


func _init() -> void:
	type = ItemType.EQUIPMENT
	max_stack = 1


func missing(attrs: Dictionary) -> Dictionary:   # {"stat":"strength","need":7,"have":5}
	var checks := [
		[&"strength", required_strength],
		[&"agility", required_agility],
		[&"intelligence", required_intelligence],
	]
	for c in checks:
		var have := int(attrs.get(c[0], 0))
		if c[1] > 0 and have < c[1]:
			return {"stat": c[0], "need": c[1], "have": have}
	return {}


func meets(attrs: Dictionary) -> bool:   # 裸三围够不够穿
	return missing(attrs).is_empty()
