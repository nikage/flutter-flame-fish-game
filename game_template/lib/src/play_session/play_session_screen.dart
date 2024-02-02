import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class FishGame extends FlameGame {
  final _kBackgroundSpeed = -1 / 60;
  final _parallaxOffset = Vector2.zero();
  late JoystickComponent _joystick;
  late ParallaxComponent _backgroundParallax;
  var _idleFishDirection = _IdleFishDirection.left;
  var _updateAnimationNeeded = false;
  var _isLoadingAnimation = false;
  var _wasIdleLastFrame = true;
  Fish? fish;

  void addJoystick() {
    _joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: Paint()..color = Colors.blue),
      background: CircleComponent(
        radius: 60,
        paint: Paint()..color = Colors.blue.withOpacity(0.4),
      ),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(_joystick);
  }

  Future<void> addParallaxBackground() async {
    _backgroundParallax = await loadParallaxComponent(
      [
        ParallaxImageData('background.png'),
      ],
      baseVelocity: Vector2(0, 0),
      velocityMultiplierDelta: Vector2(1, 1.0),
    );
    add(_backgroundParallax);
  }

  _IdleFishDirection _getDirectionFromJoystick() {
    switch (_joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        return _IdleFishDirection.left;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        return _IdleFishDirection.right;
      default:
        return _idleFishDirection;
    }
  }

  Future<void> loadFishAnimation() async {
    await _updateFishAnimation();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await addParallaxBackground();
    addJoystick();
    await loadFishAnimation();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _parallaxOffset.x = _kBackgroundSpeed * dt;
    _updateParallaxOffset();

    final newDirection = _getDirectionFromJoystick();
    bool isFishIdle = _joystick.direction == JoystickDirection.idle;
    bool directionChanged = newDirection != _idleFishDirection;
    bool idleTransition = isFishIdle && !_wasIdleLastFrame;

    // Update the animation when the direction changes or when transitioning to idle
    if (directionChanged || idleTransition) {
      _idleFishDirection = isFishIdle ? _idleFishDirection : newDirection;
      _updateAnimationNeeded = true;
      _wasIdleLastFrame = isFishIdle;
    } else if (!isFishIdle) {
      _wasIdleLastFrame = false;
    }

    if (_updateAnimationNeeded) {
      _updateAnimationNeeded = false;
      _updateFishAnimation();
    }

    if (fish != null) {
      Vector2 delta = _joystick.relativeDelta;

      Vector2 newPosition = fish!.position + delta * fish!.speed * dt;

      newPosition.x = newPosition.x.clamp(0, size.x - fish!.width);
      newPosition.y = newPosition.y.clamp(0, size.y - fish!.height);

      fish!.position.setFrom(newPosition);
      fish?.rotateTowardsJoystick(_joystick.direction);
    }
  }

  _updateFishAnimation() async {
    if (_isLoadingAnimation) return;
    _isLoadingAnimation = true;

    final spriteSheet = await images.load(_getFishSprite());
    const kSpriteWidth = 256.0;
    final kSpriteSize = Vector2.all(kSpriteWidth);
    const kAnimationFramesCount = 6;

    final newAnimation = SpriteAnimation.spriteList(
      List.generate(
        kAnimationFramesCount,
        (index) => Sprite(
          spriteSheet,
          srcPosition: Vector2(kSpriteWidth * index, 0),
          srcSize: kSpriteSize,
        ),
      ),
      stepTime: 0.1,
    );

    if (fish == null) {
      fish = Fish.fromSpriteAnimations(
        SpriteAnimationComponent(
          animation: newAnimation,
          size: kSpriteSize,
          position: size / 2,
        ),
      );
      await add(fish!);
    } else {
      fish!.animation = newAnimation;
    }

    _isLoadingAnimation = false;
  }

  void _updateParallaxOffset() {
    for (ParallaxLayer layer in _backgroundParallax.parallax!.layers) {
      var currentOffset = layer.currentOffset();
      currentOffset.x += _parallaxOffset.x;
    }
  }

  String _getFishSprite() {
    switch (_joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        return 'swim_to_left_sheet.png';
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        return 'swim_to_right_sheet.png';
      default:
        return _idleFishDirection == _IdleFishDirection.left
            ? 'rest_to_left_sheet.png'
            : 'rest_to_right_sheet.png';
    }
  }
}

enum _IdleFishDirection { left, right }

class Fish extends SpriteAnimationComponent {
  Fish.fromSpriteAnimations(SpriteAnimationComponent animation) {
    this.animation = animation.animation;
  }

  static const double _maxRotationAngle = 0.1;

  final speed = 100.0;

  void rotateTowardsJoystick(JoystickDirection direction) {
    if (direction == JoystickDirection.up ||
        direction == JoystickDirection.upLeft ||
        direction == JoystickDirection.upRight) {
      angle = -_maxRotationAngle; // Rotate upwards
    } else if (direction == JoystickDirection.down ||
        direction == JoystickDirection.downLeft ||
        direction == JoystickDirection.downRight) {
      angle = _maxRotationAngle; // Rotate downwards
    } else {
      angle = 0; // No rotation
    }
  }
}
