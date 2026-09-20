extends CharacterBody2D
class_name Actor

## 【通用逻辑层 · 角色基类】会动、有血有蓝、有朝向、能播动画，兜里揣着一个状态机。
## 它不认识"玩家"：主角 / 敌人 / NPC 都继承它，子类只管"脑子"（输入 / AI / 掉落）。
##
## 属性最终值 = Actor.base_xxx（天生，@export）+ PlayerStats 的成长（可存档）+ 装备加成；
## 出口只有 get_stat() 与 max_health() / attack() 这几个函数，面板和战斗都读它。
## 场景骨架（节点名别改）：AnimSprite(AnimatedSprite2D) / Hitbox(可选) / HurtBox / FSM
## 待办：_ready 里先 `$FSM.actor = self`，再 `$FSM.start()`，最后 health = max_health()
## 完整说明（为什么不搬 HpComponent、上限变化时怎么处理血量）见《脚本说明.md》→ Scripts/actor.gd

## ——— 接口清单（待实现）———
# signal died                                        # 一对一，留在本类
#
## ── 基础值（天生，检查器里调；怪物也靠它）──
# @export var base_max_health: float = 10.0
# @export var base_max_mana: float = 0.0             # 0 = 没有蓝条
# @export var base_move_speed: float = 120.0
# @export var base_attack: float = 0.0               # 玩家填 0（靠三围），怪物填具体值
# @export var base_defense: float = 0.0
# @export var invincible_time: float = 0.6           # 受击无敌时间
# @export var idle_state: StringName = &"idle"       # 受击/攻击后回到哪个状态
#
## ── 运行期状态 ──
# var stats: PlayerStats = null                      # 玩家的成长数据；怪物留空
# var health: float = 0.0
# var mana: float = 0.0
# var last_dir: String = "down"
# var invincible_until: int = 0                      # 毫秒时间戳
# @onready var anim: AnimatedSprite2D = $AnimSprite
# @onready var fsm: FSM = $FSM
#
## ── 汇总口（面板与战斗的唯一数据来源）──
# func max_health() -> float
# func max_mana() -> float
# func move_speed() -> float
# func attack() -> float
# func defense() -> float
# func get_stat(stat: StringName) -> float
#
## ── 行为 ──
# func face(dir_x: float) -> void
# func play_anim(name: StringName) -> void
# func take_damage(value: float, from_position := Vector2.ZERO) -> void
# func heal(value: float) -> void
# func spend_mana(value: float) -> bool               # 蓝不够返回 false，不扣
# func restore_mana(value: float) -> void
# func _ready() -> void
# func _on_stats_changed(actor: Actor) -> void        # 升级/加点/换装后重算上限
