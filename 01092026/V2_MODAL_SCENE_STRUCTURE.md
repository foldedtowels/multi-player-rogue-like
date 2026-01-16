# V2 Card Choice Modal - Scene Structure

**Scene File**: `res://scenes/ui/card_v2_choice_modal.tscn`
**Script**: `scripts/ui/card_v2_choice_modal.gd` (already created)

## Node Hierarchy

```
Control (card_v2_choice_modal)
├── ModalPanel (Panel)
│   └── VBoxContainer
│       ├── TitleLabel (Label) - "Choose Card Effect: [CardName]"
│       ├── V1Container (VBoxContainer)
│       │   ├── NameLabel (Label) - Card name (v1)
│       │   ├── DescriptionLabel (Label) - Card description (v1)
│       │   └── ChooseButton (Button) - "Choose v1"
│       └── V2Container (VBoxContainer)
│           ├── NameLabel (Label) - Card name (v2)
│           ├── DescriptionLabel (Label) - Card description (v2)
│           └── ChooseButton (Button) - "Choose v2"
```

## Layout Recommendations

**Root Control Node**:
- Anchor: Full Rect
- Size: Fill parent
- Background: Semi-transparent black (Color: 0, 0, 0, 0.7) to darken background

**ModalPanel (Panel)**:
- Anchor: Center
- Size: 600x400
- Position: Centered on screen
- Background: Dark gray/blue with border

**VBoxContainer**:
- Separation: 20px
- Alignment: Center

**TitleLabel**:
- Font Size: 24
- Horizontal Alignment: Center

**V1/V2 Containers**:
- Min Size: 250x150
- Separation: 10px
- Add border/background to distinguish them
- V1 Container: Blue tint
- V2 Container: Green tint

**Name Labels**:
- Font Size: 18
- Horizontal Alignment: Center

**Description Labels**:
- Font Size: 14
- Autowrap: Enabled
- Min Size: 250x80

**Choose Buttons**:
- Min Size: 200x40
- Font Size: 16

## Testing

Once the scene is created:
1. Attach the script `card_v2_choice_modal.gd`
2. Ensure all node paths match the @onready references
3. Test with a v2 card (will need to add v2 cards in later phases)

## Integration

The modal is integrated into `card_hand_display.gd` and shows automatically when a player plays a v2 card. See wiring in `_on_hand_card_clicked()` function.
