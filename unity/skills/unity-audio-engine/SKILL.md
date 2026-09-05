---
name: unity-audio-engine
description: Complete audio mastery for Unity including AudioSource, AudioMixer, spatial 3D audio, FMOD/Wwise integration, music systems, audio pooling, and dynamic mixing.
author: Diego Villanueva
trigger: When implementing game audio, sound effects, music systems, spatial audio, audio mixing, or integrating middleware like FMOD or Wwise.
---

# Unity Audio Engine

Audio is 50% of the player experience. A professionally mixed game uses AudioMixer groups for volume control, spatial audio for immersion, pooled AudioSources for performance, and a layered music system for dynamic soundtracks.

## 1. AudioMixer Architecture

```text
✅ AudioMixer Group Hierarchy:
Master
├── Music
│   ├── MusicAmbient
│   └── MusicCombat
├── SFX
│   ├── SFXPlayer (footsteps, attacks, pickups)
│   ├── SFXEnvironment (wind, water, fire)
│   ├── SFXEnemy (growls, attacks, death)
│   └── SFXUI (button clicks, menu sounds)
├── Voice
│   ├── VoiceDialogue
│   └── VoiceNarration
└── Ambience
    ├── AmbienceNature
    └── AmbienceCity
```

```csharp
// ✅ Expose mixer parameters for volume control
// In AudioMixer: Right-click on Volume → Expose to Script
// Name exposed parameter: "MasterVolume", "MusicVolume", "SFXVolume"

public class AudioSettings : MonoBehaviour
{
    [SerializeField] private AudioMixer _mixer;

    public void SetMasterVolume(float normalizedValue)
    {
        // Convert 0-1 slider to decibels (logarithmic)
        float db = normalizedValue > 0.0001f
            ? Mathf.Log10(normalizedValue) * 20f
            : -80f;
        _mixer.SetFloat("MasterVolume", db);
    }

    public void SetMusicVolume(float value) => SetVolume("MusicVolume", value);
    public void SetSFXVolume(float value) => SetVolume("SFXVolume", value);

    private void SetVolume(string parameter, float normalizedValue)
    {
        float db = normalizedValue > 0.0001f ? Mathf.Log10(normalizedValue) * 20f : -80f;
        _mixer.SetFloat(parameter, db);
    }
}
```

## 2. SFX Manager (Pooled AudioSources)

```csharp
// ✅ ALWAYS: Pool AudioSources for SFX
public class SFXManager : MonoBehaviour
{
    [SerializeField] private AudioMixerGroup _sfxGroup;
    [SerializeField] private int _poolSize = 16;

    private readonly Queue<AudioSource> _pool = new();

    private void Awake()
    {
        for (int i = 0; i < _poolSize; i++)
        {
            var go = new GameObject($"SFX_{i}");
            go.transform.SetParent(transform);
            var source = go.AddComponent<AudioSource>();
            source.outputAudioMixerGroup = _sfxGroup;
            source.playOnAwake = false;
            _pool.Enqueue(source);
        }
    }

    public void PlaySFX(AudioClip clip, Vector3 position, float volume = 1f, float pitch = 1f)
    {
        if (clip == null || _pool.Count == 0) return;

        var source = _pool.Dequeue();
        source.transform.position = position;
        source.clip = clip;
        source.volume = volume;
        source.pitch = pitch;
        source.spatialBlend = 1f; // 3D
        source.Play();

        StartCoroutine(ReturnToPool(source, clip.length / pitch));
    }

    public void PlaySFX2D(AudioClip clip, float volume = 1f)
    {
        if (clip == null || _pool.Count == 0) return;

        var source = _pool.Dequeue();
        source.clip = clip;
        source.volume = volume;
        source.spatialBlend = 0f; // 2D
        source.Play();

        StartCoroutine(ReturnToPool(source, clip.length));
    }

    private IEnumerator ReturnToPool(AudioSource source, float delay)
    {
        yield return new WaitForSeconds(delay + 0.1f);
        source.Stop();
        source.clip = null;
        _pool.Enqueue(source);
    }
}

// ❌ NEVER: Create AudioSource per sound
void PlaySound(AudioClip clip)
{
    AudioSource.PlayClipAtPoint(clip, transform.position); // Creates and leaks GameObjects!
}
```

## 3. Music Manager (Crossfading)

