extends Resource
class_name ItemBase

## 【数据层 · 所有物品的根基类】
##
## 一句话：ItemBase 描述"一件东西长什么样、能不能叠、属于哪一类"，是纯数据，不是行为。
##
## 为什么是 Resource 而不是 Node？
##   Resource 可以存成 .tres 文件：在编辑器「文件系统 → 右键 → 新建资源」里选 ItemBase，
##   然后像填表格一样填数值。策划改平衡、美术换图标都在编辑器里完成，不用碰代码。
##
## 继承链：ItemBase → WeaponData / PotionData / EquipmentData / SkillData
## 谁会用到它：InventoryData（存它）、Slot（画它）、DropItem（掉它）、LootTable（抽它）
##
## 字段说明：
##   id            全局唯一字符串（约定写 &"iron_sword"）。存档、掉落表、合成配方都靠它认物品。
##                 千万不要拿"数组下标"当身份——重排一次数组，旧存档就全错位了
##   display_name  显示名（可以带翻译）
##   description   悬浮提示里的说明文字
##   icon          背包格子里画的那张图
##   max_stack     单格最多叠几个。1 = 不可叠（武器、装备就是 1）
##   type          分类枚举，用来做筛选、判断能不能装备、能不能吃
##   tags          自由标签，做"算不算材料""能不能当燃料"这类软判断。
##                 比 type 灵活——加新玩法时不用改枚举、不用改旧资源文件
##
## 三条铁律：
##   1. 子类只加数据，不加逻辑。"使用之后发生什么"由使用者决定
##      （药水在 PlayerStats 里加血、装备在 PlayerStats 里换部位）——数据与行为分离
##   2. type 和 max_stack 要自洽：消耗品可叠、装备不可叠
##   3. id 一旦发布就不要改，改 id 等于让所有引用它的地方（掉落表、存档）同时失效
##
## ——— 接口清单（待实现，需要时把下面的注释打开）———
# enum ItemType { MATERIAL, POTION, WEAPON, EQUIPMENT, SKILL, QUEST, KEY }
#
# @export var id: StringName = &""
# @export var display_name: String = ""
# @export_multiline var description: String = ""
# @export var icon: Texture2D
# @export var max_stack: int = 1
# @export var type: ItemType = ItemType.MATERIAL
# @export var tags: Array[StringName] = []
#
# func is_stackable() -> bool                       # max_stack > 1
# func can_stack_with(other: ItemBase) -> bool      # id 相同即可合并（能否装下由容器判断）
# func has_tag(tag: StringName) -> bool
