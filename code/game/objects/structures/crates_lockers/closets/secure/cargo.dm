/obj/structure/closet/secure_closet/quartermaster
	name = "\proper quartermaster's locker"
	req_access = list(ACCESS_QM)
	icon_state = "qm"

/obj/structure/closet/secure_closet/quartermaster/PopulateContents()
	..()
	new /obj/item/clothing/neck/cloak/qm(src)
	new /obj/item/clothing/under/rank/cargo(src)
	new /obj/item/clothing/shoes/sneakers/brown(src)
	new /obj/item/device/radio/headset/heads/qm(src)
	new /obj/item/clothing/suit/fire/firefighter(src)
	new /obj/item/clothing/gloves/fingerless(src)
	new /obj/item/device/megaphone/cargo(src)
	new /obj/item/tank/internals/emergency_oxygen(src)
	new /obj/item/clothing/mask/gas(src)
	new /obj/item/clothing/head/soft(src)
	new /obj/item/device/export_scanner(src)
	new /obj/item/door_remote/quartermaster(src)
