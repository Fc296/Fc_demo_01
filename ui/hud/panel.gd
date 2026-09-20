extends Control
class_name HudPanel

## 【UI 层 · 常驻状态栏（血条 / 蓝条 / 经验条 / 金币 / 提示文字）】
##
## 屏幕常驻的那几条东西。它和属性面板的区别：属性面板是"按 I 打开才看"，
## HUD 是"一直在，打架时要能扫一眼"。
##
## ★ 它只听 EventBus，而且**必须按 actor 过滤**：
##   事件都带"是谁"（health_changed(actor, current, maximum)），
##   过滤方式统一走 GameData.get_player() —— 不这么写的话，
##   加第二只怪物时，怪物掉血你的血条也会跟着掉。
##
## ★ 这里只做"画"：不存血量、不改血量。
##   血量的真相在 Actor 上，HUD 只是把广播过来的数字摆上去。
##
## ★ 提示文字（hint）：my-01 里的 show_hint() 是个好东西，照搬 ——
##   连续提示时只有最后一条负责隐藏（用一个自增 id 比较），
##   否则前一条的定时器到点会把后一条也一起关掉。
##
## 面板开关按钮以后也挂在这里（背包 I / 装备 / 属性 / 技能）：
##   按钮只负责"让对应的面板显示或隐藏"，面板自己不知道按钮存在。
##
## ——— 接口清单 ———
# @onready var hp_bar: ProgressBar = %HpBar
# @onready var hp_label: Label = %HpLabel
# @onready var mana_bar: ProgressBar = %ManaBar
# @onready var mana_label: Label = %ManaLabel
# @onready var exp_bar: ProgressBar = %ExpBar
# @onready var coin_label: Label = %CoinLabel
# @onready var hint_label: Label = %HintLabel
#
# var _hint_id: int = 0
#
# func _ready() -> void                 # connect 四条广播（血/蓝/经验/金币）+ hint_requested
# func show_hint(text: String, duration: float = 1.5) -> void
# func _on_health_changed(actor: Actor, current: float, maximum: float) -> void
# func _on_mana_changed(actor: Actor, current: float, maximum: float) -> void
# func _on_exp_changed(actor: Actor, current: int, need: int) -> void
# func _on_gold_changed(current: int, change: int) -> void
