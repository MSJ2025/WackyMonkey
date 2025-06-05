extends Node

const FIREBASE_PROJECT_ID = "wackymonkey-924a8"
const BASE_URL = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/leaderboard" % FIREBASE_PROJECT_ID

# Vérifie si le pseudo est unique (pas utilisé par un autre device)
func check_pseudo_unique(pseudo: String, device_id: String, callback):
    var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:runQuery" % FIREBASE_PROJECT_ID
    var headers = ["Content-Type: application/json"]
    var body = {
        "structuredQuery": {
            "from": [{"collectionId": "leaderboard"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "pseudo"},
                    "op": "EQUAL",
                    "value": {"stringValue": pseudo}
                }
            }
        }
    }
    var http = HTTPRequest.new()
    get_tree().root.add_child(http)

    http.request_completed.connect(func(result, code, headers, body):
        if result != HTTPRequest.RESULT_SUCCESS or code != 200:
            push_error("Erreur HTTP ou requête échouée: %d" % code)
            if callback:
                callback.call(false)
            http.queue_free()
            return
        var data = JSON.parse_string(body.get_string_from_utf8())
        var unique = true
        for row in data:
            if row.has("document"):
                var fields = row["document"]["fields"]
                if fields.has("device_id") and fields["device_id"]["stringValue"] != device_id:
                    unique = false
        callback.call(unique)
        http.queue_free()
    )

    http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# Enregistre le score et la hauteur sur Firestore uniquement si meilleur score
func submit_score_if_best(pseudo: String, score: int, device_id: String, best_height: int, callback):
    check_pseudo_unique(pseudo, device_id, func(is_unique):
        if not is_unique:
            print("Ce pseudo appartient déjà à un autre joueur.")
            if callback:
                callback.call(false)
            return
        var url = BASE_URL + "/" + device_id
        var http = HTTPRequest.new()
        get_tree().root.add_child(http)

        http.request_completed.connect(func(result, code, headers, body):
            if result != HTTPRequest.RESULT_SUCCESS:
                push_error("Erreur HTTP: %d" % code)
                if callback:
                    callback.call(false)
                http.queue_free()
                return
            var can_submit = true
            if code == 200:
                var data = JSON.parse_string(body.get_string_from_utf8())
                var old_score = -1
                var old_best_height = -1
                if "fields" in data:
                    if "score" in data.fields:
                        old_score = int(data.fields.score.integerValue)
                    if "best_height" in data.fields:
                        old_best_height = int(data.fields.best_height.integerValue)
                if score <= old_score and best_height <= old_best_height:
                    can_submit = false
            if can_submit:
                _patch_score(pseudo, score, device_id, best_height, callback)
            else:
                if callback:
                    callback.call(false)
            http.queue_free()
        )

        http.request(url, [], HTTPClient.METHOD_GET)
    )

# PATCH le score et la hauteur dans la doc du device_id
func _patch_score(pseudo: String, score: int, device_id: String, best_height: int, callback = null):
    var url = BASE_URL + "/" + device_id
    var headers = ["Content-Type: application/json"]
    var body = {
        "fields": {
            "pseudo": {"stringValue": pseudo},
            "score": {"integerValue": str(score)},
            "device_id": {"stringValue": device_id},
            "best_height": {"integerValue": str(best_height)}
        }
    }
    var http = HTTPRequest.new()
    get_tree().root.add_child(http)

    http.request_completed.connect(func(result, response_code, headers, body):
        if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
            push_error("Erreur HTTP: %d" % response_code)
            if callback != null:
                callback.call(false)
            http.queue_free()
            return
        print("Submit Score:", response_code, body.get_string_from_utf8())
        if callback != null:
            callback.call(true)
        http.queue_free()
    )

    http.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(body))

# Récupère les meilleurs scores Firestore (triés par score)
func fetch_top_scores(callback):
    var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:runQuery" % FIREBASE_PROJECT_ID
    var headers = ["Content-Type: application/json"]
    var body = {
        "structuredQuery": {
            "from": [{"collectionId": "leaderboard"}],
            "orderBy": [{
                "field": {"fieldPath": "score"},
                "direction": "DESCENDING"
            }],
            "limit": 20
        }
    }
    var http = HTTPRequest.new()
    get_tree().root.add_child(http)

    http.request_completed.connect(func(result, response_code, headers, body):
        if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
            push_error("Erreur HTTP: %d" % response_code)
            if callback:
                callback.call(false)
            http.queue_free()
            return
        var data = JSON.parse_string(body.get_string_from_utf8())
        var scores = []
        for row in data:
            if row.has("document"):
                var fields = row["document"]["fields"]
                var pseudo = "???"
                var score = 0
                var best_height = 0
                if fields.has("pseudo"):
                    pseudo = fields["pseudo"]["stringValue"]
                if fields.has("score"):
                    score = int(fields["score"]["integerValue"])
                if fields.has("best_height"):
                    best_height = int(fields["best_height"]["integerValue"])
                else:
                    best_height = score
                scores.append({
                    "pseudo": pseudo,
                    "score": score,
                    "best_height": best_height
                })
        callback.call(scores)
        http.queue_free()
    )

    http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
