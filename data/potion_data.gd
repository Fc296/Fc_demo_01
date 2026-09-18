extends ItemBase
class_name PotionData

## 【数据层 · 药水 / 消耗品】
##
## PotionData : ItemBase —— 只回答一个问题：喝下去回多少血。
##
## 本类多出来的字段：
##   value         回复量。填负数就是"毒药"——机制上不用另开一个类，这就是数据驱动的意义
##   duration      大于 0 表示"持续回复"，配合 value 每秒回一次；等于 0 就是一口回满
##
## 谁用它：Slot 接到"使用"操作 → InventoryData 找到物品 → 让 PlayerStats 执行效果
##
## 使用流程（顺序很重要，照着写就不会出 bug）：
##   1. Slot 发出"使用第 3 格"
##   2. InventoryData 检查第 3 格是不是能用的东西
##   3. 把 value 交给 PlayerStats，让它改血量（数据类永远不碰角色状态）
##   4. 效果成功执行后，才从背包扣掉 1 个
##   —— 先扣物品后执行效果，中间一旦出错（比如血量已满不该扣）就会出现"药没了血没加"
##
## ——— 接口清单 ———
# @export var value: float = 20.0        # 命名约定：一次动作的"量"统一叫 value（见 event_bus.gd）
# @export var duration: float = 0.0     # 0 = 立即回复；>0 = 持续回复的秒数
# @export var consume_sound: AudioStream
