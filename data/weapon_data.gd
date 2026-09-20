extends ItemBase
class_name WeaponData

## 【数据层 · 武器】多出"怎么打人"的数值和"拿在手里长什么样"的贴图，依然只是数据。
## 要点：武器不算伤害，只是数值的容器；真正扣血统一在 Actor.take_damage()。
## 背包里看 icon（小图），手上看 hold_texture（大图）。详见《脚本说明.md》→ data/weapon_data.gd

## ——— 接口清单（待实现）———
# @export var damage: float = 1.0
# @export var cooldown: float = 0.4            # 两次攻击的间隔（秒）
# @export var attack_range: float = 24.0
# @export var hold_texture: Texture2D          # 手持图（素材包里叫 SpriteInHand.png）
# @export var hold_offset: Vector2 = Vector2.ZERO
