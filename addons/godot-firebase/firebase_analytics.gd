extends Node

class AnalyticsClass:
    func log_event(event_name: String, params: Dictionary = {}):
        print("[Analytics] %s %s" % [event_name, params])

var Analytics := AnalyticsClass.new()
