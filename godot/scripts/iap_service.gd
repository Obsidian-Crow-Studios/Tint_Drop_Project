extends Node
class_name IapService

## Catalog + restore + purchase request.
## Godot 4.7 has no built-in store API. Mobile billing is plugin-optional:
## iOS StoreKit 2 via ClassDB "GodotStoreKit2"; Android Play Billing via
## class_name BillingClient (JNI singleton GodotGooglePlayBilling).
## Editor / F5 desktop never charges. Missing plugin uses the unpaid path.

const PRODUCT_PREFIX := "com.obsidiancrow.tintdrop."
const STEAM_LIST_PRICE := "$7.99"
const UNPAID_TOAST := "Not billed yet."
const DEBUG_GRANT_TOAST := "Debug grant. Not billed."

## Locked 2026-08-28 sku_id list. Prices stay on SHOP_SKUS in main.gd.
const SKU_IDS: PackedStringArray = [
	"remove_ads",
	"extra_well",
	"undo_pack",
	"color_bomb",
	"booster_starter",
	"well_skin",
	"cosmetic_track",
]

const KIND_NONCONSUMABLE := "nonconsumable"
const KIND_CONSUMABLE := "consumable"
const KIND_BUNDLE := "bundle"
const KIND_TIMED := "timed"

signal purchase_finished(sku_id: String, status: String, message: String)

var _progress: TintProgress
var _store_kit: Object
var _android: Object
var _pending_sku: String = ""
var _android_ready: bool = false


func store_product_id(sku_id: String) -> String:
	return PRODUCT_PREFIX + sku_id


func sku_from_product_id(product_id: String) -> String:
	if product_id.begins_with(PRODUCT_PREFIX):
		return product_id.substr(PRODUCT_PREFIX.length())
	return product_id


func sku_kind(sku_id: String) -> String:
	match sku_id:
		"remove_ads", "well_skin":
			return KIND_NONCONSUMABLE
		"booster_starter":
			return KIND_BUNDLE
		"cosmetic_track":
			return KIND_TIMED
		"extra_well", "undo_pack", "color_bomb":
			return KIND_CONSUMABLE
		_:
			return ""


func is_store_consumable(sku_id: String) -> bool:
	var kind: String = sku_kind(sku_id)
	return kind == KIND_CONSUMABLE or kind == KIND_TIMED


func catalog_product_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for sku_id in SKU_IDS:
		ids.append(store_product_id(sku_id))
	return ids


func is_steam_build() -> bool:
	return OS.has_feature("steam") or OS.has_feature("Steam")


func shows_mobile_catalog() -> bool:
	return not is_steam_build()


func is_editor_or_desktop() -> bool:
	if OS.has_feature("editor"):
		return true
	var name: String = OS.get_name()
	return name == "Windows" or name == "macOS" or name == "Linux" or name == "FreeBSD" or name == "BSD"


func billing_plugin_present() -> bool:
	if OS.get_name() == "iOS" and ClassDB.class_exists("GodotStoreKit2"):
		return true
	if OS.get_name() == "Android" and (
		Engine.has_singleton("GodotGooglePlayBilling") or ClassDB.class_exists("BillingClient")
	):
		return true
	return false


func can_charge() -> bool:
	if is_editor_or_desktop():
		return false
	if is_steam_build():
		return false
	return billing_plugin_present()


func setup(progress: TintProgress) -> void:
	_progress = progress
	if is_steam_build() and _progress != null:
		_progress.apply_steam_paid_app()
	_bind_store_plugins()


func debug_grant_allowed(sku_id: String) -> bool:
	if not OS.is_debug_build() and not OS.has_feature("editor"):
		return false
	var flag: String = OS.get_environment("TINT_DROP_IAP_GRANT").strip_edges()
	if flag.is_empty():
		return false
	var f: String = flag.to_lower()
	if f == "1" or f == "true" or f == "all":
		return true
	return f == sku_id or f == sku_id.to_lower()


