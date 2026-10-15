@tool
extends Node2D

## 【工具 · 武器判定预览】把一把武器的"判定框 / 往前伸 / 偏转角 / 手持贴图 / 挥砍扇形"摆到屏幕上量。
## 只在编辑器里用：不挂 Autoload、不进游戏场景。
## 用法：① 检查器选 weapon ② 改 .tres 里的数值（画布会自己跟上）或直接拖 HitShape ③ 点按钮写回 .tres
##
## 规矩（重要）：预览节点上的值有两个来源 —— ①武器数据（每帧对账）②你手拖的（点按钮写回）。
## 所以"只在数据真的变了"才去覆盖画面，否则你拖到一半会被抢回去。

@export var weapon: WeaponData

@export_range(-180.0, 180.0, 1.0) var aim_deg: float = 0.0
@export_tool_button("写回武器 .tres") var save_action = _save_to_weapon

@onready var hold_pivot: Node2D = $HoldPivot
@onready var hold_sprite: Sprite2D = $HoldPivot/Hold
@onready var hit_box: Area2D = $HoldPivot/HitBox
@onready var hit_shape: CollisionShape2D = $HoldPivot/HitBox/HitShape

# —— 下面几个是"上一次见过的值"：用来发现武器数据变了没有（改过才重建，没改什么也不做）
var _seen_weapon: WeaponData = null
var _seen_offset := Vector2.INF
var _seen_shape := "?"
var _seen_tex: Texture2D = null
var _seen_hit_angle := 1e9
var _seen_arc := 1e9
var _seen_aim := 1e9


func _process(_delta: float) -> void:
	# @tool 脚本在编辑器里也会跑 _process —— "实时"就是从这儿来的
	if hit_box == null or hold_pivot == null:
		return                                     # @onready 还没赋值（场景还没加载完）
	_sync_from_weapon()

	if aim_deg != _seen_aim:
		_seen_aim = aim_deg
		queue_redraw()

	_pose()                                        # 手的方向 + 贴图朝向修正（和游戏里一样）


func _sync_from_weapon() -> void:
	var w := weapon
	if w != _seen_weapon:                          # 换了武器 → 下面几项强制重新应用一遍
		_seen_weapon = w
		_seen_offset = Vector2.INF
		_seen_shape = "?"
		_seen_tex = null
		_seen_hit_angle = 1e9
	var offset := w.hit_offset if w != null else Vector2.ZERO
	if offset != _seen_offset:
		_seen_offset = offset
		hit_shape.position = offset                # 只有 .tres 里改了 hit_offset 才搬判定框，你手拖的不会被冲掉
	var hit_angle := w.hit_angle if w != null else 0.0
	if hit_angle != _seen_hit_angle:
		_seen_hit_angle = hit_angle
		hit_shape.rotation = hit_angle             # 判定框自己再偏转多少
	var shape_sig := _shape_sig(w.hit_shape if w != null else null)
	if shape_sig != _seen_shape:                   # 形状"变没变"不能只看引用：改了半径还是同一个对象
		_seen_shape = shape_sig
		hit_shape.shape = w.hit_shape.duplicate() if (w != null and w.hit_shape != null) else _new_default_shape()
	var tex: Texture2D = w.hold_texture if w != null else null
	if tex != _seen_tex:
		_seen_tex = tex
		hold_sprite.texture = tex
	if w != null and tex != null:
		var off := Vector2(0, tex.get_height() / 2.0).rotated(w.hold_angle)
		if hold_sprite.offset != off:              # 值一样就不写，别每帧白碰属性
			hold_sprite.offset = off
	if w != null and w.swing_arc != _seen_arc:      # 扇形和两条边界线跟着 swing_arc 变
		_seen_arc = w.swing_arc
		queue_redraw()


func _pose() -> void:
	hold_pivot.rotation = deg_to_rad(aim_deg)      # "手"的方向 = 攻击方向；判定框（挂在手下）跟着它
	if weapon != null:
		hold_sprite.rotation = -weapon.hold_angle  # 贴图再把"天生朝向"补回来


func _shape_sig(s: Shape2D) -> String:
	if s == null:
		return "null"
	if s is CapsuleShape2D:
		return "capsule:%.1f:%.1f" % [s.radius, s.height]
	if s is RectangleShape2D:
		return "rect:%.1f:%.1f" % [s.size.x, s.size.y]
	if s is CircleShape2D:
		return "circle:%.1f" % s.radius
	return s.get_class()


func _new_default_shape() -> CapsuleShape2D:        # 武器还没配形状时，先给一个能拖的起手值
	var s := CapsuleShape2D.new()
	s.radius = 3.0
	s.height = 10.0
	return s


func _save_to_weapon() -> void:
	if weapon == null:
		push_warning("先在检查器里选一把武器")
		return
	if weapon.resource_path.is_empty():
		push_warning("这把武器还没存成 .tres，先保存它一次")
		return
	weapon.hit_offset = hit_shape.position
	weapon.hit_angle = hit_shape.rotation           # ← 判定框的偏转角一起写回
	weapon.hit_shape = hit_shape.shape.duplicate()
	var err := ResourceSaver.save(weapon, weapon.resource_path)
	if err == OK:
		print("[武器预览] 已写回 ", weapon.resource_path, "  offset = ", weapon.hit_offset)
	else:
		push_error("写回失败，错误码 %d" % err)


func _draw() -> void:
	# 全是参考线，不参与逻辑：脚底十字 / 挥砍扇形 / 朝向线 / 起手(绿)收招(红)
	draw_line(Vector2(-4, 0), Vector2(4, 0), Color(1, 1, 1, 0.4))
	draw_line(Vector2(0, -4), Vector2(0, 4), Color(1, 1, 1, 0.4))
	if weapon == null:
		return
	var aim := deg_to_rad(aim_deg)
	var arc := deg_to_rad(weapon.swing_arc)
	var mid := aim + PI / 2.0                      # 绘制坐标是"右=0"，我们的约定是"下=0"，所以 +90°
	draw_arc(Vector2.ZERO, 22.0, mid - arc / 2.0, mid + arc / 2.0, 24, Color(1, 1, 0, 0.6), 1.0)
	draw_line(Vector2.ZERO, Vector2(0, 22.0).rotated(aim), Color(0, 1, 1, 0.6), 1.0)
	var angles := weapon.swing_angles(aim)
	draw_line(Vector2.ZERO, Vector2(0, 22.0).rotated(angles.x), Color(0.4, 1.0, 0.4, 0.5), 1.0)   # 起手
	draw_line(Vector2.ZERO, Vector2(0, 22.0).rotated(angles.y), Color(1.0, 0.4, 0.4, 0.5), 1.0)   # 收招
