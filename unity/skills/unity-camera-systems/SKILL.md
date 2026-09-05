---
name: unity-camera-systems
description: Camera system architecture for Unity including follow cameras, orbit cameras, dead zones, camera shake, split screen, dynamic framing, and 2D/3D camera rigs.
author: Diego Villanueva
trigger: When implementing camera controllers, follow cameras, orbit systems, split screen, dynamic framing, or camera transition systems.
---

# Camera Systems

Camera is the player's window into the game world. A bad camera ruins even the best gameplay. This document covers camera rigs for every genre, independent of Cinemachine (for when you need full custom control).

## 1. 2D Follow Camera

```csharp
// ✅ Smooth 2D camera with dead zone and bounds
public class Camera2DFollow : MonoBehaviour
{
    [SerializeField] private Transform _target;
    [SerializeField] private float _smoothSpeed = 5f;
    [SerializeField] private Vector2 _offset = new(0, 1);
    [SerializeField] private Vector2 _deadZone = new(1, 0.5f);
    [SerializeField] private Bounds _cameraBounds;

    private Vector3 _currentVelocity;

    private void LateUpdate()
    {
        Vector3 targetPos = _target.position + (Vector3)_offset;

        // Dead zone: don't move camera if target is within dead zone
        Vector3 diff = targetPos - transform.position;
        if (Mathf.Abs(diff.x) < _deadZone.x) targetPos.x = transform.position.x;
        if (Mathf.Abs(diff.y) < _deadZone.y) targetPos.y = transform.position.y;

        targetPos.z = transform.position.z; // Maintain camera Z

        // Smooth follow
        Vector3 smoothed = Vector3.SmoothDamp(
            transform.position, targetPos, ref _currentVelocity, 1f / _smoothSpeed);

        // Clamp to bounds
        smoothed.x = Mathf.Clamp(smoothed.x, _cameraBounds.min.x, _cameraBounds.max.x);
        smoothed.y = Mathf.Clamp(smoothed.y, _cameraBounds.min.y, _cameraBounds.max.y);

        transform.position = smoothed;
    }
}
```

## 2. Third-Person Orbit Camera

```csharp
// ✅ Orbiting third-person camera with collision
public class OrbitCamera : MonoBehaviour
{
    [SerializeField] private Transform _target;
    [SerializeField] private float _distance = 5f;
    [SerializeField] private float _minDistance = 1f;
    [SerializeField] private float _maxDistance = 10f;
    [SerializeField] private float _sensitivity = 3f;
    [SerializeField] private float _minPitch = -30f;
    [SerializeField] private float _maxPitch = 60f;
    [SerializeField] private float _collisionRadius = 0.3f;
    [SerializeField] private LayerMask _collisionMask;

    private float _yaw;
    private float _pitch = 20f;

    private void LateUpdate()
    {
        // Input
        _yaw += Input.GetAxis("Mouse X") * _sensitivity;
        _pitch -= Input.GetAxis("Mouse Y") * _sensitivity;
        _pitch = Mathf.Clamp(_pitch, _minPitch, _maxPitch);

        // Scroll zoom
        _distance -= Input.GetAxis("Mouse ScrollWheel") * 2f;
        _distance = Mathf.Clamp(_distance, _minDistance, _maxDistance);

        // Calculate desired position
        Quaternion rotation = Quaternion.Euler(_pitch, _yaw, 0);
        Vector3 desiredPos = _target.position - rotation * Vector3.forward * _distance;

        // Collision: pull camera forward if obstructed
        float actualDistance = _distance;
        Vector3 direction = desiredPos - _target.position;
        if (Physics.SphereCast(_target.position, _collisionRadius, direction.normalized,
            out var hit, _distance, _collisionMask))
        {
            actualDistance = hit.distance - 0.1f;
        }

        Vector3 finalPos = _target.position - rotation * Vector3.forward * actualDistance;
        transform.position = finalPos;
        transform.LookAt(_target.position + Vector3.up * 1.5f);
    }
}
```

## 3. Camera Shake

