extends Area2D
class_name DropItem

## 【场景层 · 地上的掉落物】只做三件事：显示物品图标、被玩家碰到就请求入包、出场表现。
## 铁律：**背包装得下才 queue_free()**；出生后有 0.4 秒不可拾取窗口（避免"打死怪东西瞬间消失"）。
## 它不认识"物品怎么用"。完整说明见《脚本说明.md》→ Scenes/drop_item/drop_item.gd

## ——— 接口清单（待实现）———
# signal picked_up(item: ItemBase, count: int)
#
# @export var item: ItemBase
# @export var count: int = 1
# @export var pickup_delay: float = 0.4          # 出生后多久才允许被捡
# @onready var sprite: Sprite2D = $Sprite2D
#
# func setup(new_item: ItemBase, new_count := 1) -> void   # 由 spawner 调用
# func _on_body_entered(body: Node2D) -> void              # 判定是不是能捡的人（玩家）
