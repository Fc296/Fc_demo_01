extends Resource
class_name PlayerStats

## 【通用逻辑层 · 玩家成长数值】三围 / 经验等级 / 属性点 / 金币 / 技能冷却。
## 只算"成长那一段"，不认识 Actor、不认识节点（依赖方向：Actor → PlayerStats）。
## 铁律：★ 重算必须从常量出发（`damage = base_damage * (1 + 系数 * (敏捷 - 5))`），
##       绝不 `damage += 1.5` —— 后者脱装/洗点顺序一变数值就漂。
##       ★ 触发重算只有四个点：升级、加点、穿脱装备、读档，四处都要调 recalc()。
## 完整说明（公式来源、与 my-01 的对照表、冷却为何用时间戳）见《脚本说明.md》→ Scripts/player_stats.gd

## ——— 接口清单（待实现）———
## ── 三围与成长 ──
# const BASE_ATTR := 5
# @export var attrs: Dictionary = {"strength": BASE_ATTR, "agility": BASE_ATTR, "intelligence": BASE_ATTR}
# @export var base_up_need_exp: int = 100
# @export var up_rate: float = 1.2
# @export var up_points: int = 4
# var level: int = 1
# var exp: int = 0
# var points_total: int = 0
# var points_used: int = 0
#
## ── 公式基数与系数（从 my-01 原样搬，检查器可调）──
# @export var base_max_hp: float = 100.0
# @export var base_max_mp: float = 50.0
# @export var base_damage: float = 20.0
# @export var base_defense: float = 5.0
# @export var base_crit: float = 5.0
# @export var base_crit_dam: float = 150.0
# @export var base_miss: float = 5.0
# @export var base_att_sp: float = 100.0
# @export var base_mov_sp: float = 100.0     # 面板上的移速百分比；真正走路用 Actor.base_move_speed
# @export var hp_per_strength: float = 0.10
# @export var damage_per_agility: float = 0.05
# @export var mp_per_intelligence: float = 0.10
# @export var defense_per_strength: float = 0.05
# @export var crit_per_agility: float = 0.05
# @export var miss_per_agility: float = 0.5
#
## ── 重算结果（缓存，供 Actor 汇总读；别在别处写）──
# var health_bonus: float = 0.0
# var mana_bonus: float = 0.0
# var attack_bonus: float = 0.0
# var defense_bonus: float = 0.0
# var speed_bonus: float = 0.0
# var crit: float = 0.0
# var crit_damage: float = 0.0
# var miss: float = 0.0
# var attack_speed: float = 100.0
#
## ── 其它 ──
# var gold: int = 0
# var equipment: InventoryData               # 指向 GameData.equipment，不自己 new
# var cooldown_until: Dictionary = {}        # SkillData → 到期时间戳（毫秒）
#
## ── 函数 ──
# func setup(equipment_container: InventoryData) -> void
# func recalc() -> void                       # ① 常量 + 三围 ② 叠加装备 ③ 刷新上面的缓存
# func bonus_of(stat: StringName) -> float     # 给 Actor 汇总用
# func add_exp(value: int) -> void             # 可能连续升好几级
# func need_exp() -> int
# func points_left() -> int
# func upgrade_stat(name: StringName) -> bool  # 花 1 点 → 三围 +1 → recalc
# func add_gold(value: int) -> void
# func can_cast(skill: SkillData) -> bool
# func start_cooldown(skill: SkillData) -> void
# func cooldown_left(skill: SkillData) -> float
# func to_dict() -> Dictionary
# func from_dict(data: Dictionary) -> void
