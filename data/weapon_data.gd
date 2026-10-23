@tool
extends EquipmentData
class_name WeaponData

## 【数据层 · 武器】多出"怎么打人"的数值和"拿在手里长什么样"的贴图，依然只是数据。
## 要点：武器不算伤害，只是数值的容器；真正扣血统一在 Actor.take_damage()。
## 背包里看 icon（小图），手上看 hold_texture（大图）。详见《脚本说明.md》→ data/weapon_data.gd

## ——— 接口清单（待实现）———
@export var hit_shape: Shape2D = null              # 判定形状（检查器里新建 CapsuleShape2D / RectangleShape2D 拖进来）
@export var hit_offset: Vector2 = Vector2(0, 12)   # 判定框往前伸多远
@export var hit_angle: float = 0.0                 # 判定框自己再偏转多少（弧度，0 = 正前方；和 hold_angle 同一套单位）
@export var hit_time: float = 0.06                 # 前摇：进状态后几秒出判定。⚠️ 判定框跟着刀刃扫 → 它同时决定"命中在弧线哪儿"：= swing_time/2 才是正前方
@export var recover_time: float = 0.2              # 后摇：多久能再动
@export_range(0.0, 1.0) var move_scale_while_attack: float = 0.5   # 攻击期间移速比例
@export var element: Element.Type = Element.Type.NONE
@export var element_amount: float = 0.0
@export var knockback: float = 6.0                 # 击退像素

@export var hold_texture: Texture2D                    # 手持图：本项目用同目录的 Sprite.png（背包图标），它是"朝上"画的
@export var hold_angle: float = PI               # 贴图"天生"朝哪（下=0 约定）：图标朝上 → PI。换用 SpriteInHand.png 的那把必须显式填 0
@export var hold_orbit := Vector2(9.0, 6.0)      # 武器绕人物图中心转的椭圆半轴：x = 左右、y = 上下（暴露出来方便随时调）
@export var swing_arc: float = 90.0                    # 挥砍扫过的角度（度）
@export var swing_time: float = 0.12                   # 挥砍用时（秒）

## 挥砍的两个极限角：Vector2(起手, 收招)，单位弧度，"手的方向帧"（下=0；不是贴图旋转角）。
## 规矩：从屏幕上更靠上的那一边扫到另一边 —— 朝右是右上→右下，朝左是左上→左下，
## 所以左右两侧看起来都是"从上往下劈"；朝正下/正上时两边一样高，退化成横劈。
## 游戏（attack.gd）和预览工具都调它 —— 共用一份，画布上看到的曲线就是运行时的曲线。
func swing_angles(aim: float) -> Vector2:
	var half := deg_to_rad(swing_arc) * 0.5
	var up_first := cos(aim + half) < cos(aim - half)      # 方向向量的屏幕 y 分量就是 cos(角)
	var start_aim := aim + half if up_first else aim - half
	var end_aim := aim - half if up_first else aim + half
	return Vector2(start_aim, end_aim)                 # hold_angle 不掺和：它只管"贴图天生朝哪"


func _init() -> void:
	super()                    # 先让父类把 type 设成 EQUIPMENT、max_stack 设成 1
	type = ItemType.WEAPON     # 再改成"武器"，不然新建的武器全都算成普通装备
