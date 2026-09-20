extends Resource
class_name PlayerStats

## 【通用逻辑层 · 玩家成长数值（三围 / 经验等级 / 金币 / 技能冷却）】
##
## 这个类回答一个问题：**"玩家现在强到什么程度"**。
## 它是把 my-01 的 StatsComponent + ExpComponent 合并升级来的
## （my-01 里那两个是挂在角色下面的节点，见文末"从 my-01 搬过来了什么"）。
##
## ★★ 属性最终值 = 三处相加，而且只有一个出口 ★★
##     Actor.base_xxx       每个角色天生是多少（检查器里调；怪物也用它）
##   + PlayerStats 的成长   等级 / 三围 / 加点
##   + 装备加成             穿在身上的 EquipmentData
##   → 最终值由 Actor.get_stat("attack") 这类函数给出，**面板和战斗都读它**，
##     绝不允许面板自己再算一遍。
##     （my-01 的坑：属性面板曾经是空脚本，玩家根本看不到真实数值；
##       而一旦面板自己算，就会出现"面板 +2、实战 +3"——这种错几乎发现不了。）
##
## ★ 本类只算"成长那一段"：不认识 Actor、不认识任何节点。
##   依赖方向是单向的 Actor → PlayerStats；怪物不需要它（Actor.stats 留空）。
##
## ★ 每次重算都从常量出发，绝不读上一次的结果（这条是 my-01 里写得最好的部分，原样保留）：
##     damage = base_damage * (1 + damage_per_agility * (agility - BASE_ATTR))
##   而不是 damage += 1.5 —— 后者在脱装 / 洗点时顺序一变，数值就会悄悄漂。
##   触发重算的四个点（记住这四个就够）：**升级、加点、穿脱装备、读档**。
##
## ★ 经验与等级（公式照 my-01）：
##     下一级所需 = base_up_need_exp * up_rate ^ (level - 1)
##     每次升级发 up_points 点属性点；可分配 = 累计发的 - 已用的
##
## ★ 金币为什么在这里：它是"玩家的一个数字"，不是背包里的一格（决策 4）。
##
## ★ 技能冷却用**到期时间戳**，不用"还剩几秒"：
##   时间戳不需要任何人每帧 tick（Resource 没有 _process，
##   而"每帧减 delta"的写法一旦没人调用就永远不减）。
##
## ——— 接口清单 ———
## ── 三围与成长 ──
# const BASE_ATTR := 5                       # 1 级基准属性，公式以此为原点（照 my-01）
# @export var attrs: Dictionary = {"strength": BASE_ATTR, "agility": BASE_ATTR, "intelligence": BASE_ATTR}
# @export var base_up_need_exp: int = 100
# @export var up_rate: float = 1.2
# @export var up_points: int = 4
# var level: int = 1
# var exp: int = 0
# var points_total: int = 0                  # 升级累计发了多少点
# var points_used: int = 0                   # 已分配掉多少点
#
## ── 公式基数与系数（从 my-01 原样搬，检查器里可调）──
# @export var base_max_hp: float = 100.0
# @export var base_max_mp: float = 50.0
# @export var base_damage: float = 20.0
# @export var base_defense: float = 5.0
# @export var base_crit: float = 5.0
# @export var base_crit_dam: float = 150.0
# @export var base_miss: float = 5.0
# @export var base_att_sp: float = 100.0
# @export var base_mov_sp: float = 100.0     # 这是"面板上的移速百分比"；真正走路速度用
#                                            # Actor.base_move_speed，别把两处搞混
# @export var hp_per_strength: float = 0.10
# @export var damage_per_agility: float = 0.05
# @export var mp_per_intelligence: float = 0.10
# @export var defense_per_strength: float = 0.05
# @export var crit_per_agility: float = 0.05
# @export var miss_per_agility: float = 0.5
#
## ── 重算结果（缓存，供 Actor 汇总时读；不要在别处写它们）──
# var health_bonus: float = 0.0      # 相对 Actor.base_max_health 的加成
# var mana_bonus: float = 0.0
# var attack_bonus: float = 0.0
# var defense_bonus: float = 0.0
# var speed_bonus: float = 0.0
# var crit: float = 0.0
# var crit_damage: float = 0.0
# var miss: float = 0.0
# var attack_speed: float = 100.0
#
## ── 其它数据 ──
# var gold: int = 0
# var equipment: InventoryData               # 指向 GameData.equipment 那个 8 格容器，不自己 new
# var cooldown_until: Dictionary = {}        # SkillData → 到期时间戳（毫秒）
#
## ── 函数 ──
# func setup(equipment_container: InventoryData) -> void     # GameData 在开局 / 读档后调
# func recalc() -> void                       # ① 常量 + 三围 ② 叠加装备 ③ 刷新上面的缓存
# func bonus_of(stat: StringName) -> float     # 给 Actor 汇总用："health_bonus" / "attack_bonus" …
# func add_exp(value: int) -> void             # 内部可能连续升好几级（照 my-01 的 while）
# func need_exp() -> int
# func points_left() -> int
# func upgrade_stat(name: StringName) -> bool  # 花 1 点 → 三围 +1 → recalc；点数不够返回 false
# func add_gold(value: int) -> void
# func can_cast(skill: SkillData) -> bool      # 蓝够 + 不在冷却（蓝的上限由 Actor 管）
# func start_cooldown(skill: SkillData) -> void
# func cooldown_left(skill: SkillData) -> float
# func to_dict() -> Dictionary                 # 存档：等级/经验/点数/三围/金币/装备id
# func from_dict(data: Dictionary) -> void
#
## ——— 从 my-01 搬过来了什么（对照表）———
## | my-01 里的东西 | 这里 | 变化 |
## | --- | --- | --- |
## | StatsComponent（Node，emit 整个 Dictionary 快照） | 本类 | 改成 Resource（能存档）；只算"成长那一段"，最终值交给 Actor 汇总 |
## | ExpComponent（Node：等级 / 经验 / 属性点） | 本类 | 合并进来，少一层节点转发 |
## | StatsComponent.base_stats（三围，基准 5） | attrs | 名字统一成 attrs，公式一字未改 |
## | StatsComponent 的公式与全部系数 | 原样搬 | 数值直接可用，先跑起来再调平衡 |
## | 装备加成（bonus_max_hp / damage / defense） | recalc() 第二步 | 改成遍历 GameData.equipment 这个容器（枚举值当索引） |
## | Player.allocate_point() | upgrade_stat() | 加点是"数据变化"，不必经过节点 |
## | Player.stats_snapshot + get_stat() | 删掉 | 不再传快照；要值就问 Actor.get_stat()（唯一出口） |
## | EventBus.on_stats_updated(stats: Dictionary) | EventBus.stats_changed(actor) | 只广播"谁变了"；拿快照当真相的人迟早会造出一份假数据 |
## | StatsComponent.meets_requirements / get_missing_requirement | 保留（放本类） | 装备门槛只看**裸三围**，不看装备加成 |
