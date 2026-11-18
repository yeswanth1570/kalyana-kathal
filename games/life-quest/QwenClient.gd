extends Node

signal replied(data: Dictionary)
signal failed(message: String)
var endpoint := ""
var access_code := ""
var busy := false
var request: HTTPRequest
var health: HTTPRequest

func _ready() -> void:
	request = HTTPRequest.new()
	request.timeout = 85
	add_child(request)
	request.request_completed.connect(_completed)
	health = HTTPRequest.new()
	health.timeout = 4
	add_child(health)
	health.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
		var data = JSON.parse_string(body.get_string_from_utf8())
		if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not data is Dictionary or not data.get("ready",false):
			failed.emit("Qwen is unavailable"))

func cancel() -> void:
	request.cancel_request()
	health.cancel_request()
	busy = false

func _valid_address(address: String) -> bool:
	return address.begins_with("https://") or address.begins_with("http://127.0.0.1:") or address.begins_with("http://localhost:")

func check_connection() -> void:
	health.cancel_request()
	var address := endpoint.strip_edges().trim_suffix("/")
	if not _valid_address(address):
		failed.emit("Use your PC’s HTTPS relay address.")
		return
	var error := health.request(address+"/api/health",PackedStringArray(["Authorization: Bearer "+access_code]))
	if error != OK: failed.emit("Qwen is unavailable")

func send_message(text: String, stage: int, phase: int, approval: int, history: Array) -> void:
	if busy:
		return
	if endpoint.is_empty() or access_code.is_empty():
		failed.emit("Connect Qwen on your PC first. Open Settings > Connect Qwen.")
		return
	var address := endpoint.strip_edges().trim_suffix("/")
	if not _valid_address(address):
		failed.emit("Use your PC's HTTPS relay address, or localhost for a desktop test.")
		return
	busy = true
	var headers := PackedStringArray(["Content-Type: application/json", "Authorization: Bearer " + access_code])
	var body := {"text":text,"stage":stage,"phase":phase,"approval":approval,"history":history.slice(-8)}
	var error := request.request(address+"/api/chat",headers,HTTPClient.METHOD_POST,JSON.stringify(body))
	if error != OK:
		busy = false
		failed.emit("Could not connect to the PC. Check the relay, then retry.")

func _completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	busy = false
	if result != HTTPRequest.RESULT_SUCCESS:
		failed.emit("Qwen did not respond. Keep the PC and relay running, then retry.")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not data is Dictionary:
		failed.emit("The PC returned an invalid reply. Please retry.")
	elif code != 200:
		failed.emit(str(data.get("error","Qwen is unavailable. Please retry.")))
	elif not data.get("reply") is String or data.get("source") != "qwen":
		failed.emit("The server did not return a Qwen character reply.")
	else:
		replied.emit(data)
