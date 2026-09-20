extends State

## 【状态 · 主角移动】留给你填：
##   enter()          播 walk 动画
##   physics_update() 读输入 → actor.face() → actor.velocity = 方向 * actor.move_speed()
##                    → actor.move_and_slide()；没输入 → transition_to("idle")
## 移动一定写 physics_update（物理帧固定步长），写 update 会随帧率漂。详见《脚本说明.md》→ states
