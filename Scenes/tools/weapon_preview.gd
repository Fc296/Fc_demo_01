@tool
extends Node2D

## 【工具 · 武器参数预览】改 .tres 里的参数 → 这里实时跟着变；手拖判定框 → 点按钮写回。
## 只在编辑器里用：不挂 Autoload、不进游戏场景。
## 保留"参数设置"这条链路：手持贴图 / 椭圆偏移 / 判定框 / 写回；参考线与每帧对账都去掉了。
## 偏移只有一个来源：WeaponData.hold_orbit（每帧算位置）；贴图不再另外设 Sprite2D.offset。

## 要预览的武器。换一把 → 下面所有显示立刻按它的数据重摆。
@export var weapon: WeaponData:
	set(value):
		if weapon != null and weapon.changed.is_connected(_apply):
			weapon.changed.disconnect(_apply)
		weapon = value
		if weapon != null and not weapon.changed.is_connected(_apply):
			weapon.changed.connect(_apply)
		_apply()

## 预览用的瞄准角度（度，0 = 正下方，顺时针为正）。拖它看武器在不同方向的姿势。
@export_range(-180.0, 180.0, 1.0) var aim_deg: float = 0.0
## 把画布上手拖过的判定框（位置 / 偏转角 / 形状）写回武器的 .tres。
@export_tool_button("写回武器 .tres") var save_action = _save_to_weapon

@onready var hold_pivot: Node2D = $HoldPivot
@onready var hold_sprite: Sprite2D = $HoldPivot/Hold
@onready var hit_shape: CollisionShape2D = $HoldPivot/HitBox/HitShape

# 上一次应用过的值：只有数据真的变了才覆盖 —— 你手拖的判定框不会被抢回去
var _seen_offset := Vector2.INF
var _seen_hit_angle := 1e9
var _seen_shape := "?"


func _ready() -> void:
	_apply()


## 武器数据变了（检查器里改 .tres）→ 重新应用一次
func _apply() -> void:
	if not is_node_ready() or weapon == null:
		return
	hold_sprite.texture = weapon.hold_texture
	hold_sprite.rotation = -weapon.hold_angle
	if weapon.hit_offset != _seen_offset:
		_seen_offset = weapon.hit_offset
		hit_shape.position = weapon.hit_offset
	if weapon.hit_angle != _seen_hit_angle:
		_seen_hit_angle = weapon.hit_angle
		hit_shape.rotation = weapon.hit_angle
	var sig := _shape_sig(weapon.hit_shape)
	if sig != _seen_shape:
		_seen_shape = sig
		hit_shape.shape = weapon.hit_shape.duplicate() if weapon.hit_shape != null else _default_shape()


## 每帧摆姿态：手朝 aim，贴图按"天生朝向"补回来，并按武器的椭圆偏移离开人物中心
func _process(_delta: float) -> void:
	if hold_pivot == null or weapon == null:
		return
	var aim := deg_to_rad(aim_deg)
	hold_pivot.rotation = aim
	var dir := Vector2(0, 1).rotated(aim)
	var orbit := Vector2(dir.x * weapon.hold_orbit.x, dir.y * weapon.hold_orbit.y)
	hold_sprite.position = orbit.rotated(-aim)     # 世界椭圆 → "手"的局部坐标


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


func _default_shape() -> CapsuleShape2D:        # 武器还没配形状时，先给一个能拖的起手值
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
