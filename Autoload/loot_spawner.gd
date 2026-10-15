extends Node

## 【场景层 · 掉落生成器】把"抽签结果"变成"地上真实存在的节点"，全工程唯一 new 掉落物的地方。
## 怪物只说一句"我死了，用这张表"，不关心掉落物长什么样、要不要散开。
## 坑：掉落物要加进**当前场景**（不是 spawner 自己身上），否则换地图它跟着跑。
## 完整说明见《脚本说明.md》→ Scenes/drop_item/loot_spawner.gd

const DROP_SCENE := preload("res://Scenes/drop_item/drop_item.tscn")


# 抽完铺到地上
func spawn(drops: Array[Dictionary], global_pos: Vector2) -> void:
	for d in drops:
		spawn_item(d["item"], int(d["count"]), global_pos)


func spawn_item(item: ItemBase, count: int, global_pos: Vector2) -> void:
	if item == null or count <= 0:
		return
	var node := DROP_SCENE.instantiate()
	var map := get_tree().current_scene
	var drops := map.get_node_or_null("Drops")           # 地图里有专门的抽屉就用它
	(drops if drops != null else map).add_child(node)    # 没有就退回老做法（加在地图根上）
	node.global_position = global_pos                    # 进树之后才能设 global_position
	node.setup(item, count)                              # 也要在进树之后，否则 @onready 的 sprite 还是 null
	node.scatter()                                       # 撒开多少，由掉落物自己决定
