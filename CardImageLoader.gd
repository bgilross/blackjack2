# File: res://CardImageLoader.gd
# Purpose: An Autoload/Singleton script to preload all card textures at startup.
# This guarantees that the Godot exporter includes the images in the final build.

extends Node

# This dictionary forces the exporter to include every single image by using preload().
# The keys match the "Rank_of_Suit" format used to look them up.
const CARD_TEXTURES = {
	# --- Hearts ---
	"2_of_Hearts": preload("res://CardImages/2_of_Hearts.png"),
	"3_of_Hearts": preload("res://CardImages/3_of_Hearts.png"),
	"4_of_Hearts": preload("res://CardImages/4_of_Hearts.png"),
	"5_of_Hearts": preload("res://CardImages/5_of_Hearts.png"),
	"6_of_Hearts": preload("res://CardImages/6_of_Hearts.png"),
	"7_of_Hearts": preload("res://CardImages/7_of_Hearts.png"),
	"8_of_Hearts": preload("res://CardImages/8_of_Hearts.png"),
	"9_of_Hearts": preload("res://CardImages/9_of_Hearts.png"),
	"10_of_Hearts": preload("res://CardImages/10_of_Hearts.png"),
	"Jack_of_Hearts": preload("res://CardImages/Jack_of_Hearts.png"),
	"Queen_of_Hearts": preload("res://CardImages/Queen_of_Hearts.png"),
	"King_of_Hearts": preload("res://CardImages/King_of_Hearts.png"),
	"Ace_of_Hearts": preload("res://CardImages/Ace_of_Hearts.png"),

	# --- Diamonds ---
	"2_of_Diamonds": preload("res://CardImages/2_of_Diamonds.png"),
	"3_of_Diamonds": preload("res://CardImages/3_of_Diamonds.png"),
	"4_of_Diamonds": preload("res://CardImages/4_of_Diamonds.png"),
	"5_of_Diamonds": preload("res://CardImages/5_of_Diamonds.png"),
	"6_of_Diamonds": preload("res://CardImages/6_of_Diamonds.png"),
	"7_of_Diamonds": preload("res://CardImages/7_of_Diamonds.png"),
	"8_of_Diamonds": preload("res://CardImages/8_of_Diamonds.png"),
	"9_of_Diamonds": preload("res://CardImages/9_of_Diamonds.png"),
	"10_of_Diamonds": preload("res://CardImages/10_of_Diamonds.png"),
	"Jack_of_Diamonds": preload("res://CardImages/Jack_of_Diamonds.png"),
	"Queen_of_Diamonds": preload("res://CardImages/Queen_of_Diamonds.png"),
	"King_of_Diamonds": preload("res://CardImages/King_of_Diamonds.png"),
	"Ace_of_Diamonds": preload("res://CardImages/Ace_of_Diamonds.png"),

	# --- Clubs ---
	"2_of_Clubs": preload("res://CardImages/2_of_Clubs.png"),
	"3_of_Clubs": preload("res://CardImages/3_of_Clubs.png"),
	"4_of_Clubs": preload("res://CardImages/4_of_Clubs.png"),
	"5_of_Clubs": preload("res://CardImages/5_of_Clubs.png"),
	"6_of_Clubs": preload("res://CardImages/6_of_Clubs.png"),
	"7_of_Clubs": preload("res://CardImages/7_of_Clubs.png"),
	"8_of_Clubs": preload("res://CardImages/8_of_Clubs.png"),
	"9_of_Clubs": preload("res://CardImages/9_of_Clubs.png"),
	"10_of_Clubs": preload("res://CardImages/10_of_Clubs.png"),
	"Jack_of_Clubs": preload("res://CardImages/Jack_of_Clubs.png"),
	"Queen_of_Clubs": preload("res://CardImages/Queen_of_Clubs.png"),
	"King_of_Clubs": preload("res://CardImages/King_of_Clubs.png"),
	"Ace_of_Clubs": preload("res://CardImages/Ace_of_Clubs.png"),

	# --- Spades ---
	"2_of_Spades": preload("res://CardImages/2_of_Spades.png"),
	"3_of_Spades": preload("res://CardImages/3_of_Spades.png"),
	"4_of_Spades": preload("res://CardImages/4_of_Spades.png"),
	"5_of_Spades": preload("res://CardImages/5_of_Spades.png"),
	"6_of_Spades": preload("res://CardImages/6_of_Spades.png"),
	"7_of_Spades": preload("res://CardImages/7_of_Spades.png"),
	"8_of_Spades": preload("res://CardImages/8_of_Spades.png"),
	"9_of_Spades": preload("res://CardImages/9_of_Spades.png"),
	"10_of_Spades": preload("res://CardImages/10_of_Spades.png"),
	"Jack_of_Spades": preload("res://CardImages/Jack_of_Spades.png"),
	"Queen_of_Spades": preload("res://CardImages/Queen_of_Spades.png"),
	"King_of_Spades": preload("res://CardImages/King_of_Spades.png"),
	"Ace_of_Spades": preload("res://CardImages/Ace_of_Spades.png"),
}


# A helper function to get the preloaded texture from any other script.
# This prevents you from having to call load() dynamically.
func get_card_texture(rank: String, suit: String) -> Texture2D:
	var key = "%s_of_%s" % [rank, suit]
	
	if CARD_TEXTURES.has(key):
		return CARD_TEXTURES[key]
	else:
		# Fallback in case of an error, so the game doesn't crash.
		print("ERROR: Card texture not found for key: ", key)
		return null
