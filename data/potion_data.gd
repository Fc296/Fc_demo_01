extends ItemBase
class_name PotionData

## 【数据层 · 消耗品】只回答一个问题：喝下去回多少。
## 使用流程（先执行效果、成功后才扣物品）见《脚本说明.md》→ data/potion_data.gd

## 一次动作的量：回复多少生命 / 法力。
@export var value: float = 20.0
## 0 = 立即回复；大于 0 = 持续回复的秒数。
@export var duration: float = 0.0
## 喝下时播放的音效（可留空）。
@export var consume_sound: AudioStream


func _init() -> void:
	# 默认值写在 _init：新建 .tres 时直接是"消耗品、可叠 64"，忘了改也不会变成材料
	type = ItemType.POTION
	max_stack = 64
