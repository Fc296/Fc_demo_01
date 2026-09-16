extends Area2D
class_name DropItem

## 【场景层 · 地上的掉落物】
##
## 怪物死掉、箱子打开后，掉在地上、走过去能捡起来的那一小团东西。
##
## 它只做三件事：
##   1. 显示   用 item.icon 画自己；数量 > 1 时角标显示数量（可选）
##   2. 捡起   玩家碰到 → 请求加入背包 → ★ 加成功了才 queue_free()
##             背包满了就不捡，物品留在原地 —— 别先删了再发现装不下
##   3. 表现   出生时弹跳一下、轻微浮空、被吸过来。纯粹是手感，不影响逻辑
##
## ★ 重要：掉落物不"知道"物品该怎么用。
##   它唯一的职责是把 ItemBase 从地上搬到容器里，真正的增删逻辑在 InventoryData.add_item()。
##   如果在这里写"这是药水所以加血"，那捡到装备、捡到材料就得再加一堆分支
##
## 生成方式：由 loot_spawner.gd 统一 new 出来，不自己进场景树
##
## ——— 接口清单 ———
# signal picked_up(item: ItemBase, count: int)
#
# @export var item: ItemBase
# @export var count: int = 1
# @onready var sprite: Sprite2D = $Sprite2D
#
# func setup(new_item: ItemBase, new_count := 1) -> void   # 生成后由 spawner 调用
# func _on_body_entered(body: Node2D) -> void              # 判定是不是能捡的人（玩家）
