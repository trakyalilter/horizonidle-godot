extends Label

func setup(text_val: String, color: Color, start_pos: Vector2):
	text = text_val
	modulate = color
	position = start_pos
	
	# Animation (Pop + Float + Fade)
	scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move Up
	tween.tween_property(self, "position", start_pos + Vector2(0, -60), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fade Out
	tween.tween_property(self, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	# Scale Pop
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	tween.chain().tween_callback(queue_free)
