extends Node

const CURRENT_VERSION := "1.0.0"
const VERSION_URL := "https://example.com/version.txt"
const DOWNLOAD_URL := "https://example.com/download"

func check_for_update() -> void:
    var http := HTTPRequest.new()
    get_tree().root.add_child(http)
    http.request_completed.connect(func(result, code, headers, body):
        if result != HTTPRequest.RESULT_SUCCESS or code != 200:
            http.queue_free()
            return
        var latest := body.get_string_from_utf8().strip_edges()
        if latest != CURRENT_VERSION:
            var dialog := AcceptDialog.new()
            dialog.title = "Mise à jour disponible"
            dialog.dialog_text = "Une nouvelle version (" + latest + ") est disponible."
            dialog.ok_button_text = "Télécharger"
            dialog.confirmed.connect(func():
                OS.shell_open(DOWNLOAD_URL)
            )
            get_tree().root.add_child(dialog)
            dialog.popup_centered()
        http.queue_free()
    )
    http.request(VERSION_URL)
