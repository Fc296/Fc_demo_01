extends ItemBase
class_name EquipmentData

## 【数据层 · 防具 / 饰品等可穿戴物】
##
## EquipmentData : ItemBase —— 在"一件物品"的基础上加一个"戴在哪"。
##
## 本类多出来的字段：
##   equip_slot    装备部位枚举，决定这件东西能进哪个格子
##   sprite_frame  穿在身上后显示用的贴图
##                 （对应 Sprites/Equipment/placeholder_helmet|body|legs|ring|tool|weapon.png 这套素材）
##   bonus_*       穿戴时给角色的属性加成（防御、攻击、移速……）。脱下时原样减回去
##
## 部位枚举必须和 UI 上的装备格子一一对应，而且两边引用同一个枚举：
##   写 EquipmentData.Slot.HELMET，不要写字符串 "helmet"。
##   字符串写错了不报错、只是静默失效，是最难查的一类 bug。
##
## 谁用它：EquipmentPanel（六个固定格子）、PlayerStats（加减属性）
##
## 常见的坑：属性要"基础值 + 所有加成"重算，不要在东一件西一件时直接 += 到最终值上。
##   否则脱装顺序一变，数值就漂了
##
## ——— 接口清单 ———
# enum Slot { HELMET, BODY, LEGS, RING, TOOL, WEAPON }
#
# @export var equip_slot: Slot = Slot.WEAPON
# @export var sprite_frame: Texture2D
# @export var bonus_attack: float = 0.0
# @export var bonus_defense: float = 0.0
# @export var bonus_speed: float = 0.0
#
# func can_equip_into(target: Slot) -> bool     # 给 Slot 的 filter 用