```csharp
// ✅ Perlin noise-based camera shake (smooth, not jittery)
public class CameraShake : MonoBehaviour
{
    private float _shakeIntensity;
    private float _shakeDuration;
    private float _shakeTimer;
    private float _shakeFrequency = 25f;

    public void Shake(float intensity, float duration)
    {
        _shakeIntensity = intensity;
        _shakeDuration = duration;
        _shakeTimer = 0f;
    }

    private void LateUpdate()
    {
        if (_shakeTimer >= _shakeDuration) return;

        _shakeTimer += Time.deltaTime;
        float decay = 1f - (_shakeTimer / _shakeDuration); // Linear decay

        float offsetX = (Mathf.PerlinNoise(Time.time * _shakeFrequency, 0f) - 0.5f) * 2f;
        float offsetY = (Mathf.PerlinNoise(0f, Time.time * _shakeFrequency) - 0.5f) * 2f;

        transform.localPosition += new Vector3(offsetX, offsetY, 0f) * (_shakeIntensity * decay);
    }
}

// Usage:
// Small hit: cameraShake.Shake(0.1f, 0.2f);
// Explosion: cameraShake.Shake(0.5f, 0.5f);
// Boss slam:  cameraShake.Shake(1.0f, 0.8f);
```

## 4. Split Screen

```csharp
// ✅ Multi-player split screen
public class SplitScreenManager : MonoBehaviour
{
    [SerializeField] private Camera[] _playerCameras;

    public void SetupSplitScreen(int playerCount)
    {
        switch (playerCount)
        {
            case 1:
                _playerCameras[0].rect = new Rect(0, 0, 1, 1);
                break;
            case 2: // Horizontal split
                _playerCameras[0].rect = new Rect(0, 0.5f, 1, 0.5f); // Top
                _playerCameras[1].rect = new Rect(0, 0, 1, 0.5f);    // Bottom
                break;
            case 4: // Quad split
                _playerCameras[0].rect = new Rect(0, 0.5f, 0.5f, 0.5f);   // Top Left
                _playerCameras[1].rect = new Rect(0.5f, 0.5f, 0.5f, 0.5f); // Top Right
                _playerCameras[2].rect = new Rect(0, 0, 0.5f, 0.5f);       // Bottom Left
                _playerCameras[3].rect = new Rect(0.5f, 0, 0.5f, 0.5f);    // Bottom Right
                break;
        }
    }
}
```

## 5. Dynamic Framing (Boss Fights)

```csharp
// ✅ Camera that frames both player and target (boss fights, lock-on)
public class DynamicFrameCamera : MonoBehaviour
{
    [SerializeField] private Transform _player;
    [SerializeField] private Transform _target;
    [SerializeField] private float _padding = 2f;
    [SerializeField] private float _minSize = 5f;
    [SerializeField] private float _smoothSpeed = 3f;

    private Camera _cam;

    private void Awake() => _cam = GetComponent<Camera>();

    private void LateUpdate()
    {
        if (_target == null) return;

        // Center point between player and target
        Vector3 center = (_player.position + _target.position) * 0.5f;
        float distance = Vector3.Distance(_player.position, _target.position);

        // For orthographic 2D:
        float targetSize = Mathf.Max(distance * 0.5f + _padding, _minSize);
        _cam.orthographicSize = Mathf.Lerp(_cam.orthographicSize, targetSize, _smoothSpeed * Time.deltaTime);

        Vector3 targetPos = center;
        targetPos.z = transform.position.z;
        transform.position = Vector3.Lerp(transform.position, targetPos, _smoothSpeed * Time.deltaTime);
    }
}
```

---

**Execution Protocol**
1. **LateUpdate for Cameras**: ALL camera movement MUST happen in `LateUpdate()` to ensure it runs after player movement.
2. **SmoothDamp Over Lerp**: Use `Vector3.SmoothDamp` for camera follow — it handles deceleration naturally.
3. **Collision Avoidance**: 3D orbit cameras MUST use SphereCast to prevent clipping through geometry.
4. **Perlin Shake**: Use Perlin noise for camera shake, not random offsets — it produces smooth, natural-looking vibration.
5. **Dead Zones**: 2D cameras SHOULD have dead zones so the camera doesn't move on every tiny player movement.
