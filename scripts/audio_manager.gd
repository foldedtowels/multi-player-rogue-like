extends Node

## AudioManager - Centralized audio system for the game
##
## Features:
## - Music playback with crossfade transitions
## - Pooled SFX players (8 players, round-robin) for combat sounds
## - UI sound player (single, interrupts previous)
## - Volume controls per bus (Master/Music/SFX/UI)
## - Auto-connects to GameManager signals
## - Lazy-loads audio with caching, falls back to placeholder sounds

# Preload the placeholder sound generator
const AudioPlaceholderClass = preload("res://scripts/audio_placeholder.gd")

# ============================================
# CONFIGURATION
# ============================================

## Enable/disable all audio (useful for testing)
var audio_enabled: bool = true

## Use placeholder sounds when audio files are missing
var use_placeholders: bool = true

## Music crossfade duration in seconds
const MUSIC_CROSSFADE_DURATION: float = 1.5

## Number of SFX players in the pool
const SFX_POOL_SIZE: int = 8

## Default volume levels (0.0 to 1.0)
var master_volume: float = 0.8
var music_volume: float = 0.6
var sfx_volume: float = 0.8
var ui_volume: float = 0.7

# ============================================
# AUDIO BUS INDICES
# ============================================
# These will be set up dynamically in _ready()

var bus_master: int = 0
var bus_music: int = -1
var bus_sfx: int = -1
var bus_ui: int = -1

# ============================================
# AUDIO PLAYERS
# ============================================

## Music players (2 for crossfading)
var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var active_music_player: AudioStreamPlayer
var inactive_music_player: AudioStreamPlayer

## SFX player pool
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_pool_index: int = 0

## UI sound player (single)
var ui_player: AudioStreamPlayer

## Crossfade tween
var music_tween: Tween

# ============================================
# AUDIO CACHE
# ============================================

## Cache for loaded audio streams (path -> AudioStream)
var audio_cache: Dictionary = {}

## Currently playing music track name
var current_music: String = ""

# ============================================
# SOUND FILE PATHS
# ============================================

const AUDIO_BASE_PATH: String = "res://assets/audio/"

## Music tracks
const MUSIC_PATHS: Dictionary = {
	"menu": "music/menu_theme.ogg",
	"combat_normal": "music/combat_normal.ogg",
	"combat_boss": "music/combat_boss.ogg",
	"victory": "music/victory_stinger.ogg",
	"defeat": "music/defeat_stinger.ogg",
}

## Sound effects
const SFX_PATHS: Dictionary = {
	# Card sounds
	"card_hover": "sfx/cards/hover.wav",
	"card_pickup": "sfx/cards/pickup.wav",
	"card_play": "sfx/cards/play.wav",
	"card_return": "sfx/cards/return.wav",
	"card_draw": "sfx/cards/draw.wav",
	# Combat sounds
	"damage": "sfx/combat/damage.wav",
	"shield": "sfx/combat/shield.wav",
	"heal": "sfx/combat/heal.wav",
	"poison_tick": "sfx/combat/poison_tick.wav",
	"buff": "sfx/combat/buff.wav",
	"debuff": "sfx/combat/debuff.wav",
	# UI sounds
	"button_click": "sfx/ui/button_click.wav",
	"modal_open": "sfx/ui/modal_open.wav",
	"turn_start": "sfx/ui/turn_start.wav",
	# Special sounds
	"boss_attack": "sfx/special/boss_attack.wav",
	"element_fire": "sfx/special/element_fire.wav",
	"element_water": "sfx/special/element_water.wav",
	"element_earth": "sfx/special/element_earth.wav",
	"toilet_flush": "sfx/special/toilet_flush.wav",
}

## Map SFX names to placeholder types for fallback (initialized in _ready)
var sfx_to_placeholder: Dictionary = {}

## Map music names to placeholder types for fallback (initialized in _ready)
var music_to_placeholder: Dictionary = {}


# ============================================
# INITIALIZATION
# ============================================

