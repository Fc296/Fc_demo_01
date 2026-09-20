extends ItemBase
class_name PotionData

## 【数据层 · 消耗品】只回答一个问题：喝下去回多少。
## 使用流程（先执行效果、成功后才扣物品）见《脚本说明.md》→ data/potion_data.gd

@export var value: float = 20.0          # 一次动作的"量"统一叫 value（见 event_bus.gd）
@export var duration: float = 0.0        # 0 = 立即回复；>0 = 持续回复秒数
@export var consume_sound: AudioStream   # 按需


func _init() -> void:
	# 默认值写在 _init：新建 .tres 时直接是"消耗品、可叠 64"，忘了改也不会变成材料
	type = ItemType.POTION
	max_stack = 64
