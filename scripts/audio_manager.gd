extends Node2D

# Dipanggil oleh main.gd untuk memainkan BGM sesuai nomor turn
func play_bgm_for_turn(turn_number: int) -> void:
	print("Audio: Play BGM for turn", turn_number)

	# Matikan semua BGM di grup
	get_tree().call_group("BGM", "stop")

	# Bentuk nama node yang dicari
	var node_name = "BGM_Turn" + str(turn_number)
	print("Audio: Searching node:", node_name)

	# Cari child dengan nama tersebut dan mainkan
	var bgm_node = find_child(node_name)

	if is_instance_valid(bgm_node):
		print("Audio: Node ditemukan — memulai playback.")
		bgm_node.play()
	else:
		print("Audio: Node tidak ditemukan — coba fallback.")
		# Fallback: mainkan BGM Turn1 jika tersedia
		var fallback_bgm = $BGM_Turn1
		if is_instance_valid(fallback_bgm) and not fallback_bgm.is_playing():
			print("Audio: Memainkan BGM fallback (Turn 1).")
			fallback_bgm.play()

# Hentikan semua BGM
func stop_all_bgm() -> void:
	print("Audio: Stop all BGM.")
	get_tree().call_group("BGM", "stop")