func _ready():
	_init_placeholder_mappings()
	_setup_audio_buses()
	_create_audio_players()
	_apply_volume_settings()

	# Connect to GameManager signals after it's ready
	call_deferred("_connect_game_manager_signals")

	print("[AUDIO] AudioManager initialized")


func _init_placeholder_mappings():
	# Initialize SFX to placeholder mappings using the enum from AudioPlaceholder
	sfx_to_placeholder = {
		"card_hover": AudioPlaceholderClass.SoundType.CARD_HOVER,
		"card_pickup": AudioPlaceholderClass.SoundType.CARD_PICKUP,
		"card_play": AudioPlaceholderClass.SoundType.CARD_PLAY,
		"card_return": AudioPlaceholderClass.SoundType.CARD_RETURN,
		"card_draw": AudioPlaceholderClass.SoundType.CARD_DRAW,
		"damage": AudioPlaceholderClass.SoundType.DAMAGE,
		"shield": AudioPlaceholderClass.SoundType.SHIELD,
		"heal": AudioPlaceholderClass.SoundType.HEAL,
		"poison_tick": AudioPlaceholderClass.SoundType.POISON_TICK,
		"buff": AudioPlaceholderClass.SoundType.BUFF,
		"debuff": AudioPlaceholderClass.SoundType.DEBUFF,
		"button_click": AudioPlaceholderClass.SoundType.BUTTON_CLICK,
		"modal_open": AudioPlaceholderClass.SoundType.MODAL_OPEN,
		"turn_start": AudioPlaceholderClass.SoundType.TURN_START,
		"boss_attack": AudioPlaceholderClass.SoundType.BOSS_ATTACK,
		"element_fire": AudioPlaceholderClass.SoundType.ELEMENT_FIRE,
		"element_water": AudioPlaceholderClass.SoundType.ELEMENT_WATER,
		"element_earth": AudioPlaceholderClass.SoundType.ELEMENT_EARTH,
	}

	# Initialize music to placeholder mappings
	music_to_placeholder = {
		"victory": AudioPlaceholderClass.SoundType.VICTORY,
		"defeat": AudioPlaceholderClass.SoundType.DEFEAT,
	}


func _setup_audio_buses():
	# Get or create audio buses
	bus_master = AudioServer.get_bus_index("Master")

	# Create Music bus if it doesn't exist
	bus_music = AudioServer.get_bus_index("Music")
	if bus_music == -1:
		AudioServer.add_bus()
		bus_music = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_music, "Music")
		AudioServer.set_bus_send(bus_music, "Master")

	# Create SFX bus if it doesn't exist
	bus_sfx = AudioServer.get_bus_index("SFX")
	if bus_sfx == -1:
		AudioServer.add_bus()
		bus_sfx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_sfx, "SFX")
		AudioServer.set_bus_send(bus_sfx, "Master")

	# Create UI bus if it doesn't exist
	bus_ui = AudioServer.get_bus_index("UI")
	if bus_ui == -1:
		AudioServer.add_bus()
		bus_ui = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_ui, "UI")
		AudioServer.set_bus_send(bus_ui, "Master")

	print("[AUDIO] Audio buses configured: Music=", bus_music, ", SFX=", bus_sfx, ", UI=", bus_ui)


func _create_audio_players():
	# Create music players for crossfading
	music_player_a = AudioStreamPlayer.new()
	music_player_a.name = "MusicPlayerA"
	music_player_a.bus = "Music"
	add_child(music_player_a)

	music_player_b = AudioStreamPlayer.new()
	music_player_b.name = "MusicPlayerB"
	music_player_b.bus = "Music"
	add_child(music_player_b)

	active_music_player = music_player_a
	inactive_music_player = music_player_b

	# Create SFX player pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer" + str(i)
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	# Create UI player
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	ui_player.bus = "UI"
	add_child(ui_player)


