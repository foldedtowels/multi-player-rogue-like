extends RefCounted
class_name AudioPlaceholder

## Generates simple placeholder sounds for testing without audio files.
## Uses synthesized beeps/tones with different frequencies and envelopes.

enum SoundType {
	CARD_HOVER,      # Short high blip
	CARD_PICKUP,     # Rising tone
	CARD_PLAY,       # Satisfying thunk
	CARD_RETURN,     # Falling tone
	CARD_DRAW,       # Soft swish
	DAMAGE,          # Low impact
	SHIELD,          # Metallic ping
	HEAL,            # Gentle rising chime
	BUFF,            # Magical sparkle
	DEBUFF,          # Dark rumble
	POISON_TICK,     # Bubbling
	TURN_START,      # Alert chime
	BUTTON_CLICK,    # UI click
	MODAL_OPEN,      # Whoosh
	VICTORY,         # Triumphant fanfare
	DEFEAT,          # Sad descending
	BOSS_ATTACK,     # Heavy slam
	ELEMENT_FIRE,    # Crackling
	ELEMENT_WATER,   # Splash
	ELEMENT_EARTH,   # Rumble
}

# Audio generation constants
const SAMPLE_RATE: int = 44100
const MAX_AMPLITUDE: float = 0.5  # Keep volume reasonable

## Generate a placeholder sound of the given type
static func generate_sound(sound_type: SoundType) -> AudioStreamWAV:
	match sound_type:
		SoundType.CARD_HOVER:
			return _generate_blip(800, 0.05)
		SoundType.CARD_PICKUP:
			return _generate_sweep(400, 600, 0.1)
		SoundType.CARD_PLAY:
			return _generate_thunk(200, 0.15)
		SoundType.CARD_RETURN:
			return _generate_sweep(500, 300, 0.1)
		SoundType.CARD_DRAW:
			return _generate_noise_burst(0.08)
		SoundType.DAMAGE:
			return _generate_impact(120, 0.2)
		SoundType.SHIELD:
			return _generate_ping(1200, 0.15)
		SoundType.HEAL:
			return _generate_chime([523, 659, 784], 0.3)  # C, E, G
		SoundType.BUFF:
			return _generate_sparkle(0.25)
		SoundType.DEBUFF:
			return _generate_rumble(80, 0.2)
		SoundType.POISON_TICK:
			return _generate_bubble(0.15)
		SoundType.TURN_START:
			return _generate_chime([440, 550, 660], 0.2)  # A, Db, E
		SoundType.BUTTON_CLICK:
			return _generate_blip(600, 0.03)
		SoundType.MODAL_OPEN:
			return _generate_whoosh(0.15)
		SoundType.VICTORY:
			return _generate_fanfare(0.8)
		SoundType.DEFEAT:
			return _generate_sad_tone(0.6)
		SoundType.BOSS_ATTACK:
			return _generate_impact(80, 0.3)
		SoundType.ELEMENT_FIRE:
			return _generate_crackle(0.2)
		SoundType.ELEMENT_WATER:
			return _generate_splash(0.2)
		SoundType.ELEMENT_EARTH:
			return _generate_rumble(60, 0.25)

	# Default fallback
	return _generate_blip(440, 0.1)


