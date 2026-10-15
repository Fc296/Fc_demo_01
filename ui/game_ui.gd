extends CanvasLayer

@onready var bag_panel: ContainerPanel = %Conta_Panel
@onready var equip_panel: ContainerPanel = %Equip_Panel
@onready var stats_panel: PanelBase = %Stats_Panel
@onready var craft_panel: CraftPanel = %Craft_Panel
@onready var market_panel: MarketPanel = %Market_Panel
@onready var save_panel: SavePanel = %Save_Panel
@onready var chest_panel: ContainerPanel = %Chest_Panel


func _ready() -> void:
	add_to_group(&"game_ui")
	equip_panel.open(GameData.equipment)
	bag_panel.open(GameData.inventory)      # 绑容器 + 建格子，只做一次
	# 箱子面板先藏着（等玩家走到箱子旁按 E 才出现）
	chest_panel.hide()
	for p in [bag_panel, equip_panel, stats_panel, craft_panel, market_panel, save_panel]:
		p.hide()


## 箱子开口：把"箱子面板"打开并指向这个容器（背包面板不受影响）
func open_chest(target: InventoryData) -> ContainerPanel:
	chest_panel.open(target)
	return chest_panel