func _connect_game_manager_signals():
	# Wait for GameManager to be ready
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		push_warning("[AUDIO] GameManager not found, audio signals not connected")
		return

	# Connect to game state signals
	if game_manager.has_signal("game_state_changed"):
		game_manager.game_state_changed.connect(_on_game_state_changed)

	if game_manager.has_signal("card_played"):
		game_manager.card_played.connect(_on_card_played)

	if game_manager.has_signal("player_turn_started"):
		game_manager.player_turn_started.connect(_on_player_turn_started)

	if game_manager.has_signal("boss_turn_started"):
		game_manager.boss_turn_started.connect(_on_boss_turn_started)

	if game_manager.has_signal("combat_ended"):
		game_manager.combat_ended.connect(_on_combat_ended)

	if game_manager.has_signal("enemy_damaged_player"):
		game_manager.enemy_damaged_player.connect(_on_enemy_damaged_player)

	print("[AUDIO] Connected to GameManager signals")


# ============================================
# PUBLIC API - MUSIC
# ============================================

## Play background music with crossfade transition
func play_music(track_name: String, loop: bool = true):
	if not audio_enabled:
		return

	if track_name == current_music and active_music_player.playing:
		return  # Already playing this track

	var stream = _load_audio(track_name, true)
	if not stream:
		push_warning("[AUDIO] Music track not found: " + track_name)
		return

	current_music = track_name

	# Set up the inactive player with new track
	inactive_music_player.stream = stream
	inactive_music_player.volume_db = -80  # Start silent

	# Handle looping
	if stream is AudioStreamOggVorbis:
		stream.loop = loop
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED

	inactive_music_player.play()

	# Crossfade
	if music_tween and music_tween.is_running():
		music_tween.kill()

	music_tween = create_tween()
	music_tween.set_parallel(true)

	# Fade in new track
	music_tween.tween_property(inactive_music_player, "volume_db",
		linear_to_db(music_volume), MUSIC_CROSSFADE_DURATION)

	# Fade out old track
	music_tween.tween_property(active_music_player, "volume_db",
		-80, MUSIC_CROSSFADE_DURATION)

	# Swap active/inactive after crossfade
	music_tween.chain().tween_callback(_swap_music_players)


## Stop music with fade out
func stop_music(fade_duration: float = 1.0):
	if music_tween and music_tween.is_running():
		music_tween.kill()

	music_tween = create_tween()
	music_tween.tween_property(active_music_player, "volume_db", -80, fade_duration)
	music_tween.tween_callback(active_music_player.stop)

	current_music = ""


## Pause/resume music
func pause_music(paused: bool = true):
	active_music_player.stream_paused = paused


func _swap_music_players():
	# Stop the old track and swap references
	var old_active = active_music_player
	active_music_player = inactive_music_player
	inactive_music_player = old_active
	inactive_music_player.stop()


# ============================================
# PUBLIC API - SFX
# ============================================

## Play a sound effect by name
func play_sfx(sfx_name: String, volume_scale: float = 1.0):
	if not audio_enabled:
		return

	var stream = _load_audio(sfx_name, false)
	if not stream:
		if use_placeholders and sfx_to_placeholder.has(sfx_name):
			stream = AudioPlaceholderClass.generate_sound(sfx_to_placeholder[sfx_name])
		else:
			return

	# Get next player from pool (round-robin)
	var player = sfx_players[sfx_pool_index]
	sfx_pool_index = (sfx_pool_index + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.play()


## Play element-specific sound based on card element
func play_element_sfx(element: String):
	match element.to_lower():
		"fire":
			play_sfx("element_fire")
		"water":
			play_sfx("element_water")
		"earth":
			play_sfx("element_earth")
		_:
			play_sfx("card_play")


# ============================================
# PUBLIC API - UI SOUNDS
# ============================================

## Play a UI sound (interrupts previous UI sound)
func play_ui(sfx_name: String, volume_scale: float = 1.0):
	if not audio_enabled:
		return

	var stream = _load_audio(sfx_name, false)
	if not stream:
		if use_placeholders and sfx_to_placeholder.has(sfx_name):
			stream = AudioPlaceholderClass.generate_sound(sfx_to_placeholder[sfx_name])
		else:
			return

	ui_player.stream = stream
	ui_player.volume_db = linear_to_db(ui_volume * volume_scale)
	ui_player.play()


# ============================================
# PUBLIC API - VOLUME CONTROL
# ============================================

## Set master volume (0.0 to 1.0)
func set_master_volume(value: float):
	master_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_master, linear_to_db(master_volume))


