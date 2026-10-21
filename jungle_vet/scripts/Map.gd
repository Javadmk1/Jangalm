extends Control

const LEVEL_KINDS := ["rabbit", "squirrel", "turtle", "bird", "fox", "deer", "hedgehog"]
const NAMES := ["پوپی", "ناتس", "لاکی", "چیریک", "فاکسی", "لونا", "تیغی (باس هفتگی)"]

func _ready() -> void:
    Backdrop.add_to(self, Backdrop.Kind.FOREST)
    var box := UI.screen_root(self, 40, 20)

    var top := HBoxContainer.new()
    box.add_child(top)
    var back := UI.button("منو", 90, 34, true)
    back.custom_minimum_size = Vector2(170, 90)
    back.pressed.connect(func(): Nav.go(Nav.MAIN_MENU))
    top.add_child(back)
    top.add_child(UI.spacer_h())
    top.add_child(UI.coin_chip())

    box.add_child(UI.title("نقشه‌ی جنگل", 60))

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    box.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 22)
    scroll.add_child(list)

    for i in range(1, Nav.LEVEL_COUNT + 1):
        list.add_child(_card(i))

func _card(i: int) -> PanelContainer:
    var unlocked := SaveManager.is_level_unlocked(i)
    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.mouse_filter = Control.MOUSE_FILTER_STOP
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 20)
    card.add_child(row)

    var av := AnimalView.new()
    av.kind = LEVEL_KINDS[i - 1]
    av.mood = "happy" if SaveManager.stars_for(i) > 0 else "calm"
    av.hint_injury = false
    av.silhouette = not unlocked
    av.custom_minimum_size = Vector2(190, 190)
    row.add_child(av)

    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_child(info)
    info.add_child(UI.label("%d. %s" % [i, Loc.t(NAMES[i - 1])], 42))
    if unlocked:
        var sv := StarsView.new()
        sv.star_size = 44.0
        sv.count = SaveManager.stars_for(i)
        sv.size_flags_horizontal = Control.SIZE_SHRINK_END
        info.add_child(sv)
    else:
        info.add_child(UI.label("اول مرحله‌ی قبل را تمام کن", 30))

    # Child controls otherwise consume Android touch/mouse events before the card sees them.
    _ignore_card_input(row)

    if unlocked:
        card.gui_input.connect(func(event: InputEvent):
            if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
                AudioManager.play("click")
                Nav.start_level(i))
    else:
        card.modulate = Color(1, 1, 1, 0.75)
    return card

func _ignore_card_input(node: Node) -> void:
    for child in node.get_children():
        if child is Control:
            (child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
        _ignore_card_input(child)
