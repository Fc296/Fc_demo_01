extends CharacterBody2D
class_name Actor

## 【通用逻辑层 · 所有角色的公共父类】
##
## Actor 是"会动、有血、有蓝、有朝向、能播动画、兜里揣着一个状态机"的东西。
## 它压根不认识"玩家"这个词 —— 主角、敌人、NPC 全都继承它。
##
## ★ 为什么要把老项目里的 Player 拆开：
##   my-01 里血量、属性、动画、受击全写在 Player 上（外加两个 HpComponent / ExpComponent 节点），
##   怪物要的话就只能复制一份。现在 Actor 管"身体"，子类只管"脑子"：
##     Player : Actor  → 只加输入、经验、鼠标攻击
##     Enemy  : Actor  → 只加 AI 参数、掉落表
##
## ★★ 属性从哪来（和 PlayerStats 的分工，这是本文件最重要的一段）★★
##     Actor.base_xxx      这个角色天生是多少（@export，检查器里调；怪物也靠它）
##   + PlayerStats 的成长  等级 / 三围 / 加点（玩家才有；怪物 stats 留空 = 加成算 0）
##   + 装备加成            跟着 PlayerStats 一起算好，放在它的 *_bonus 字段里
##   → 汇总只在这一个文件里发生，出口只有 get_stat() / 下面几个函数：
##        max_health() / max_mana() / move_speed() / attack() / defense()
##     面板和战斗**都读这里**，谁都不许自己再拼一遍公式。
##
## ★ 血量为什么不沿用 my-01 的 HpComponent 节点：
##   血量是"身体"的一部分，塞进 Actor 少一层转发（转发多了就会有人忘了同步）。
##   代价说清楚：将来若要做"可破坏物"（木箱、门、矿脉），它们不是 Actor，
##   那时候再把血量抽成一个独立组件，让 Actor 和可破坏物共用 —— 现在是过度设计。
##   （my-01 的 HpComponent.set_max() 语义要保留：上限变大时保留当前血量，
##     变小才 clamp，绝不顺手回血。这是升级/穿装备时最容易被忽略的细节。）
##
## ★ 蓝和血同构：base_max_mana 填 0 就表示这个角色没有蓝条（怪物通常填 0）。
##
## 场景骨架（新建任何角色照抄这个结构，节点名不要改）：
##   CharacterBody2D  ← 挂角色自己的脚本（Player / Enemy）
##     ├─ AnimSprite : AnimatedSprite2D   ← 名字固定，Actor 靠它播动画
##     ├─ Hitbox     : Area2D             ← 可选：NPC 没有攻击框就不放，代码里要判空
##     ├─ HurtBox    : Area2D             ← 被别人打的判定区
##     └─ FSM        : Node（挂 fsm.gd）   ← 子节点里放状态
##
## ★ 待办（写 _ready 时务必做，就一行）：
##   $FSM.actor = self      ← "我是谁"不能靠猜场景根节点（原因见 fsm.gd 顶部）
##   然后 fsm.start()；最后把血量初始化成 max_health()。
##
## ★ 信号归属：Actor 自己**不声明** health_changed，
##   血/蓝一变就 EventBus.health_changed.emit(self, cur, max)（带上是谁）。
##   只有 Actor.died 这种"自己 → 自己的订阅者"的一对一关系才留在这里。
##
## ——— 接口清单 ———
# signal died                                        # 一对一（自己 → 订阅者），留在本类
#
## ── 基础值（每个角色天生，检查器里调）──
# @export var base_max_health: float = 10.0
# @export var base_max_mana: float = 0.0             # 0 = 没有蓝条
# @export var base_move_speed: float = 120.0
# @export var base_attack: float = 0.0               # 玩家填 0（靠三围公式），怪物填具体值
# @export var base_defense: float = 0.0
# @export var invincible_time: float = 0.6           # 受击无敌时间，防止被连击一帧掉光
# @export var idle_state: StringName = &"idle"       # 受击 / 攻击结束后回到哪个状态（怪物常填 chase）
#
## ── 运行期状态 ──
# var stats: PlayerStats = null                      # 玩家的成长数据；怪物留空（加成按 0 算）
# var health: float = 0.0
# var mana: float = 0.0
# var last_dir: String = "down"
# var invincible_until: int = 0                      # 毫秒时间戳（Time.get_ticks_msec()）
# @onready var anim: AnimatedSprite2D = $AnimSprite
# @onready var fsm: FSM = $FSM
#
## ── 汇总口：面板与战斗的唯一数据来源 ──
# func max_health() -> float                         # base_max_health + stats.health_bonus
# func max_mana() -> float
# func move_speed() -> float
# func attack() -> float
# func defense() -> float
# func get_stat(stat: StringName) -> float            # 统一入口：面板想显示什么就问它
#
## ── 行为 ──
# func face(dir_x: float) -> void                     # 转向：记住朝向（翻转贴图留给攻击阶段）
# func play_anim(name: StringName) -> void            # 播 "名字_方向" 动画，素材里没有的直接忽略
# func take_damage(value: float, from_position := Vector2.ZERO) -> void
# func heal(value: float) -> void
# func spend_mana(value: float) -> bool               # 蓝不够返回 false，不扣
# func restore_mana(value: float) -> void
# func _ready() -> void                               # 注入 fsm.actor、启动状态机、初始化血蓝
# func _on_stats_changed(actor: Actor) -> void        # 升级/加点/换装后重算上限（保留当前血量比例）
