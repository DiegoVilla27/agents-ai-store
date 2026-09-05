---
name: unity-fps-tps-controller
description: FPS and TPS controller mastery for Unity including camera systems, recoil, ADS (aim down sights), head bobbing, footsteps, weapon switching, and aim assist.
author: Diego Villanueva
trigger: When building first-person or third-person shooter controllers, implementing recoil, ADS, weapon systems, or shooter-specific camera behavior.
---

# FPS / TPS Controller

Shooter controllers require frame-perfect camera control, responsive movement, and convincing weapon feel. Every millisecond of input lag, every pixel of recoil, and every frame of ADS transition matters.

## 1. First-Person Camera Controller

```csharp
// ✅ Responsive FPS mouse look
public class FPSCamera : MonoBehaviour
{
    [SerializeField] private float _sensitivity = 2f;
    [SerializeField] private float _maxPitch = 85f;
    [SerializeField] private Transform _playerBody;

    private float _pitch;
    private float _yaw;

    private void Start() => Cursor.lockState = CursorLockMode.Locked;

    private void LateUpdate()
    {
        float mouseX = Input.GetAxis("Mouse X") * _sensitivity;
        float mouseY = Input.GetAxis("Mouse Y") * _sensitivity;

        _yaw += mouseX;
        _pitch -= mouseY;
        _pitch = Mathf.Clamp(_pitch, -_maxPitch, _maxPitch);

        transform.localRotation = Quaternion.Euler(_pitch, 0f, 0f);
        _playerBody.rotation = Quaternion.Euler(0f, _yaw, 0f);
    }
}
```

## 2. FPS Movement

```csharp
// ✅ Responsive FPS movement with CharacterController
public class FPSMovement : MonoBehaviour
{
    [Header("Movement")]
    [SerializeField] private float _walkSpeed = 5f;
    [SerializeField] private float _sprintSpeed = 8f;
    [SerializeField] private float _crouchSpeed = 2.5f;

    [Header("Jump")]
    [SerializeField] private float _jumpHeight = 1.2f;
    [SerializeField] private float _gravity = -20f;

    [Header("Head Bob")]
    [SerializeField] private float _bobFrequency = 10f;
    [SerializeField] private float _bobAmplitude = 0.05f;

    private CharacterController _cc;
    private Vector3 _velocity;
    private float _bobTimer;
    private Transform _cameraTransform;

    private void Update()
    {
        bool isGrounded = _cc.isGrounded;
        if (isGrounded && _velocity.y < 0) _velocity.y = -2f;

        float x = Input.GetAxisRaw("Horizontal");
        float z = Input.GetAxisRaw("Vertical");
        bool isSprinting = Input.GetKey(KeyCode.LeftShift);

        float speed = isSprinting ? _sprintSpeed : _walkSpeed;
        Vector3 move = transform.right * x + transform.forward * z;
        _cc.Move(move.normalized * (speed * Time.deltaTime));

        // Jump
        if (Input.GetButtonDown("Jump") && isGrounded)
            _velocity.y = Mathf.Sqrt(_jumpHeight * -2f * _gravity);

        _velocity.y += _gravity * Time.deltaTime;
        _cc.Move(_velocity * Time.deltaTime);

        // Head bob
        if (isGrounded && move.magnitude > 0.1f)
        {
            _bobTimer += Time.deltaTime * _bobFrequency * (isSprinting ? 1.5f : 1f);
            float bobY = Mathf.Sin(_bobTimer) * _bobAmplitude;
            float bobX = Mathf.Cos(_bobTimer * 0.5f) * _bobAmplitude * 0.5f;
            _cameraTransform.localPosition = new Vector3(bobX, _cameraTransform.localPosition.y + bobY, 0);
        }
        else
        {
            _bobTimer = 0;
        }
    }
}
```

## 3. Weapon Recoil System

