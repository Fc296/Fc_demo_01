extends Area2D
class_name DropItem

## 【场景层 · 地上的掉落物】只做三件事：显示物品图标、被玩家碰到就请求入包、出场表现。
## 铁律：**背包装得下才 queue_free()**；出生后有 0.4 秒不可拾取窗口（避免"打死怪东西瞬间消失"）。
## 它不认识"物品怎么用"。完整说明见《脚本说明.md》→ Scenes/drop_item/drop_item.gd

## ——— 接口清单（待实现）———
signal picked_up(item: ItemBase, count: int)

## 这个掉落物是什么（通常由掉落表抽签后填进来，编辑器里也可手动摆测试物）。
@export var item: ItemBase
## 数量。
@export var count: int = 1
## 出生后多少秒内不能被捡（防止刚掉出来就被吸走）。
@export var pickup_delay: float = 0.4
## 出生时往四周撒开的最大半径（像素）。
@export var scatter_radius: float = 12.0

@onready var sprite: Sprite2D = $Sprite2D

var _age: float = 0.0


func _process(delta: float) -> void:
	_age += delta
	# 窗口一过就主动查一次：如果出生时玩家就压在圈里，
	# body_entered 早就发过了，不会再发第二次
	if _age >= pickup_delay:
		set_process(false)              # 只查一次，查完就别再跑 _process 了
		for body in get_overlapping_bodies():
			var a := body as Actor
			if a != null and a.is_player():
				_try_pick()
				break


# 由 spawner 调用
func setup(new_item: ItemBase, new_count: int = 1) -> void:
	item = new_item
	count = new_count
	if item != null and item.icon != null:
		sprite.texture = item.icon

# 判定是不是能捡的人（玩家）
func _on_body_entered(body: Node2D) -> void:
	if _age < pickup_delay:
		return
	var a := body as Actor
	if a == null or not a.is_player():   # 只有玩家能捡
		return
	_try_pick()


func _try_pick() -> void:
	var bag := GameData.inventory
	if bag == null:
		return
	if bag.add_item(item, count) == 0:   # 装得下才消失（铁律）
		picked_up.emit(item, count)
		print("捡到 ", item.display_name, " x", count)
		queue_free()
	# 装不下：留在原地等玩家腾格子


## 让"我"从落点撒开一点，避免几个掉落物叠在同一个像素上
func scatter() -> void:
	global_position += Vector2(randf_range(-scatter_radius, scatter_radius),
							   randf_range(-scatter_radius, scatter_radius))
