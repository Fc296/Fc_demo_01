extends ItemBase
class_name SkillData

## 【数据层 · 技能】记录"花多少、等多久、图标长什么样"。
## 易混的一对：SkillData = 技能表里的一行数字（长期不变）；技能状态 = 状态机里真正播动画、
## 生成判定、走冷却的行为节点。冷却的"还剩几秒"不写回这里（会被多个角色共享）——放 PlayerStats。
## 详见《脚本说明.md》→ data/skill_data.gd

@export var mana_cost: float = 0.0
@export var cooldown: float = 3.0
@export var damage: float = 0.0
@export var projectile_scene: PackedScene     # 远程技能用；近战留空


func _init() -> void:
	type = ItemType.SKILL
	max_stack = 1
