extends Node3D
## Put on a prop's root node. The player's E key calls interact().

@export var display_name := ""

func interact():
	var seq = get_tree().get_first_node_in_group("sequence")
	if seq:
		seq.try_interact(self)

func get_display_name() -> String:
	return display_name if display_name != "" else String(name)