func request_purchase(sku_id: String) -> Dictionary:
	if sku_kind(sku_id).is_empty():
		return _result("unpaid", UNPAID_TOAST)
	if is_steam_build():
		return _result("unavailable", "Steam paid app. No mobile IAP.")
	if _already_owned(sku_id):
		return _result("owned", "Owned.")
	if debug_grant_allowed(sku_id):
		_grant(sku_id)
		return _result("debug", DEBUG_GRANT_TOAST)
	if can_charge():
		if _start_store_purchase(sku_id):
			_pending_sku = sku_id
			return _result("pending", "")
		return _result("unpaid", UNPAID_TOAST)
	return _result("unpaid", UNPAID_TOAST)


func restore_purchases() -> void:
	if not can_charge():
		return
	if _store_kit != null and _store_kit.has_method("sync"):
		_store_kit.call("sync")
		_query_ios_owned()
		return
	if _android != null and _android_ready and _android.has_method("query_purchases"):
		_android.call("query_purchases", _android_inapp_type())


func _result(status: String, message: String) -> Dictionary:
	return {"status": status, "message": message}


func _already_owned(sku_id: String) -> bool:
	if _progress == null:
		return false
	match sku_id:
		"remove_ads":
			return _progress.remove_ads
		"well_skin":
			return _progress.well_skin
		"booster_starter":
			return _progress.booster_starter
		"cosmetic_track":
			return _progress.cosmetic_track_active()
		_:
			return false


func _grant(sku_id: String) -> void:
	if _progress == null:
		return
	_progress.apply_sku(sku_id)


func _bind_store_plugins() -> void:
	if is_editor_or_desktop() or is_steam_build():
		return
	if OS.get_name() == "iOS" and ClassDB.class_exists("GodotStoreKit2"):
		_store_kit = ClassDB.instantiate("GodotStoreKit2")
		if _store_kit is Node:
			add_child(_store_kit)
		if _store_kit != null and _store_kit.has_signal("transaction_state_changed"):
			_store_kit.connect("transaction_state_changed", _on_ios_transaction)
		if _store_kit != null and _store_kit.has_signal("product_info_received"):
			_store_kit.connect("product_info_received", _on_ios_product_info)
		_query_ios_catalog()
		return
	if OS.get_name() == "Android" and ClassDB.class_exists("BillingClient"):
		_android = ClassDB.instantiate("BillingClient")
		if _android is Node:
			add_child(_android)
		if _android == null:
			return
		if _android.has_signal("connected"):
			_android.connect("connected", _on_android_connected)
		if _android.has_signal("on_purchase_updated"):
			_android.connect("on_purchase_updated", _on_android_purchase_updated)
		if _android.has_signal("query_purchases_response"):
			_android.connect("query_purchases_response", _on_android_query_purchases)
		if _android.has_method("start_connection"):
			_android.call("start_connection")


func _query_ios_catalog() -> void:
	if _store_kit == null or not _store_kit.has_method("request_product_info"):
		return
	for sku_id in SKU_IDS:
		_store_kit.call("request_product_info", store_product_id(sku_id))


func _query_ios_owned() -> void:
	_query_ios_catalog()


func _start_store_purchase(sku_id: String) -> bool:
	var product_id: String = store_product_id(sku_id)
	if _store_kit != null and _store_kit.has_method("purchase_product"):
		_store_kit.call("purchase_product", product_id, 1)
		return true
	if _android != null and _android_ready and _android.has_method("purchase"):
		var launch: Variant = _android.call("purchase", product_id)
		if typeof(launch) == TYPE_DICTIONARY:
			var code: int = int((launch as Dictionary).get("response_code", 0))
			return code == 0
		return true
	return false


