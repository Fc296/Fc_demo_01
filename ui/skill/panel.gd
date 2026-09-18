extends Control
class_name SkillPanel

## 【UI 层 · 技能栏 / 技能面板】
##
## 显示已学会的技能（图标 + 冷却），并负责"按快捷键施放"。
##
## 三个显示元素，都叠在同一个 Slot 上：
##   图标      SkillData.icon（素材在 Sprites/Ui/Skill Icon）
##   冷却      一个遮罩节点（ColorRect 从上往下扫，或 radial 填充），
##             每帧向 PlayerStats 问一句"还剩几秒"，据此画出来
##   蓝不够    整体压暗 + 加个变灰的着色，让玩家一眼看出"现在按不出来"，
##             而不是按了没反应、以为键盘坏了
##
## ★ 冷却数据放哪：**不放这里**（这个面板改过一次，原因值得记住）
##   面板是会开关、以后还可能要销毁重建的。冷却写在这里，
##   面板一重建冷却就归零 → 无限技能，而且很难复现。
##   正确分工：
##     PlayerStats  记着"这个技能什么时候才能再放"（存时间戳，不用每帧 tick）
##     本面板        只负责"问一句、画出来"，以及"按键时请求施放"
##   另外，冷却也绝不能写回 SkillData：那是一份被所有角色共用的资源，
##   写进去等于所有怪物和你共享同一个冷却。
##
## 施放流程（注意顺序）：
##   按键 → 面板问 PlayerStats.can_cast(skill)
##        → 通过 → 通知状态机切到对应的技能状态 / 生成子弹
##        → 扣蓝 + PlayerStats.start_cooldown(skill)（先确认能放，再扣、再开冷却）
##        → 广播出去让别的系统知道
##   —— 顺序反了（先开冷却再判断能不能放）就会出现"按了没放出来，但冷却已经在转"
##
## ★ 施放决策放在这里、不放在技能状态里的原因：
##   "能不能放"是规则（和数值有关），"放了之后怎么动"是行为。
##   规则放 UI/管理侧，行为放状态机，责任清楚，冷却也能统一显示
##
## ——— 接口清单 ———
# @export var slot_scene: PackedScene
# @onready var bar: HBoxContainer = $Bar
#
# var skills: Array[SkillData] = []
# var stats: PlayerStats                 # 冷却和蓝量都问它，面板自己不存冷却
#
# func _process(delta: float) -> void     # 只刷新遮罩：stats.cooldown_left(skills[i])
# func try_cast(index: int) -> void       # 问 stats.can_cast()，通过才请求施放
# func refresh() -> void
