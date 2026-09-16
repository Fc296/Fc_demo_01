extends Node
class_name LootSpawner

## 【场景层 · 掉落生成器】
##
## 把"抽签结果"变成"地上真实存在的节点"。★ 这是整套掉落系统里唯一负责 new 东西的地方。
##
## 为什么单独拆出来：
##   怪物只需要说一句"我死了，用这张表"，完全不关心掉落物长什么样、
##   要不要散开、要不要延迟弹出、金币怎么处理。
##   换成宝箱、木桶、Boss 掉落，全都复用同一个 spawner —— 改一个地方，全体生效
##
## 流程：
##   LootTable.roll() 拿到 [{ item, count }]
##     → 对每一条，实例化 drop_scene
##     → 放到指定坐标周围（散开一点，避免全叠在同一点，看起来像一个）
##     → 加进场景树
##   金币不生成节点，直接把数值加给 PlayerStats（金币在地上一粒粒捡太烦了）
##
## 常见坑：
##   - 掉落物要加到"当前场景"而不是 spawner 自己身上，否则玩家换地图它跟着跑
##   - 死亡瞬间就把节点加进去，可能和攻击判定挤在同一帧；需要时用 await 延后一帧
##
## ——— 接口清单 ———
# @export var drop_scene: PackedScene          # 拖 drop_item.tscn 进来
# @export var scatter_radius: float = 12.0     # 以生成点为圆心的散开半径
#
# func spawn_from(table: LootTable, global_pos: Vector2) -> void   # 一次抽完并铺到地上
# func spawn_item(item: ItemBase, count: int, global_pos: Vector2) -> void
# func _scatter(pos: Vector2) -> Vector2       # 在半径内随机取一个不重叠的点