func _on_ios_transaction(transaction: Dictionary) -> void:
	if not str(transaction.get("error", "")).is_empty():
		if not _pending_sku.is_empty():
			purchase_finished.emit(_pending_sku, "unpaid", UNPAID_TOAST)
			_pending_sku = ""
		return
	var product_id: String = str(transaction.get("product_id", ""))
	var sku_id: String = sku_from_product_id(product_id)
	if sku_id.is_empty():
		sku_id = _pending_sku
	var state: Variant = transaction.get("transaction_state", -1)
	var purchased: bool = _ios_state_is_purchased(state)
	var restored: bool = _ios_state_is_restored(state)
	if purchased or restored:
		if not restored or not is_store_consumable(sku_id):
			_grant(sku_id)
		var status: String = "restored" if restored else "granted"
		purchase_finished.emit(sku_id, status, "Unlocked.")
	_pending_sku = ""


func _on_ios_product_info(product_info: Dictionary) -> void:
	if not str(product_info.get("error", "")).is_empty():
		return
	if not bool(product_info.get("is_purchased", false)):
		return
	var sku_id: String = sku_from_product_id(str(product_info.get("product_id", "")))
	if is_store_consumable(sku_id):
		return
	if _already_owned(sku_id):
		return
	_grant(sku_id)
	purchase_finished.emit(sku_id, "restored", "Unlocked.")


func _ios_state_is_purchased(state: Variant) -> bool:
	if typeof(state) == TYPE_STRING:
		return str(state) == "PURCHASED"
	# GodotStoreKit2 TransactionState: FAILED, REFUNDED, PENDING, PURCHASED, RESTORED, ...
	return int(state) == 3


func _ios_state_is_restored(state: Variant) -> bool:
	if typeof(state) == TYPE_STRING:
		return str(state) == "RESTORED"
	return int(state) == 4


func _on_android_connected() -> void:
	_android_ready = true
	if _android != null and _android.has_method("query_product_details"):
		_android.call("query_product_details", catalog_product_ids(), _android_inapp_type())
	if _android != null and _android.has_method("query_purchases"):
		_android.call("query_purchases", _android_inapp_type())


func _on_android_purchase_updated(response: Dictionary) -> void:
	_handle_android_purchases(response, false)


func _on_android_query_purchases(response: Dictionary) -> void:
	_handle_android_purchases(response, true)


func _handle_android_purchases(response: Dictionary, from_restore: bool) -> void:
	if int(response.get("response_code", 0)) != 0:
		if not from_restore:
			purchase_finished.emit(_pending_sku, "unpaid", UNPAID_TOAST)
			_pending_sku = ""
		return
	var purchases: Variant = response.get("purchases", [])
	if typeof(purchases) != TYPE_ARRAY:
		return
	for item in purchases:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		_process_android_purchase(item as Dictionary, from_restore)


func _process_android_purchase(purchase: Dictionary, from_restore: bool) -> void:
	# PurchaseState.PURCHASED == 1
	if int(purchase.get("purchase_state", 0)) != 1:
		return
	var ids: Variant = purchase.get("product_ids", [])
	var sku_id: String = ""
	if typeof(ids) == TYPE_ARRAY and (ids as Array).size() > 0:
		sku_id = sku_from_product_id(str((ids as Array)[0]))
	elif _pending_sku != "":
		sku_id = _pending_sku
	if sku_kind(sku_id).is_empty():
		return
	if from_restore and is_store_consumable(sku_id):
		return
	_grant(sku_id)
	var token: String = str(purchase.get("purchase_token", ""))
	if is_store_consumable(sku_id):
		if _android != null and _android.has_method("consume_purchase") and not token.is_empty():
			_android.call("consume_purchase", token)
	else:
		if not bool(purchase.get("is_acknowledged", true)):
			if _android != null and _android.has_method("acknowledge_purchase") and not token.is_empty():
				_android.call("acknowledge_purchase", token)
	var status: String = "restored" if from_restore else "granted"
	purchase_finished.emit(sku_id, status, "Unlocked.")
	_pending_sku = ""


func _android_inapp_type() -> Variant:
	# BillingClient.ProductType.INAPP == 0
	return 0
