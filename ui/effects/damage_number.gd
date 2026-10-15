extends Label
class_name DamageNumber

## 【UI 层 · 伤害数字】挨打时冒一个数字，往上飘 + 淡出后自毁。
## 由 HUD 生成（路线图 3.1 第 9 条：伤害数字与提示集中在 HUD）。
## 数字锚在"命中那一刻的位置"，不跟着目标跑 —— 0.6 秒里看不出来差别。

const RISE := 14.0       # 往上飘多少像素
const LIFE := 0.6        # 活多久（秒）


func setup(amount: float, color: Color = Color.WHITE) -> void:
	text = str(roundi(amount))          # 4.7 → "5"，玩家只看整数
	modulate = color
	var t := create_tween()
	t.set_parallel(true)                # 上飘和淡出同时进行
	t.tween_property(self, "position:y", position.y - RISE, LIFE)
	t.tween_property(self, "modulate:a", 0.0, LIFE)
	t.finished.connect(queue_free)      # 飘完自己删掉，不留垃圾
