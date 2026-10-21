extends Node

const MAIN_MENU := "res://scenes/MainMenu.tscn"
const MAP := "res://scenes/Map.tscn"
const LEVEL := "res://scenes/Level.tscn"
const ALBUM := "res://scenes/Album.tscn"
const COIN_SHOP := "res://scenes/CoinShop.tscn"
const CLINIC := "res://scenes/Clinic.tscn"
const DAILY := "res://scenes/DailyScreen.tscn"
const SETTINGS := "res://scenes/Settings.tscn"
const PARENTAL := "res://scenes/ParentalPanel.tscn"
const LEVEL_COUNT := 7

var current_level: int = 1
var session_levels: int = 0

var _busy := false
var _fade: ColorRect
var _acc := 0.0
var _save_timer := 0.0
var _rest_overlay: Node = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().root.theme = GameTheme.build()

    var layer := CanvasLayer.new()
    layer.layer = 100
    add_child(layer)
    _fade = ColorRect.new()
    _fade.color = Color(0.1, 0.08, 0.06, 0.0)
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(_fade)
    _fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    MissionManager.refresh()

func go(path: String) -> void:
    if _busy:
        return
    if not path.begins_with("res://") or not ResourceLoader.exists(path):
        push_error("Nav.go rejected missing or invalid scene path: %s" % path)
        return

    _busy = true
    _fade.mouse_filter = Control.MOUSE_FILTER_STOP
    var tw := create_tween()
    tw.tween_property(_fade, "color:a", 1.0, 0.18)
    await tw.finished

    var change_error: Error = get_tree().change_scene_to_file(path)
    if change_error != OK:
        push_error("Could not change scene to %s (error %d)" % [path, change_error])
        var recover := create_tween()
        recover.tween_property(_fade, "color:a", 0.0, 0.18)
        await recover.finished
        _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _busy = false
        return

    await get_tree().process_frame
    await get_tree().process_frame
    var tw2 := create_tween()
    tw2.tween_property(_fade, "color:a", 0.0, 0.22)
    await tw2.finished
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _busy = false

func start_level(id: int) -> void:
    current_level = id
    go(LEVEL)

# ---------- زمان بازی و استراحت اجباری ----------

func _process(delta: float) -> void:
    _acc += delta
    _save_timer += delta
    if _acc >= 1.0:
        SaveManager.add_play_seconds(_acc)
        _acc = 0.0
        if _rest_overlay == null and SaveManager.time_limit_reached():
            _show_rest()
    if _save_timer >= 20.0:
        _save_timer = 0.0
        SaveManager.save_game()

func _show_rest() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 101
    add_child(layer)
    var root := Control.new()
    layer.add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _rest_overlay = layer

    var bg := ColorRect.new()
    bg.color = Color("fff1d6")
    root.add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center := CenterContainer.new()
    root.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var box := VBoxContainer.new()
    box.custom_minimum_size = Vector2(800, 0)
    box.add_theme_constant_override("separation", 28)
    center.add_child(box)

    var av := AnimalView.new()
    av.kind = "rabbit"
    av.mood = "calm"
    av.hint_injury = false
    av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    box.add_child(av)
    box.add_child(UI.label("وقت استراحته!", 60, true))
    box.add_child(UI.label("امروز خیلی بازی کردی. چشم‌هات را استراحت بده و فردا دوباره حیوان‌ها را نجات بده.", 36, true))
    var parent_btn := UI.button("برای والدین", 120, 34, true)
    parent_btn.pressed.connect(_on_rest_parent)
    box.add_child(parent_btn)

func _on_rest_parent() -> void:
    var gate := ParentalGate.open(_rest_overlay.get_child(0))
    gate.passed.connect(_extend_after_gate, CONNECT_ONE_SHOT)

func _extend_after_gate() -> void:
    SaveManager.add_extension(15)
    if _rest_overlay != null:
        _rest_overlay.queue_free()
        _rest_overlay = null
