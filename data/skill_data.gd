extends ItemBase
class_name SkillData

## 【数据层 · 技能】
##
## SkillData : ItemBase —— 记录一个技能"花多少、等多久、图标长什么样"。
##
## 本类多出来的字段：
##   mana_cost        蓝耗
##   cooldown         冷却秒数
##   damage           命中判定时的伤害
##   projectile_scene 命中时生成的子弹/特效场景（远程技能用；近战留空）
##
## ★ 最容易搞混的一对概念，记住这句话：
##     SkillData = 技能表里的一行数字（长期不变，可以存成 .tres，编辑器里填）
##     技能状态  = 状态机里真正播动画、生成判定框、走冷却的那个"行为"节点
##   前者回答"是什么"，后者回答"怎么打"。数据变了不用改行为，行为改了不用动数据。
##
## 谁用它：SkillPanel（画图标 / 画冷却遮罩）、状态机里的技能状态（读数值）
##
## 冷却放哪：建议把"还剩几秒"这种运行期状态单独放一张冷却表（或写在 PlayerStats 里），
##   SkillData 保持只读。同一份资源被多个角色引用时，写进去就会互相串数据
##
## ——— 接口清单 ———
# @export var mana_cost: float = 0.0
# @export var cooldown: float = 3.0
# @export var damage: float = 0.0
# @export var projectile_scene: PackedScene
