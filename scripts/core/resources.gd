extends Node

signal element_added(symbol, amount)
signal currency_added(type, amount)
signal element_removed(symbol, amount)

var elements: Dictionary = {}
var currencies: Dictionary = {}
var energy: float = 0.0
var max_energy: float = 1000.0

func _ready():
	pass

func add_element(symbol: String, amount: float):
	if not elements.has(symbol):
		elements[symbol] = 0.0
	elements[symbol] += amount
	element_added.emit(symbol, amount)
	
	if elements[symbol] < 0:
		elements[symbol] = 0.0

func remove_element(symbol: String, amount: float) -> bool:
	var current = elements.get(symbol, 0.0)
	if current >= amount:
		elements[symbol] = current - amount
		element_removed.emit(symbol, amount)
		return true
	return false

func get_element_amount(symbol: String) -> float:
	return elements.get(symbol, 0.0)

func add_currency(currency_type: String, amount: float):
	if not currencies.has(currency_type):
		currencies[currency_type] = 0.0
	currencies[currency_type] += amount
	currency_added.emit(currency_type, amount)

func remove_currency(currency_type: String, amount: float) -> bool:
	var current = currencies.get(currency_type, 0.0)
	if current >= amount:
		currencies[currency_type] = current - amount
		return true
	return false

func get_currency(currency_type: String) -> float:
	return currencies.get(currency_type, 0.0)

func add_energy(amount: float):
	energy += amount
	if energy > max_energy:
		energy = max_energy
	# Emit signal if needed

func get_save_data() -> Dictionary:
	return {
		"elements": elements,
		"currencies": currencies
	}

func load_save_data(data: Dictionary):
	if data.is_empty(): return
	elements = data.get("elements", {})
	currencies = data.get("currencies", {})
	
	# Fix types if JSON loaded ints
	for k in elements: elements[k] = float(elements[k])
	for k in currencies: currencies[k] = float(currencies[k])

func reset():
	elements.clear()
	currencies.clear()
	energy = 0.0
