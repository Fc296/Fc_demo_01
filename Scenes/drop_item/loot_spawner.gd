extends Node
class_name LootSpawner

## 【场景层 · 掉落生成器】把"抽签结果"变成"地上真实存在的节点"，全工程唯一 new 掉落物的地方。
## 怪物只说一句"我死了，用这张表"，不关心掉落物长什么样、要不要散开。
## 坑：掉落物要加进**当前场景**（不是 spawner 自己身上），否则换地图它跟着跑。
## 完整说明见《脚本说明.md》→ Scenes/drop_item/loot_spawner.gd

## ——— 接口清单（待实现）———
# @export var drop_scene: PackedScene          # 拖 drop_item.tscn 进来
# @export var scatter_radius: float = 12.0     # 以生成点为圆心的散开半径
#
# func spawn_from(table: LootTable, global_pos: Vector2) -> void   # 抽完铺到地上
# func spawn_item(item: ItemBase, count: int, global_pos: Vector2) -> void
# func _scatter(pos: Vector2) -> Vector2       # 半径内随机取点
