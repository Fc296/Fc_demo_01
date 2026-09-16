extends Control
class_name SkillPanel

## 【UI 层 · 技能栏 / 技能面板】
##
## 显示已学会的技能（图标 + 冷却），并负责"按快捷键施放"。
##
## 三个显示元素，都叠在同一个 Slot 上：
##   图标      SkillData.icon（素材在 Sprites/Ui/Skill Icon）
##   冷却      一个遮罩节点（ColorRect 从上往下扫，或 radial 填充），
##             靠 _process 或 Timer 推进；冷却一类的"运行期状态"不要写回 SkillData
##   蓝不够    整体压暗 + 加个变灰的着色，让玩家一眼看出"现在按不出来"，
##             而不是按了没反应、以为键盘坏了
##
## 施放流程：
##   按键 → 面板读 SkillData.mana_cost 和当前冷却
##        → 都满足 → 通知状态机切到对应的技能状态 / 生成子弹
##        → 扣蓝、开冷却
##        → 广播出去让别的系统知道
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
# var cooldowns: Dictionary = {}          # SkillData -> 剩余秒数
#
# func _process(delta: float) -> void     # 推进冷却、刷新遮罩
# func try_cast(index: int) -> void       # 检查蓝耗与冷却，通过才真的放
# func refresh() -> void
