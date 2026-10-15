extends RefCounted
class_name Element

#最后那行能这么省事，是因为"三种元素正好构成闭环"——所以只要不是克制、不是同元素，就必然是被克制。
#将来你加第 4 种元素时，这里会静默算错（新元素和老元素之间可能既不是克制也不是被克），到时候必须改成显式的 3×3 表。
#这种"依赖隐含前提"的写法一定要在代码里标出来，否则半年后你自己会踩。

enum Type { NONE, LIGHT, ROCK, WIND }

const ADVANTAGE := 1.3        # 克制
const DISADVANTAGE := 0.75    # 被克制

static func multiplier(attack: Type, defend: Type) -> float:
	if attack == Type.NONE or defend == Type.NONE or attack == defend:
		return 1.0
	var beats := {Type.ROCK: Type.WIND, Type.WIND: Type.LIGHT, Type.LIGHT: Type.ROCK}
	if beats.get(attack, Type.NONE) == defend:
		return ADVANTAGE
	return DISADVANTAGE