```csharp
// ✅ Music system with crossfading
public class MusicManager : MonoBehaviour
{
    [SerializeField] private AudioMixerGroup _musicGroup;
    private AudioSource _sourceA;
    private AudioSource _sourceB;
    private bool _isPlayingA = true;

    private void Awake()
    {
        _sourceA = CreateMusicSource("MusicA");
        _sourceB = CreateMusicSource("MusicB");
    }

    private AudioSource CreateMusicSource(string name)
    {
        var go = new GameObject(name);
        go.transform.SetParent(transform);
        var source = go.AddComponent<AudioSource>();
        source.outputAudioMixerGroup = _musicGroup;
        source.loop = true;
        source.playOnAwake = false;
        source.spatialBlend = 0f;
        return source;
    }

    public void CrossfadeTo(AudioClip newTrack, float duration = 2f)
    {
        var incoming = _isPlayingA ? _sourceB : _sourceA;
        var outgoing = _isPlayingA ? _sourceA : _sourceB;
        _isPlayingA = !_isPlayingA;

        incoming.clip = newTrack;
        incoming.volume = 0f;
        incoming.Play();

        StartCoroutine(Crossfade(outgoing, incoming, duration));
    }

    private IEnumerator Crossfade(AudioSource fadeOut, AudioSource fadeIn, float duration)
    {
        float elapsed = 0f;
        float startVolume = fadeOut.volume;

        while (elapsed < duration)
        {
            elapsed += Time.unscaledDeltaTime;
            float t = elapsed / duration;
            fadeOut.volume = Mathf.Lerp(startVolume, 0f, t);
            fadeIn.volume = Mathf.Lerp(0f, 1f, t);
            yield return null;
        }

        fadeOut.Stop();
        fadeOut.volume = 0f;
        fadeIn.volume = 1f;
    }
}
```

## 4. Spatial Audio (3D Sound)

```csharp
// ✅ 3D Audio configuration on AudioSource:
// Spatial Blend: 1.0 (fully 3D)
// Doppler Level: 0.5 (subtle pitch shift for moving sources)
// Min Distance: 1m (full volume within this range)
// Max Distance: 30m (inaudible beyond this)
// Rolloff Mode: Logarithmic (natural falloff)
// Spread: 0° (point source) or 180° (wide ambient)

// ✅ Occlusion: Reduce volume when behind walls
public class AudioOcclusion : MonoBehaviour
{
    [SerializeField] private AudioSource _source;
    [SerializeField] private AudioLowPassFilter _lowPass;
    [SerializeField] private LayerMask _occlusionLayer;

    private Transform _listener;

    private void Start() => _listener = Camera.main.transform;

    private void Update()
    {
        var direction = _listener.position - transform.position;
        bool occluded = Physics.Raycast(transform.position, direction.normalized,
            direction.magnitude, _occlusionLayer);

        _lowPass.cutoffFrequency = occluded ? 800f : 22000f; // Muffle when behind walls
        _source.volume = occluded ? 0.3f : 1f;
    }
}
```

## 5. Audio Data (ScriptableObject)

```csharp
// ✅ Centralize audio references in ScriptableObjects
[CreateAssetMenu(menuName = "Audio/SFX Collection")]
public class SFXCollection : ScriptableObject
{
    [Header("Player")]
    public AudioClip[] footsteps;
    public AudioClip jump;
    public AudioClip land;
    public AudioClip[] attacks;
    public AudioClip hurt;
    public AudioClip death;

    [Header("UI")]
    public AudioClip buttonClick;
    public AudioClip buttonHover;
    public AudioClip menuOpen;
    public AudioClip menuClose;

    public AudioClip GetRandomFootstep() =>
        footsteps[Random.Range(0, footsteps.Length)];

    public AudioClip GetRandomAttack() =>
        attacks[Random.Range(0, attacks.Length)];
}
```

---

**Execution Protocol**
1. **AudioMixer for ALL Output**: Every AudioSource MUST route through an AudioMixer group. NEVER output directly to the master.
2. **Pool AudioSources**: NEVER use `AudioSource.PlayClipAtPoint()` — it creates and leaks GameObjects.
3. **Logarithmic Volume**: Convert UI slider values (0-1) to decibels with `Log10(value) * 20f` for natural volume perception.
4. **Spatial Blend**: SFX that exist in the world = `spatialBlend = 1f`. UI sounds and music = `spatialBlend = 0f`.
5. **Randomize Pitch**: For repetitive sounds (footsteps, gunshots), randomize pitch ±0.05f to avoid machine-gun effect.
