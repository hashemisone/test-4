extends RefCounted
class_name ShopPrices


static func buy_price(item: ItemData, kept_market: bool) -> int:
	var price := 4
	if item.is_potion():
		price = 3
	elif item.rarity == ItemData.Rarity.UNCOMMON:
		price = 8
	if kept_market:
		price *= 10
	return price


static func sell_price(item: ItemData, kept_market: bool) -> int:
	var price := 2
	if item.is_potion():
		price = 1
	elif item.rarity == ItemData.Rarity.UNCOMMON:
		price = 4
	if kept_market:
		price *= 10
	return price
