extends Resource
class_name PlayerStats

## 【通用逻辑层 · 角色属性汇总 + 金币】
##
## 背包里放的是"物品"，这里是"物品生效之后，角色身上剩下的数字"。
## 一件装备穿上时把加成加进来，脱下时减回去。
##
## ★ 属性计算唯一正确的写法：基础值 + 所有加成，每次重算。
##     base_attack 5.0，戴上 +3 的剑 → 8.0；再戴上 +2 的戒指 → 10.0。
##   不要在东一件西一件时直接往最终值上 += ——那样脱装顺序一变，数值就会漂，
##   而且会漂得悄无声息（这是数值类 bug 的头号来源）。
##
## 负责：攻击 / 防御 / 移速等基础属性、经验与等级、金币
## 不负责：显示（面板来读）、存盘（存档系统来读）—— 它只管算
##
## 金币为什么在这里，而不是做成一个物品：
##   金币是"玩家的一个数字"，不是背包里的一格。
##   做成物品就要处理"叠满 999 怎么办、钱包装不下怎么办"，纯属自找麻烦。
##   将来要做"钱袋"道具，那也只是个道具，点开时给 gold += N 而已。
##
## 和 GameData 的分工（很容易搞混）：
##   PlayerStats  角色自己的战斗数值（攻击/防御/经验等级）
##   GameData     属于这一局游戏、不属于某个角色的东西（存档槽、进度标志位）
##   以后做多角色切换时，PlayerStats 会跟着当前角色换，GameData 不会
##
## ★ 为什么是 Resource，而不是 Node（这里改过一次，说清原因）：
##   它是一堆"数字"，不是场景里的东西。做成 Node 就必须挂在某个父节点下，
##   而玩家节点一换场景就销毁 —— 金币、经验、装备加成正好是**必须活过换场景**的东西。
##   做成 Resource 之后由常驻的 GameData 持有，谁也不用担心它什么时候被销毁。
##   附带好处：存档就是把这些基础类型的字段写下来，不需要遍历场景树。
##
## ★ 属性信号为什么不在这个文件里声明：
##   stats_changed / gold_changed 的听众是"界面"，属于跨系统通知 ——
##   统一由 EventBus 广播（见 event_bus.gd 的同名信号单一来源规则），
##   这样全工程只有一个 gold_changed，不会出现"连了 A 却没连 B"。
##   本文件只负责"改值 + 调 EventBus.xxx.emit()"。
##
## ★ 技能冷却为什么也放在这里：
##   冷却决定"能不能放"，属于战斗规则，不是显示。放在面板上会有一个致命后果：
##   面板一关一开（或以后改成按需销毁重建），冷却就归零 → 可以无限放技能。
##   实现诀窍：**存"到期时间戳"，不存"还剩几秒"**。
##     Time.get_ticks_msec() 是引擎启动到现在的毫秒数。
##     放技能时记下 now + cooldown*1000；之后任何地方比一下就知道能不能放。
##   好处：不需要任何人每帧 tick 它。Resource 没有 _process，
##   而"每帧减掉 delta"的写法一旦没人调用就永远不减 —— 时间戳没有这个问题。
##
## ——— 接口清单 ———
# @export var base_attack: float = 5.0
# @export var base_defense: float = 0.0
# @export var base_speed: float = 120.0
#
# var gold: int = 0
# var level: int = 1
# var exp: int = 0
# var equipped: Dictionary = {}            # EquipmentData.Slot -> EquipmentData
#                                          # 运行期用引用（快）；存档时转成 {"部位": 物品id}
# var cooldown_until: Dictionary = {}      # SkillData -> 到期时间戳（毫秒）
#
# func equip(item: EquipmentData) -> void
# func unequip(slot: EquipmentData.Slot) -> void
# func add_gold(value: int) -> void
# func add_exp(value: int) -> void
# func can_cast(skill: SkillData) -> bool          # 蓝够 + 不在冷却
# func start_cooldown(skill: SkillData) -> void     # 记下"什么时候才能再放"
# func cooldown_left(skill: SkillData) -> float     # 还剩几秒（用于画遮罩；没冷却返回 0）
# func get_attack() -> float              # 基础 + 全部装备加成
# func get_defense() -> float
# func get_speed() -> float
# func _recalc() -> void                  # 统一重算并 emit stats_changed
