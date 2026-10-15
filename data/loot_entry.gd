extends Resource
class_name LootEntry

## 【数据层 · 掉落条目】一条掉落规则：掉什么、多大概率、掉几个。
## 字段全在检查器里填，填错类型当场报错（阶段一用 Dictionary 吃过"填错只静默算歪"的亏）。

@export var item: ItemBase                              # 掉什么（直接把 .tres 拖进来，不用写 id）
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0   # 独立概率：0.3 = 30%，1.0 = 必掉
@export var min_count: int = 1
@export var max_count: int = 1
