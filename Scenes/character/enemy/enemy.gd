extends Actor
class_name Enemy

## 【角色层 · 敌人】
##
## 只加"AI 参数 + 掉落表"。跑动的部分（idle / chase / attack / hurt / die 这些状态）
## 完全复用 Actor + State，一行都不用重写。
##
## 敌人独有的两件事：
##   1. AI 参数  看到玩家多远的距离开始追（detect_range）、追到多近开始打（attack_range）、
##               追击速度、丢失目标多久放弃 —— 全是 @export，
##               在检查器里拖数字调手感，不用改代码、不用重开项目
##   2. 掉落表   死亡时把 loot_table 交给掉落系统去抽签
##
## 死亡流程不要自己造：直接 connect Actor.died 信号 →
##   调 loot_spawner 抽掉落并生成 → 最后 queue_free()。
##   顺序反了（先 free 再抽掉落）会拿到已经被释放的坐标
##
## ★ 想让不同怪物有不同"性格"，不要加 if 分支，直接换状态节点组合：
##     近战怪 = idle + chase + attack + hurt + die
##     远程怪 = 上面再挂一个 shoot 状态
##     傻怪   = 干脆不放 chase 状态，它压根不知道要追
##   组合出来的行为永远比 if 分支出来的好调、好读、好复用
##
## ——— 接口清单 ———
# @export var detect_range: float = 160.0     # 多远开始追
# @export var attack_range: float = 24.0      # 多近开始打
# @export var chase_speed: float = 60.0
# @export var lose_sight_time: float = 2.0    # 丢失目标后放弃追击的秒数
# @export var loot_table: LootTable
#
# func _on_died() -> void                     # 抽掉落 → 交给 loot_spawner → queue_free
# func distance_to_player() -> float
