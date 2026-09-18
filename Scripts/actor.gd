extends CharacterBody2D
class_name Actor

## 【通用逻辑层 · 所有角色的公共父类】
##
## Actor 是"会动、有血、有朝向、能播动画、兜里揣着一个状态机"的东西。
## 注意它压根不认识"玩家"这个词 —— 主角、敌人、NPC 全都继承它。
##
## ★ 为什么要把老项目里的 Player 拆开：
##   以前血量、动画、受击全写在 Player 里，怪物就只能复制一份，
##   于是改一处 bug 要改两处，还经常只改一处。
##   现在 Actor 管"身体"，子类只管"脑子"：
##     Player : Actor  → 只加输入、经验、鼠标攻击
##     Enemy  : Actor  → 只加 AI 参数、掉落表
##
## 职责边界（写代码时照这个分，越界就是设计坏了）：
##   Actor 管：max_health / health、朝向 facing、play(动画名)、take_damage()、无敌帧、死亡
##   Actor 不管：输入、AI、经验、金币、背包 —— 那些属于各自的子类或系统
##
## 场景骨架（新建任何角色照抄这个结构，节点名不要改）：
##   CharacterBody2D  ← 挂本脚本
##     ├─ AnimSprite : AnimatedSprite2D   ← 名字固定，Actor 靠它播动画
##     ├─ Hitbox     : Area2D             ← 可选：NPC 没有攻击框就不放，代码里要判空
##     ├─ HurtBox    : Area2D             ← 被别人打的判定区
##     └─ FSM        : Node（挂 fsm.gd）   ← 子节点里放状态
##
## 状态机在 Actor 的 _ready 里启动，这样能保证 @onready 变量都已就绪才跑第一个状态。
##
## ★ 待办（写 _ready 时务必做，就一行）：
##   $FSM.actor = self
##   原因见 fsm.gd 顶部："我是谁"不能靠猜场景根节点，要显式赋值。
##
## ★ 血量信号的归属：Actor 自己**不声明** health_changed，
##   血变了直接 EventBus.health_changed.emit(self, cur, max)（带上是谁）。
##   只有 Actor.died 这种"自己 → 自己的子类/订阅者"的一对一关系才留在这里。
##
## ——— 接口清单 ———
# signal died                                       # 一对一（自己 → 订阅者），留在本类
#
# @export var max_health: float = 10.0
# @export var idle_state: StringName = &"idle"      # 受击/攻击结束后回到哪个状态（怪物常填 chase）
# @export var invincible_time: float = 0.6          # 受击无敌时间，防止被连击打成一帧掉光
#
# func face(dir_x: float) -> void                   # 转向：翻转贴图和攻击框位置
# func play(anim: StringName) -> void                # 播动画，素材里没有的动画名直接忽略，不报错
# func take_damage(value: float, from_position := Vector2.ZERO) -> void
