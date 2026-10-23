extends Label
class_name CoinLabel

## 【UI 层 · 金币余额】插到任何面板里就能显示当前金币。
## 只负责显示：改金币的唯一入口仍是 GameData.add_gold()，这里只订阅广播。
## 用法：把 coin_label.tscn 摆进面板；样式要变就改节点上的 theme / 字体。


func _ready() -> void:
	EventBus.on_gold_changed.connect(_on_gold_changed)
	# 信号只在"值变化时"发，所以进场先自己拉一次当前值
	_on_gold_changed(GameData.player_stats.gold if GameData.player_stats else 0, 0)


func _on_gold_changed(current: int, _change: int) -> void:
	text = "金币 %d" % current
