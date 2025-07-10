class_name CardData extends RefCounted
#RefCounted means it doesn't get cleaned up in memory if nothing is using it anymore? i think?

var suit: String
var rank: String
var value: int

func _init(s: String, r: String, v: int):
	suit = s
	rank = r
	value = v