## Set music volume (0.0 to 1.0)
func set_music_volume(value: float):
	music_volume = clamp(value, 0.0, 1.0)
	if active_music_player.playing:
		active_music_player.volume_db = linear_to_db(music_volume)


## Set SFX volume (0.0 to 1.0)
func set_sfx_volume(value: float):
	sfx_volume = clamp(value, 0.0, 1.0)


## Set UI volume (0.0 to 1.0)
func set_ui_volume(value: float):
	ui_volume = clamp(value, 0.0, 1.0)


## Mute/unmute all audio
func set_muted(muted: bool):
	AudioServer.set_bus_mute(bus_master, muted)


func _apply_volume_settings():
	AudioServer.set_bus_volume_db(bus_master, linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(bus_music, 0)  # Music volume controlled per-player
	AudioServer.set_bus_volume_db(bus_sfx, 0)    # SFX volume controlled per-player
	AudioServer.set_bus_volume_db(bus_ui, 0)     # UI volume controlled per-player


# ============================================
# SIGNAL HANDLERS
# ============================================

func _on_game_state_changed():
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return

	match game_manager.current_state:
		GameManager.GameState.CHARACTER_SELECTION:
			play_music("menu")
		GameManager.GameState.COMBAT:
			# Check if fighting a boss
			if game_manager.combat_phase == GameManager.CombatPhase.BOSS_PHASE_1 or \
			   game_manager.combat_phase == GameManager.CombatPhase.BOSS_PHASE_2:
				play_music("combat_boss")
			else:
				play_music("combat_normal")
		GameManager.GameState.REWARD:
			pass  # Keep current music
		GameManager.GameState.VICTORY:
			play_music("victory", false)  # Don't loop victory stinger
		GameManager.GameState.GAME_OVER:
			play_music("defeat", false)  # Don't loop defeat stinger


func _on_card_played(character: Character, card: Card, _target: Character):
	if not character:
		return

	# Only play sound for local player's cards
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var player_index = game_manager.players.find(character)
		if player_index != game_manager.local_player_index and player_index != -1:
			return  # Not local player

	# Play element-specific sound or generic card play
	if card and card.element != Card.ElementType.NONE:
		play_element_sfx(Card.ElementType.keys()[card.element].to_lower())
	else:
		play_sfx("card_play")


func _on_player_turn_started(player_index: int):
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and player_index == game_manager.local_player_index:
		play_sfx("turn_start")


func _on_boss_turn_started():
	play_sfx("boss_attack", 0.7)


func _on_combat_ended(victory: bool):
	if victory:
		play_music("victory", false)
	else:5
		play_music("defeat", false)


func _on_enemy_damaged_player(_enemy_name: String, _card_name: String, damage: int, target_player_index: int):
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and target_player_index == game_manager.local_player_index:
		# Scale volume based on damage
		var volume_scale = clamp(float(damage) / 20.0, 0.5, 1.2)
		play_sfx("damage", volume_scale)


# ============================================
# AUDIO LOADING
# ============================================

## Load an audio stream, using cache
func _load_audio(name: String, is_music: bool) -> AudioStream:
	# Check cache first
	if audio_cache.has(name):
		return audio_cache[name]

	# Determine path
	var paths = MUSIC_PATHS if is_music else SFX_PATHS
	if not paths.has(name):
		# Check if music has placeholder fallback
		if is_music and use_placeholders and music_to_placeholder.has(name):
			var stream = AudioPlaceholderClass.generate_sound(music_to_placeholder[name])
			audio_cache[name] = stream
			return stream
		return null

	var path = AUDIO_BASE_PATH + paths[name]

	# Try to load the file
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			audio_cache[name] = stream
			return stream

	# File doesn't exist - try placeholder for music
	if is_music and use_placeholders and music_to_placeholder.has(name):
		var stream = AudioPlaceholderClass.generate_sound(music_to_placeholder[name])
		audio_cache[name] = stream
		return stream

	return null


## Clear the audio cache (useful for memory management)
func clear_cache():
	audio_cache.clear()
