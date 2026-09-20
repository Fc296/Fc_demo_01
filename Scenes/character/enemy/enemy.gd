extends Actor
class_name Enemy

## 【角色层 · 敌人】只加"AI 参数 + 掉落表"，跑动/受击/死亡完全复用 Actor + State。
## 死亡流程：connect Actor.died → 抽掉落 → 生成掉落物 → queue_free（顺序反了会拿到已释放坐标）。
## 不同"性格"靠换状态节点组合，不加 if 分支。完整说明见《脚本说明.md》→ Scenes/character/enemy/enemy.gd

## ——— 接口清单（待实现）———
# @export var detect_range: float = 160.0     # 多远开始追
# @export var attack_range: float = 24.0      # 多近开始打
# @export var chase_speed: float = 60.0
# @export var lose_sight_time: float = 2.0    # 丢失目标后放弃追击的秒数
# @export var loot_table: LootTable
#
# func _on_died() -> void                     # 抽掉落 → 交给 loot_spawner → queue_free
# func distance_to_player() -> float
