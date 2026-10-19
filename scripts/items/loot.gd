extends RefCounted
class_name Loot

# Index matches ItemData.Rarity. A later rarity keeps a smaller base weight.
const RARITY_WEIGHTS: Array[int] = [100, 25]
const LEVEL_STEP := 15

const FAMILIES: Array = [
	["res://resources/items/sword.tres", "res://resources/items/sword_uncommon.tres"],
	["res://resources/items/greatsword.tres", "res://resources/items/greatsword_uncommon.tres"],
	["res://resources/items/armor.tres", "res://resources/items/armor_uncommon.tres"],
	["res://resources/items/helmet.tres", "res://resources/items/helmet_uncommon.tres"],
	["res://resources/items/boots.tres", "res://resources/items/boots_uncommon.tres"],
	["res://resources/items/offhand.tres", "res://resources/items/offhand_uncommon.tres"],
	["res://resources/items/charm.tres", "res://resources/items/charm_uncommon.tres"],
	["res://resources/items/cape.tres", "res://resources/items/cape_uncommon.tres"],
	["res://resources/items/pants.tres", "res://resources/items/pants_uncommon.tres"],
	["res://resources/items/bracelet.tres", "res://resources/items/bracelet_uncommon.tres"],
	["res://resources/items/gloves.tres", "res://resources/items/gloves_uncommon.tres"],
	["res://resources/items/health_potion.tres"],
	["res://resources/items/attack_potion.tres"],
	["res://resources/items/coin.tres"],
]


static func roll(enemy_level: int) -> ItemData:
	var rarity := _roll_rarity(enemy_level)
	var family: Array = FAMILIES[randi() % FAMILIES.size()]
	var path: String = family[mini(rarity, family.size() - 1)]
	var template := load(path) as ItemData
	var copy := template.roll_copy()
	if copy.is_coin():
		copy.coin_amount = randi_range(1, 3)
	return copy


static func _roll_rarity(enemy_level: int) -> int:
	var total := 0
	for rarity in RARITY_WEIGHTS.size():
		total += _weight(rarity, enemy_level)
	var pick := randi_range(1, total)
	var running := 0
	for rarity in RARITY_WEIGHTS.size():
		running += _weight(rarity, enemy_level)
		if pick <= running:
			return rarity
	return ItemData.Rarity.COMMON


static func _weight(rarity: int, enemy_level: int) -> int:
	var base := RARITY_WEIGHTS[rarity]
	var level := maxi(enemy_level, 1)
	return maxi(base * (100 + (level - 1) * rarity * LEVEL_STEP) / 100, 1)
