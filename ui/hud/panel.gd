extends Control
class_name HudPanel

## 【UI 层 · 常驻状态栏】血条 / 蓝条 / 经验条 / 金币 / 提示文字。
## 铁律：只听 EventBus，而且**必须按 actor 过滤**（`if actor != GameData.get_player(): return`），
##       否则加第二只怪物时，怪物掉血你的血条也会掉。
## 提示文字照 my-01 的写法：自增 id 比较，只有最后一条负责隐藏。
## 完整说明见《脚本说明.md》→ ui/hud/panel.gd

## ——— 接口清单（待实现）———
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
# func _ready() -> void                 # connect 血/蓝/经验/金币 + hint_requested
# func show_hint(text: String, duration: float = 1.5) -> void
# func _on_health_changed(actor: Actor, current: float, maximum: float) -> void
# func _on_mana_changed(actor: Actor, current: float, maximum: float) -> void
# func _on_exp_changed(actor: Actor, current: int, need: int) -> void
# func _on_gold_changed(current: int, change: int) -> void
