@tool
extends McpTestSuite

## 【自动化验收 · PlayerStats】公式与成长逻辑。
## 跑法：让 AI 调 Godot AI 的 test_run（suite="player_stats"），或在编辑器里用 Godot AI 面板跑测试。
## 这些数字都是《Godot学习路线.md》第 2 步的验收标准，改公式后跑一遍就知道有没有改坏。


func suite_name() -> String:
	return "player_stats"


func _fresh() -> PlayerStats:
	var stats := PlayerStats.new()
	stats.recalc()
	return stats


func _near(actual: float, expected: float, label: String) -> void:
	assert_true(absf(actual - expected) < 0.001,
		"%s：期望 %.4f，实际 %.4f" % [label, expected, actual])


func test_initial_values() -> void:
	var stats := _fresh()
	_near(stats.health_bonus, 100.0, "初始最大生命")
	_near(stats.mana_bonus, 50.0, "初始最大法力")
	_near(stats.attack_bonus, 20.0, "初始攻击")
	_near(stats.defense_bonus, 5.0, "初始防御")
	_near(stats.crit, 5.0, "初始暴击率")
	_near(stats.miss, 5.0, "初始闪避")
	_near(stats.crit_damage, 150.0, "初始暴击伤害")


func test_strength_to_10() -> void:
	var stats := _fresh()
	stats.points_total = 5
	for i in 5:
		assert_true(stats.upgrade_stat(&"strength"), "第 %d 次加点应成功" % (i + 1))
	assert_eq(stats.bare(&"strength"), 10)
	_near(stats.health_bonus, 150.0, "力量 10 的最大生命")
	_near(stats.defense_bonus, 6.25, "力量 10 的防御")


func test_agility_to_10() -> void:
	var stats := _fresh()
	stats.points_total = 5
	for i in 5:
		stats.upgrade_stat(&"agility")
	_near(stats.attack_bonus, 25.0, "敏捷 10 的攻击")
	_near(stats.crit, 5.25, "敏捷 10 的暴击率")
	_near(stats.miss, 7.5, "敏捷 10 的闪避")


func test_intelligence_to_10() -> void:
	var stats := _fresh()
	stats.points_total = 5
	for i in 5:
		stats.upgrade_stat(&"intelligence")
	_near(stats.mana_bonus, 75.0, "智力 10 的最大法力")


func test_exp_and_level_up() -> void:
	var stats := _fresh()
	assert_eq(stats.need_exp(), 100, "1 级需要 100 经验")
	assert_eq(stats.add_exp(100), 1, "100 经验刚好升 1 级")
	assert_eq(stats.level, 2)
	assert_eq(stats.exp, 0)
	assert_eq(stats.points_left(), 4, "升级发 4 点属性点")
	assert_eq(stats.need_exp(), 120, "2 级需要 120 经验")
	assert_eq(stats.add_exp(264), 2, "264 经验（120+144）从 2 级升到 4 级")
	assert_eq(stats.exp, 0)


func test_upgrade_consumes_points() -> void:
	var stats := _fresh()
	assert_false(stats.upgrade_stat(&"strength"), "没有点数时加点应失败")
	stats.points_total = 1
	assert_true(stats.upgrade_stat(&"strength"))
	assert_eq(stats.points_left(), 0)
	assert_false(stats.upgrade_stat(&"strength"), "点数用完后再加点应失败")
	assert_eq(stats.bare(&"strength"), 6)


func test_level_up_does_not_change_hp() -> void:
	var stats := _fresh()
	stats.points_total = 1
	stats.upgrade_stat(&"strength")
	var before := stats.health_bonus
	stats.add_exp(100)
	_near(stats.health_bonus, before, "升级本身不改血量（点数没花就不该变）")


func test_save_load_round_trip() -> void:
	var stats := _fresh()
	stats.add_exp(100)
	stats.points_total = stats.points_left()
	stats.upgrade_stat(&"agility")
	stats.add_gold(120)
	var data := stats.to_dict()

	var loaded := PlayerStats.new()
	loaded.from_dict(data)
	assert_eq(loaded.level, stats.level)
	assert_eq(loaded.exp, stats.exp)
	assert_eq(loaded.gold, 120)
	assert_eq(loaded.bare(&"agility"), stats.bare(&"agility"))
	_near(loaded.attack_bonus, stats.attack_bonus, "读档后攻击一致")
