extends Node
class_name ShopManager
var player_gold:int = 5000

func can_buy(price:int)->bool:
	return player_gold>=price

func buy(price:int):
	player_gold-=price
