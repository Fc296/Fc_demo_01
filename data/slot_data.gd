extends Resource
class_name SlotData

## 【数据层 · 一个格子里装的东西】
##
## 一个格子 = 一件物品 + 数量。就这两样，不多不少。
##
## ★ 为什么要有这个类，而不是直接用 Dictionary（写 {"item": x, "count": 3}）：
##     类型安全   写 item 拼成 itme 时，Dictionary 只会静悄悄给你 null（不报错、
##                不崩、就是不对），SlotData 会当场报错，一眼就能发现
##     能扩展     以后要给格子加"耐久""附魔词条""绑定角色""制造者"，
##                在这里加一个字段，所有读它的地方都能被编辑器提示到；
##                用 Dictionary 就只能靠脑子记，还得记得存档里也补一行
##     看得见     调试时在检查器里能直接展开看清内容
##   代价只有一个：存档时要多写一个"转字典"的小函数（见下面的 to_dict）。
##
## ★ 谁是"空"：约定 **空格子 = null**（`slots[3] == null`）。
##   不要另外造一个 count = 0 的"空壳对象" —— 两套"空"的表示方式，
##   迟早有一天会对不上，然后你就会遇到"明明没东西却占着一个格子"。
##
## 铁律：SlotData 不认识 UI，也不认识"用掉之后会发生什么"。
##   它只回答"这一格放了什么、放了几个"。
##
## ——— 接口清单（待实现，需要时把下面的注释打开）———
# @export var item: ItemBase
# @export var count: int = 1
#
# func is_empty() -> bool                            # count <= 0 或 item == null
# func clear() -> void                               # 清空这一格（item = null, count = 0）
# func to_dict() -> Dictionary                       # 存档：{"id": 物品id, "count": 数量}
# static func from_dict(d: Dictionary) -> SlotData   # 读档：按 id 从物品表里还原 ItemBase
