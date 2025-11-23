extends Node2D

# Fungsi ini akan dipanggil oleh main.gd
func play_bgm_for_turn(turn_number: int) -> void:
	
	print("--- AUDIO DEBUG: Diminta memainkan BGM untuk turn: ", turn_number)
	
	# 1. Matikan semua BGM
	get_tree().call_group("BGM", "stop")
	
	# 2. Buat nama node
	var node_name = "BGM_Turn" + str(turn_number)
	print("--- AUDIO DEBUG: Mencari node bernama: ", node_name)
	
	# 3. Cari node itu dan mainkan
	var bgm_node = find_child(node_name)
	
	if is_instance_valid(bgm_node):
		print("--- AUDIO DEBUG: Node ditemukan! Memainkan...")
		bgm_node.play()
	else:
		print("--- AUDIO DEBUG: !!! GAGAL !!! Node TIDAK ditemukan.")
		# Fallback: Mainkan BGM pertama jika turn 7 atau aneh
		var fallback_bgm = $BGM_Turn1
		if is_instance_valid(fallback_bgm) and not fallback_bgm.is_playing():
			print("--- AUDIO DEBUG: Memainkan BGM fallback (Turn 1).")
			fallback_bgm.play()