## Generate a simple blip/beep
static func _generate_blip(frequency: float, duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2  # 16-bit = 2 bytes per sample

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var envelope = _envelope_decay(t, duration)
		var value = sin(TAU * frequency * t) * envelope * MAX_AMPLITUDE
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate a frequency sweep (rising or falling tone)
static func _generate_sweep(start_freq: float, end_freq: float, duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = t / duration
		var freq = lerp(start_freq, end_freq, progress)
		var envelope = _envelope_decay(t, duration)
		var value = sin(TAU * freq * t) * envelope * MAX_AMPLITUDE
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate a thunky impact sound
static func _generate_thunk(frequency: float, duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		# Quick pitch drop for thunk effect
		var freq = frequency * (1.0 - t / duration * 0.5)
		var envelope = _envelope_quick_decay(t, duration)
		var value = sin(TAU * freq * t) * envelope * MAX_AMPLITUDE
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate a metallic ping
static func _generate_ping(frequency: float, duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var envelope = _envelope_decay(t, duration)
		# Add harmonics for metallic sound
		var value = (sin(TAU * frequency * t) * 0.6 +
					 sin(TAU * frequency * 2.0 * t) * 0.25 +
					 sin(TAU * frequency * 3.0 * t) * 0.15) * envelope * MAX_AMPLITUDE
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate a chord/chime from multiple frequencies
static func _generate_chime(frequencies: Array, duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2
	var freq_count = frequencies.size()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var envelope = _envelope_decay(t, duration)
		var value = 0.0
		for freq in frequencies:
			value += sin(TAU * freq * t)
		value = value / freq_count * envelope * MAX_AMPLITUDE
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate a heavy impact sound
static func _generate_impact(frequency: float, duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var envelope = _envelope_quick_decay(t, duration)
		# Layered frequencies for thick impact
		var freq = frequency * (1.0 - t / duration * 0.7)  # Pitch drops
		var value = (sin(TAU * freq * t) * 0.5 +
					 sin(TAU * freq * 0.5 * t) * 0.3 +
					 _noise() * 0.2) * envelope * MAX_AMPLITUDE
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate sparkle effect
static func _generate_sparkle(duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var envelope = _envelope_decay(t, duration)
		# Multiple high frequencies with slight detuning
		var value = (sin(TAU * 2000 * t) * 0.3 +
					 sin(TAU * 2500 * t + 0.5) * 0.3 +
					 sin(TAU * 3000 * t + 1.0) * 0.2 +
					 sin(TAU * 1500 * t) * 0.2) * envelope * MAX_AMPLITUDE * 0.6
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate low rumble
static func _generate_rumble(frequency: float, duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var envelope = _envelope_swell(t, duration)
		# Low frequency with noise
		var value = (sin(TAU * frequency * t) * 0.5 +
					 sin(TAU * frequency * 1.5 * t) * 0.3 +
					 _noise() * 0.2) * envelope * MAX_AMPLITUDE
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate bubbling sound
static func _generate_bubble(duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	var bubble_freq = 300.0
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var envelope = _envelope_decay(t, duration)
		# Modulated frequency for bubble effect
		var mod = sin(TAU * 8 * t) * 100
		var value = sin(TAU * (bubble_freq + mod) * t) * envelope * MAX_AMPLITUDE * 0.7
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate whoosh sound
static func _generate_whoosh(duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = t / duration
		var envelope = sin(progress * PI)  # Swell in middle
		# Filtered noise that sweeps up
		var cutoff = lerp(200.0, 2000.0, progress)
		var value = _filtered_noise(cutoff) * envelope * MAX_AMPLITUDE * 0.6
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate noise burst
static func _generate_noise_burst(duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var envelope = _envelope_quick_decay(t, duration)
		var value = _noise() * envelope * MAX_AMPLITUDE * 0.4
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate victory fanfare
static func _generate_fanfare(duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	# Simple ascending arpeggio: C4, E4, G4, C5
	var notes = [262, 330, 392, 523]
	var note_duration = duration / notes.size()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var note_index = int(t / note_duration)
		note_index = min(note_index, notes.size() - 1)
		var note_t = fmod(t, note_duration)
		var freq = notes[note_index]
		var envelope = _envelope_decay(note_t, note_duration * 1.5)
		var value = sin(TAU * freq * t) * envelope * MAX_AMPLITUDE
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate sad descending tone
static func _generate_sad_tone(duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	# Descending minor: C4, Bb3, Ab3, G3
	var notes = [262, 233, 208, 196]
	var note_duration = duration / notes.size()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var note_index = int(t / note_duration)
		note_index = min(note_index, notes.size() - 1)
		var note_t = fmod(t, note_duration)
		var freq = notes[note_index]
		var envelope = _envelope_decay(note_t, note_duration * 1.2)
		var value = sin(TAU * freq * t) * envelope * MAX_AMPLITUDE * 0.8
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate fire crackle
static func _generate_crackle(duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var envelope = _envelope_decay(t, duration)
		# Mix of noise and occasional pops
		var pop = 0.0
		if randf() < 0.02:  # Occasional pops
			pop = randf() * 0.5
		var value = (_filtered_noise(3000) * 0.4 + pop) * envelope * MAX_AMPLITUDE
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


## Generate water splash
static func _generate_splash(duration: float) -> AudioStreamWAV:
	var samples = _create_sample_buffer(duration)
	var sample_count = samples.size() / 2

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = t / duration
		var envelope = _envelope_quick_decay(t, duration)
		# Frequency sweep down with noise
		var freq = lerp(1000.0, 200.0, progress)
		var value = (sin(TAU * freq * t) * 0.3 +
					 _filtered_noise(freq * 2) * 0.7) * envelope * MAX_AMPLITUDE * 0.7
		_write_sample(samples, i, value)

	return _create_wav_stream(samples)


# ============================================
# HELPER FUNCTIONS
# ============================================

static func _create_sample_buffer(duration: float) -> PackedByteArray:
	var sample_count = int(SAMPLE_RATE * duration)
	var buffer = PackedByteArray()
	buffer.resize(sample_count * 2)  # 16-bit = 2 bytes per sample
	return buffer


static func _write_sample(buffer: PackedByteArray, index: int, value: float):
	var sample = int(clamp(value, -1.0, 1.0) * 32767)
	buffer[index * 2] = sample & 0xFF
	buffer[index * 2 + 1] = (sample >> 8) & 0xFF


static func _create_wav_stream(samples: PackedByteArray) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream


## Envelope that decays over time
static func _envelope_decay(t: float, duration: float) -> float:
	var progress = t / duration
	return max(0.0, 1.0 - progress)


## Envelope with quick initial decay
static func _envelope_quick_decay(t: float, duration: float) -> float:
	var progress = t / duration
	return max(0.0, exp(-progress * 5))


## Envelope that swells then decays
static func _envelope_swell(t: float, duration: float) -> float:
	var progress = t / duration
	if progress < 0.3:
		return progress / 0.3
	return max(0.0, 1.0 - (progress - 0.3) / 0.7)


## Simple white noise
static func _noise() -> float:
	return randf() * 2.0 - 1.0


## Very simple low-pass filtered noise approximation
static func _filtered_noise(cutoff: float) -> float:
	# This is a crude approximation - real filtering would need state
	var base_noise = _noise()
	var factor = clamp(cutoff / 10000.0, 0.0, 1.0)
	return base_noise * factor
