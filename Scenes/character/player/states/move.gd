extends State

## 【状态 · 主角移动】
##
## 这个文件同样留给你填：
##   enter()          播 walk 动画
##   physics_update() 读输入 → actor.velocity = 方向 * 速度 → actor.move_and_slide()
##                    没有输入 → machine.transition_to("idle")
##
## ★ 移动一定要写在 physics_update 里，不要写在 update 里：
##   update 跑在渲染帧上，帧率一变移动速度就跟着漂；物理帧是固定步长。
##
## 提醒：转向、播动画都调 actor 上的方法（Actor 是三个角色共用的"身体"），
## 不要把"怎么转向"写进这个状态里 —— 那样怪物也要再写一遍。
