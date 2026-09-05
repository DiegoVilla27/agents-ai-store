---
name: unity-platformer-2d
description: 2D platformer controller mastery for Unity including tight movement controls, coyote time, input buffering, wall jump/slide, one-way platforms, and moving platforms.
author: Diego Villanueva
trigger: When building 2D platformer movement, implementing coyote time, wall jumping, one-way platforms, or tuning platformer game feel.
---

# 2D Platformer Controller

Platformer controls are the most nuanced system in game development. Milliseconds of input buffer, pixels of coyote time, and frames of animation cancel define the difference between "tight" and "floaty." This document codifies professional platformer movement.

## 1. Core Movement Controller

```csharp
// ✅ Professional 2D platformer controller
public class PlatformerController : MonoBehaviour
{
    [Header("Movement")]
    [SerializeField] private float _maxSpeed = 10f;
    [SerializeField] private float _acceleration = 60f;
    [SerializeField] private float _deceleration = 80f;
    [SerializeField] private float _airAcceleration = 40f;

    [Header("Jump")]
    [SerializeField] private float _jumpForce = 18f;
    [SerializeField] private float _jumpCutMultiplier = 0.5f;
    [SerializeField] private float _coyoteTime = 0.1f;
    [SerializeField] private float _jumpBufferTime = 0.15f;
    [SerializeField] private float _fallGravityMultiplier = 2.5f;
    [SerializeField] private float _maxFallSpeed = 25f;

    [Header("Ground Check")]
    [SerializeField] private Transform _groundCheck;
    [SerializeField] private Vector2 _groundCheckSize = new(0.5f, 0.05f);
    [SerializeField] private LayerMask _groundLayer;

    private Rigidbody2D _rb;
    private float _moveInput;
    private float _coyoteTimer;
    private float _jumpBufferTimer;
    private bool _isGrounded;
    private bool _isJumping;

    private void Awake() => _rb = GetComponent<Rigidbody2D>();

    private void Update()
    {
        // Read input
        _moveInput = Input.GetAxisRaw("Horizontal");

        // Ground check
        _isGrounded = Physics2D.OverlapBox(
            _groundCheck.position, _groundCheckSize, 0f, _groundLayer);

        // Coyote time
        if (_isGrounded)
        {
            _coyoteTimer = _coyoteTime;
            _isJumping = false;
        }
        else
        {
            _coyoteTimer -= Time.deltaTime;
        }

        // Jump buffer
        if (Input.GetButtonDown("Jump"))
            _jumpBufferTimer = _jumpBufferTime;
        else
            _jumpBufferTimer -= Time.deltaTime;

        // Jump execution
        if (_jumpBufferTimer > 0 && _coyoteTimer > 0 && !_isJumping)
        {
            _rb.linearVelocity = new Vector2(_rb.linearVelocity.x, _jumpForce);
            _jumpBufferTimer = 0;
            _coyoteTimer = 0;
            _isJumping = true;
        }

        // Variable jump height (release to cut jump short)
        if (Input.GetButtonUp("Jump") && _rb.linearVelocity.y > 0)
        {
            _rb.linearVelocity = new Vector2(_rb.linearVelocity.x,
                _rb.linearVelocity.y * _jumpCutMultiplier);
        }
    }

    private void FixedUpdate()
    {
        // Horizontal movement with acceleration
        float targetSpeed = _moveInput * _maxSpeed;
        float accel = _isGrounded ? _acceleration : _airAcceleration;
        float decel = _isGrounded ? _deceleration : _airAcceleration;

        float speedDiff = targetSpeed - _rb.linearVelocity.x;
        float rate = (Mathf.Abs(targetSpeed) > 0.01f) ? accel : decel;
        float force = speedDiff * rate;

        _rb.AddForce(Vector2.right * force);

        // Better falling: higher gravity when falling
        if (_rb.linearVelocity.y < 0)
        {
            _rb.gravityScale = _fallGravityMultiplier;
            _rb.linearVelocity = new Vector2(_rb.linearVelocity.x,
                Mathf.Max(_rb.linearVelocity.y, -_maxFallSpeed));
        }
        else
        {
            _rb.gravityScale = 1f;
        }
    }
}
```

## 2. Wall Jump & Wall Slide

