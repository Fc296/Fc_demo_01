extends PanelBase
class_name ContainerPanel

## 【UI 层 · 容器面板】背包 / 箱子 / 商店 / 锻造材料区都是它 —— 谁的容器传进来就画谁。
## 分工：面板不存数据，只做投影；容器变了 → 容器发 changed → 这里重画。
## 用法：panel.open(player.inventory) / panel.open(chest_inventory)；商店的买卖规则压在它外面。
## 完整说明与两个坑见《脚本说明.md》→ ui/panels/container_panel.gd

## ——— 接口清单（待实现）———

@export var slot_scene: PackedScene
@export var preset_slots: bool = false     # true = 格子已经在场景里摆好了（装备栏），不要自动生成

@onready var grid: GridContainer = get_node_or_null("%Grid")   # 预摆模式可以没有 Grid

var container: InventoryData        # open() 注入，面板里不 new


func open(target: InventoryData) -> void:   # 绑定容器 → 建格子 → 显示 → connect changed
	# ⚠️ 换容器前必须先断开旧的，否则旧容器一变，这个面板也会跟着重画
	if container != null and container.changed.is_connected(_on_container_changed):
		container.changed.disconnect(_on_container_changed)
	container = target
	_build_slots()
	if container != null:
		container.changed.connect(_on_container_changed)
	_refresh_all()
	show()


func close() -> void:
	super()


func toggle_with(target) -> void:
	if visible:
		close()
	else:
		open(target)


func _build_slots() -> void:
	if container == null:
		return                                   # 没有容器就没什么可绑的（这行别丢）

	if preset_slots:
		# 预摆模式：格子已经在场景里了，只要把"容器 + 序号"绑上去
		for slot in find_children("*", "Slot", true, false):
			if slot.slot_index < 0:
				push_error("ContainerPanel[%s]：格子 %s 没填 slot_index" % [name, slot.name])
				continue
			slot.set_source(container, slot.slot_index)
		return                                   # ← 预摆模式到此结束，下面全是自动模式的活

	# 自动模式：没有 %Grid 就没法建格子，别静默退出
	if grid == null:
		push_error("ContainerPanel[%s]：自动模式需要场景里有 %%Grid，或者勾上 preset_slots" % name)
		return
	if grid.get_child_count() == container.slot_count:
		return                                   # 格子数没变就别重建

	for child in grid.get_children():
		grid.remove_child(child)      # 立刻从树上摘掉
		child.queue_free()            # 再排队释放
	for i in container.slot_count:
		var slot: Slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.set_source(container, i)


func _refresh_all() -> void:
	# ⚠️ owned 必须传 false：运行时 add_child 出来的格子 owner 是 null，
	#    默认的 owned=true 只认"场景文件里本来就有的节点"，会把背包那 36 格全漏掉
	for slot in find_children("*", "Slot", true, false):
		slot.refresh()


func _on_container_changed() -> void:
	_refresh_all()
