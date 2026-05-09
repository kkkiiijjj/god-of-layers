extends Node

# 图层操作信号
signal layer_reordered
signal layer_visibility_changed(layer_id: String, visible: bool)
signal layer_opacity_changed(layer_id: String, opacity: float)
signal layer_merged(layer_a_id: String, layer_b_id: String)
signal layer_copied(source_id: String, new_id: String)

# 谜题推进信号
signal puzzle_stage_changed(stage_index: int)
signal puzzle_completed

# 物件互动信号
signal item_grabbed(item: Node, from_layer_id: String)
signal item_dropped(item: Node, to_layer_id: String)

# 对话信号
signal dialogue_started(npc_id: String)
signal dialogue_ended

signal layer_copy_requested(layer_id: String)