```csharp
// ✅ Wall slide and wall jump
[Header("Wall")]
[SerializeField] private float _wallSlideSpeed = 2f;
[SerializeField] private Vector2 _wallJumpForce = new(12f, 18f);
[SerializeField] private float _wallJumpLockTime = 0.2f;
[SerializeField] private Transform _wallCheck;
[SerializeField] private float _wallCheckDistance = 0.3f;

private bool _isWallSliding;
private int _wallDirection;

private void CheckWallSlide()
{
    bool isTouchingWall = Physics2D.Raycast(
        _wallCheck.position, Vector2.right * _moveInput,
        _wallCheckDistance, _groundLayer);

    _isWallSliding = isTouchingWall && !_isGrounded && _rb.linearVelocity.y < 0;

    if (_isWallSliding)
    {
        _wallDirection = _moveInput > 0 ? 1 : -1;
        _rb.linearVelocity = new Vector2(_rb.linearVelocity.x,
            Mathf.Max(_rb.linearVelocity.y, -_wallSlideSpeed));
    }
}

private void WallJump()
{
    if (!_isWallSliding) return;

    _rb.linearVelocity = new Vector2(
        _wallJumpForce.x * -_wallDirection, // Jump away from wall
        _wallJumpForce.y);

    // Brief input lock to prevent immediately re-grabbing wall
    StartCoroutine(LockInput(_wallJumpLockTime));
}
```

## 3. One-Way Platforms

```text
Setup:
1. Create platform with BoxCollider2D
2. Set BoxCollider2D → Used By Effector: ✅
3. Add PlatformEffector2D:
   - Use One Way: ✅
   - Use One Way Grouping: ✅
   - Surface Arc: 180° (only solid from above)

Drop-through:
```

```csharp
// ✅ Drop through one-way platform
public class OneWayPlatform : MonoBehaviour
{
    private Collider2D _collider;
    private float _disableTimer;

    private void Awake() => _collider = GetComponent<Collider2D>();

    public void DisableTemporarily(float duration = 0.25f)
    {
        _collider.enabled = false;
        _disableTimer = duration;
    }

    private void Update()
    {
        if (_disableTimer > 0)
        {
            _disableTimer -= Time.deltaTime;
            if (_disableTimer <= 0) _collider.enabled = true;
        }
    }
}
```

## 4. Moving Platforms

```csharp
// ✅ Moving platform that carries the player
public class MovingPlatform : MonoBehaviour
{
    [SerializeField] private Vector3[] _waypoints;
    [SerializeField] private float _speed = 3f;
    [SerializeField] private float _waitTime = 1f;

    private int _currentWaypoint;
    private float _waitTimer;
    private Rigidbody2D _rb;

    private void Awake()
    {
        _rb = GetComponent<Rigidbody2D>();
        _rb.bodyType = RigidbodyType2D.Kinematic;
    }

    private void FixedUpdate()
    {
        Vector3 target = _waypoints[_currentWaypoint];
        Vector3 newPos = Vector3.MoveTowards(
            _rb.position, target, _speed * Time.fixedDeltaTime);

        _rb.MovePosition(newPos);

        if (Vector3.Distance(newPos, target) < 0.01f)
        {
            _waitTimer += Time.fixedDeltaTime;
            if (_waitTimer >= _waitTime)
            {
                _currentWaypoint = (_currentWaypoint + 1) % _waypoints.Length;
                _waitTimer = 0f;
            }
        }
    }

    // Parent player to platform when standing on it
    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (collision.gameObject.CompareTag("Player"))
            collision.transform.SetParent(transform);
    }

    private void OnCollisionExit2D(Collision2D collision)
    {
        if (collision.gameObject.CompareTag("Player"))
            collision.transform.SetParent(null);
    }
}
```

---

**Execution Protocol**
1. **Coyote Time is Mandatory**: Allow 0.08-0.15s of jump grace after leaving a ledge. Without it, jumps feel unfair.
2. **Input Buffering is Mandatory**: Buffer jump input for 0.1-0.2s before landing. Without it, jumps feel unresponsive.
3. **Variable Jump Height**: Cut velocity on button release for precision platforming.
4. **Fall Gravity Multiplier**: Increase gravity when falling (2-3x) for snappy, weighty jumps. Don't use the same gravity for rising and falling.
5. **Force-Based Movement**: Use `AddForce` with acceleration/deceleration curves, not direct velocity setting, for smooth momentum.
