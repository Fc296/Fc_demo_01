extends ItemBase
class_name EquipmentData

## 【数据层 · 可穿戴物】加三样：戴在哪（部位）、穿得上吗（门槛）、穿上多强（加成）。
## 铁律：枚举顺序 = 装备栏格子序号 = 存档格式，加部位只能往后追加；门槛只看裸三围。
## 完整说明见《脚本说明.md》→ data/equipment_data.gd

## ——— 接口清单（待实现）———
# enum EquipType {
# 	HELMET,           # 0 头盔
# 	CHESTPLATE,       # 1 胸甲
# 	LEGGINGS,         # 2 护腿
# 	LEFT_GAUNTLET,    # 3 左护手
# 	RIGHT_GAUNTLET,   # 4 右护手
# 	LEFT_BOOT,        # 5 左靴
# 	RIGHT_BOOT,       # 6 右靴
# 	SHIELD,           # 7 盾牌
# 	WEAPON,           # 8 武器（追加在末尾）
# }
#
## 穿脱结果码：给 UI 显示失败原因用，别静默失败
# enum Result { OK, NOT_EQUIPMENT, REQUIREMENT_NOT_MET, BAG_FULL }
#
# @export var equip_type: EquipType = EquipType.HELMET
#
## ── 穿戴门槛（读裸三围；0 = 无要求）──
# @export var required_strength: int = 0
# @export var required_agility: int = 0
# @export var required_intelligence: int = 0
#
## ── 加成（脱下时由 PlayerStats.recalc 自动减回去）──
# @export var bonus_max_hp: float = 0.0
# @export var bonus_damage: float = 0.0
# @export var bonus_defense: float = 0.0
#
## ── 外观（阶段 4 才用）──
# @export var sprite_frame: Texture2D
#
# func _init() -> void:
# 	type = ItemType.EQUIPMENT
# 	max_stack = 1
#
# func meets(attrs: Dictionary) -> bool          # 裸三围够不够穿
# func missing(attrs: Dictionary) -> Dictionary  # {"stat":"strength","need":7,"have":5}