```csharp
// ✅ Smooth recoil with recovery
public class RecoilSystem : MonoBehaviour
{
    [SerializeField] private float _recoilX = -2f; // Vertical kick
    [SerializeField] private float _recoilY = 1f;  // Horizontal spread
    [SerializeField] private float _recoilZ = 0.5f; // Roll
    [SerializeField] private float _snapSpeed = 10f; // How fast recoil applies
    [SerializeField] private float _returnSpeed = 6f; // How fast it recovers

    private Vector3 _currentRotation;
    private Vector3 _targetRotation;

    public void AddRecoil()
    {
        _targetRotation += new Vector3(
            _recoilX,
            Random.Range(-_recoilY, _recoilY),
            Random.Range(-_recoilZ, _recoilZ));
    }

    private void Update()
    {
        _targetRotation = Vector3.Lerp(_targetRotation, Vector3.zero, _returnSpeed * Time.deltaTime);
        _currentRotation = Vector3.Slerp(_currentRotation, _targetRotation, _snapSpeed * Time.deltaTime);
        transform.localRotation = Quaternion.Euler(_currentRotation);
    }
}
```

## 4. Aim Down Sights (ADS)

```csharp
// ✅ Smooth ADS transition
public class ADSController : MonoBehaviour
{
    [SerializeField] private Transform _weaponTransform;
    [SerializeField] private Vector3 _hipPosition;
    [SerializeField] private Vector3 _adsPosition;
    [SerializeField] private float _adsSpeed = 8f;
    [SerializeField] private float _adsFOV = 45f;
    [SerializeField] private float _normalFOV = 60f;
    [SerializeField] private float _adsSensitivityMultiplier = 0.6f;

    private Camera _camera;
    private bool _isAiming;

    private void Update()
    {
        _isAiming = Input.GetButton("Fire2"); // Right mouse button

        Vector3 targetPos = _isAiming ? _adsPosition : _hipPosition;
        float targetFOV = _isAiming ? _adsFOV : _normalFOV;

        _weaponTransform.localPosition = Vector3.Lerp(
            _weaponTransform.localPosition, targetPos, _adsSpeed * Time.deltaTime);
        _camera.fieldOfView = Mathf.Lerp(
            _camera.fieldOfView, targetFOV, _adsSpeed * Time.deltaTime);
    }

    public float GetSensitivityMultiplier() =>
        _isAiming ? _adsSensitivityMultiplier : 1f;
}
```

## 5. Weapon System

```csharp
// ✅ Weapon switching system
public class WeaponManager : MonoBehaviour
{
    [SerializeField] private WeaponController[] _weapons;
    private int _currentIndex;

    private void Update()
    {
        // Number keys
        for (int i = 0; i < _weapons.Length && i < 9; i++)
        {
            if (Input.GetKeyDown(KeyCode.Alpha1 + i))
                SwitchWeapon(i);
        }

        // Scroll wheel
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        if (scroll > 0) SwitchWeapon((_currentIndex + 1) % _weapons.Length);
        if (scroll < 0) SwitchWeapon((_currentIndex - 1 + _weapons.Length) % _weapons.Length);
    }

    private void SwitchWeapon(int newIndex)
    {
        if (newIndex == _currentIndex) return;

        _weapons[_currentIndex].Holster();
        _currentIndex = newIndex;
        _weapons[_currentIndex].Draw();
    }
}
```

## 6. Hitscan & Projectile

```csharp
// ✅ Hitscan weapon (instant raycast)
public void FireHitscan()
{
    Vector3 origin = _camera.transform.position;
    Vector3 direction = _camera.transform.forward;

    // Spread
    direction += (Vector3)Random.insideUnitCircle * _spreadAmount;
    direction.Normalize();

    if (Physics.Raycast(origin, direction, out var hit, _range, _hitLayer))
    {
        hit.collider.GetComponent<IDamageable>()?.TakeDamage(_damage);
        SpawnImpactVFX(hit.point, hit.normal);
        SpawnBulletTrail(origin, hit.point);
    }

    _recoil.AddRecoil();
    _muzzleFlash.Play();
    _audioSource.PlayOneShot(_fireSound);
}
```

---

**Execution Protocol**
1. **LateUpdate for Camera**: Mouse look MUST run in `LateUpdate` to prevent jitter.
2. **Cursor Lock**: Lock cursor on play (`CursorLockMode.Locked`), unlock on pause/menu.
3. **Recoil Recovery**: Recoil must ALWAYS recover smoothly. Never leave the camera displaced permanently.
4. **ADS Sensitivity Reduction**: ALWAYS reduce mouse sensitivity during ADS (0.5-0.7x normal) for precision aiming.
5. **Hitscan from Camera Center**: Shoot rays from camera center, NOT from the gun barrel, to ensure what you see is what you hit.
