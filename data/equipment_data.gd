extends ItemBase
class_name EquipmentData

## 【数据层 · 可穿戴物（防具 / 饰品 / 武器类）】
##
## EquipmentData : ItemBase —— 在"一件物品"的基础上加三样：
##   1. 戴在哪     equip_type（9 个部位：my-01 的 8 个 + 武器）
##   2. 穿得上吗   required_strength / agility / intelligence（门槛只看裸三围）
##   3. 穿上多强   bonus_max_hp / bonus_damage / bonus_defense
##
## ★ 部位枚举必须和 UI 上的装备格子一一对应，而且两边引用同一个枚举：
##   写 EquipType.HELMET，不要写字符串 "helmet"（字符串写错不报错、只是静默失效）。
##
## ★★ 序号即格子序号：GameData.equipment 是一个 9 格容器，
##   第 0 格 = HELMET、第 1 格 = CHESTPLATE …… 与枚举顺序严格对应。
##   好处：汇总属性时可以 `equipment.get_slot(EquipType.CHESTPLATE)` 直接取，不用再维护映射表。
##   代价：**改枚举顺序 = 改存档格式**，以后不要随意调换顺序（要加就往后追加）。
##   （武器是最后追加的第 9 个部位，加在末尾就是遵守这条规矩的示范。
##     面板上格子怎么摆是另一回事——面板把每个格子显式绑到某个枚举值，不受序号限制。）
##
## ★ 装备门槛用"裸三围"（不加装备自身加成）：
##   否则会出现"穿上 A 才够条件穿 B、脱了 A 又不够"的循环，玩家永远绕不出来。
##
## ★ 加成只写"数值类"，不写主属性：装备不给力量/敏捷/智力，
##   否则加点、门槛、公式三处会互相打架（my-01 也是这么定的）。
##
## 谁用它：PlayerStats.recalc()（叠加加成）、EquipmentPanel（画格子）、InventoryData（穿脱时校验）
##
## ——— 接口清单 ———
# enum EquipType {
# 	HELMET,           # 0 头盔
# 	CHESTPLATE,       # 1 胸甲
# 	LEGGINGS,         # 2 护腿
# 	LEFT_GAUNTLET,    # 3 左护手
# 	RIGHT_GAUNTLET,   # 4 右护手
# 	LEFT_BOOT,        # 5 左靴
# 	RIGHT_BOOT,       # 6 右靴
# 	SHIELD,           # 7 盾牌
# 	WEAPON,           # 8 武器（09-20 追加：装备栏要能放武器）
# }
#
## 穿脱结果码（给 UI 用：把失败原因显示给人看，而不是静默什么都不发生）
# enum Result { OK, NOT_EQUIPMENT, REQUIREMENT_NOT_MET, BAG_FULL }
#
# func _init() -> void:
# 	type = ItemType.EQUIPMENT     # 默认值写在 _init：忘了填也不会变成"材料"
# 	max_stack = 1                 # 装备永远不可叠
#
# @export var equip_type: EquipType = EquipType.HELMET
#
## ── 穿戴需求（读裸三围；0 = 无要求）──
# @export var required_strength: int = 0
# @export var required_agility: int = 0
# @export var required_intelligence: int = 0
#
## ── 战斗数值加成（脱下时由 recalc 自动减回去，不需要你做减法）──
# @export var bonus_max_hp: float = 0.0
# @export var bonus_damage: float = 0.0
# @export var bonus_defense: float = 0.0
#
## ── 外观（阶段 4 才用）──
# @export var sprite_frame: Texture2D        # 穿在身上显示用的贴图（16×16 护甲层）
#
# func meets(attrs: Dictionary) -> bool       # 裸三围够不够穿
# func missing(attrs: Dictionary) -> Dictionary   # 缺哪一项：{"stat": "strength", "need": 7, "have": 5}
