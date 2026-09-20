extends State

## 【状态 · 主角待机】
##
## 这个文件留给你填，只有两三行：
##   enter()   播 idle 动画
##   update()  检测到移动输入 → machine.transition_to("move")
##
## 状态里可以直接用的东西（由状态机自动赋值，见 Scripts/state.gd）：
##   actor     宿主角色（例如 actor.play_anim("idle")）
##   machine   所属状态机（machine.transition_to("move")）
##
## 提醒：状态名 = 节点名 = 字符串，三处必须一致（这里是 "idle"）。
## 写错的话转移会静默失败，表现是"角色站着不动"，很难查。
