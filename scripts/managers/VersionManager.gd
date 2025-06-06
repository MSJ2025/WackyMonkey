extends Node

const CURRENT_VERSION := "1.0.1"
const VERSION_URL := "https://gist.githubusercontent.com/MSJ2025/4d20c7a04314d0a760b19bc41ae59c37/raw/c57b2d11e31f2efd827c4cf3ba27ad0fa6fbbcb9/version.txt"
const DOWNLOAD_URL := "https://example.com/download"
const UPDATE_THEME := preload("res://assets/themes/update_dialog_theme.tres")

func check_for_update() -> void:
    var http := HTTPRequest.new()
    get_tree().root.add_child(http)

    http.request_completed.connect(func(result, response_code, headers, body):
        http.queue_free()

        print("HTTP Result:", result, "Code:", response_code)

        if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
            push_error("Erreur lors de la vérification de la version: %d" % response_code)
            return

        var latest_version := (body as PackedByteArray).get_string_from_utf8().strip_edges()
        print("Version reçue:", latest_version)
        print("Version courante:", CURRENT_VERSION)

        if latest_version != CURRENT_VERSION:
            print("Nouvelle version détectée, affichage du dialogue")
            var dialog := ConfirmationDialog.new()
            dialog.title = "Mise à jour disponible"
            dialog.dialog_text = "Une nouvelle version (" + latest_version + ") est disponible.\n\nTélécharger : " + DOWNLOAD_URL
            dialog.ok_button_text = "Télécharger"
            dialog.cancel_button_text = "Plus tard"
            dialog.theme = UPDATE_THEME
            dialog.min_size = Vector2(500, 240)
            dialog.confirmed.connect(Callable(self, "_on_update_confirmed"))
            get_tree().root.add_child(dialog)
            dialog.popup_centered()
        else:
            print("Version à jour, pas besoin d'afficher le dialogue")
    )

    var error = http.request(VERSION_URL)
    if error != OK:
        push_error("Impossible d'envoyer la requête HTTP : %d" % error)
        http.queue_free()

func _on_update_confirmed() -> void:
    OS.shell_open(DOWNLOAD_URL)
