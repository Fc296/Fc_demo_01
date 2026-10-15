extends DeadState


func _on_death_done() -> void: 
	actor.queue_free()
