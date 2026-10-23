extends Node2D
class_name EnemySpawner

## 【场景层 · 刷怪点】我站的位置就是这个怪的出生地。怪死了，等一会儿在原地再刷一只满血的。
## 为什么不让敌人自己重生：敌人死后 queue_free，它记不住自己从哪来；出生点必须由场景持有。
## 坑：respawn_delay 必须大于死亡动画时长（敌人是 1.2 秒），
##     否则尸体会和新怪叠在一起。

## 刷什么怪（检查器里拖 enemy.tscn）。
@export var enemy_scene: PackedScene
## 怪死后多少秒刷新。
@export var respawn_delay: float = 5.0
## 进场景就先刷一只。
@export var spawn_on_ready: bool = true

var _alive: Actor = null


func _ready() -> void:
	if spawn_on_ready:
		_spawn()


func _spawn() -> void:
	if enemy_scene == null:
		push_warning("刷怪点没填 enemy_scene：%s" % name)
		return
	_alive = enemy_scene.instantiate() as Actor
	get_parent().add_child.call_deferred(_alive)               # 加到地图上，不要塞给刷怪点自己
	_alive.position = position      # 局部坐标：刷怪点和怪是兄弟节点，语义就是"站到我这儿"
	_alive.died.connect(_on_enemy_died)
	_alive.name = "%s_Enemy" % name              # 方便在远程场景树里认人


func _on_enemy_died() -> void:
	_alive = null
	await get_tree().create_timer(respawn_delay).timeout
	if not is_inside_tree():
		return                                    # 这期间场景重建过（比如读档），别再刷
	_spawn()
