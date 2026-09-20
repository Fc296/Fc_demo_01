extends Control
class_name SkillPanel

## 【UI 层 · 技能栏】显示已学技能的图标与冷却，并处理"按快捷键施放"。
## 分工：冷却记在 PlayerStats（到期时间戳，面板只读）；"能不能放"问 PlayerStats.can_cast()，
##       "放了之后怎么动"交给状态机 —— 规则与行为分开，冷却也不会因为面板重建而清零。
## 完整说明见《脚本说明.md》→ ui/skill/panel.gd

## ——— 接口清单（待实现）———
# @export var slot_scene: PackedScene
# @onready var bar: HBoxContainer = $Bar
#
# var skills: Array[SkillData] = []
# var stats: PlayerStats                 # 冷却和蓝量都问它，面板不存冷却
#
# func _process(delta: float) -> void     # 只刷新遮罩：stats.cooldown_left(skills[i])
# func try_cast(index: int) -> void       # 问 can_cast()，通过才请求施放
# func refresh() -> void
