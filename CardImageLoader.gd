#extends Resource
#
#var card_textures = {}
#
#func _ready():	# Load all textures on startup
	#var suits = ["Hearts", "Diamonds", "Clubs", "Spades"]
	#var ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King", "Ace"]
	#
	#for suit in suits:
		#for rank in ranks:
			#var key = "%s_of_%s" % [rank, suit]
			#var path = "res://CardImages/%s_of_%s.png" % [rank, suit]
			#var texture = load(path)
			#if texture:
				#card_textures[key] = texture
			#else:
				#print("Failed to load: ", path)
#
#func get_card_texture(rank: String, suit: String) -> Texture2D:
	#var key = "%s_of_%s" % [rank, suit]
	#
	#if card_textures.has(key):
		#return card_textures[key]
	#else:
		#print("ERROR: Card texture not found for key: ", key)
		#return null
