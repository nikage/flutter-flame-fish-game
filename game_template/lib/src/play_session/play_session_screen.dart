import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

typedef FishAnimation = SpriteAnimationComponent?;

class FishGame extends FlameGame {
  final _kBackgroundSpeed = -1 / 60;
  late JoystickComponent _joystick;
  late ParallaxComponent _backgroundParallax;
  FishAnimation fish;
  var _parallaxOffset = Vector2.zero();
  var _fishDirection = _CachedFishDirection.left;
  var _updateAnimationNeeded = false;
  var _isLoadingAnimation = false;
  var _fishSpriteFile = 'rest_to_left_sheet.png';

  void addJoystick() {
    _joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: Paint()..color = Colors.blue),
      background: CircleComponent(
        radius: 60,
        paint: Paint()..color = Colors.blue.withOpacity(0.5),
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

  _CachedFishDirection getDirectionFromJoystick() {
    switch (_joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        return _CachedFishDirection.left;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        return _CachedFishDirection.right;
      default:
        return _fishDirection;
    }
  }

  Future<void> loadFishAnimation() async {
    await updateFishAnimation();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await addParallaxBackground();
    addJoystick();
    await loadFishAnimation();
  }

  // @override
  // void render(Canvas canvas) {
  //   canvas.drawRect(
  //     Rect.fromLTWH(0, 0, size.x, size.y),
  //     Paint()..color = Colors.cyan,
  //   );
  //
  //   super.render(canvas);
  // }

  @override
  void update(double dt) {
    super.update(dt);

    _parallaxOffset.x = _kBackgroundSpeed * dt;
    _updateParallaxOffset();

    final newDirection = getDirectionFromJoystick();
    if (newDirection != _fishDirection ||
        _joystick.direction == JoystickDirection.idle) {
      _fishDirection = newDirection;
      _updateAnimationNeeded = true;
    }

    if (_updateAnimationNeeded) {
      _updateAnimationNeeded = false;
      updateFishAnimation();
    }

    if (fish != null) {
      Vector2 delta = _joystick.relativeDelta;

      Vector2 newPosition = fish!.position + delta * fish.speed * dt;

      newPosition.x = newPosition.x.clamp(0, size.x - fish!.width);
      newPosition.y = newPosition.y.clamp(0, size.y - fish!.height);

      fish!.position.setFrom(newPosition);
      fish?.rotateTowardsJoystick(_joystick.direction);
    }
  }

  Future<void> updateFishAnimation() async {
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
      fish = SpriteAnimationComponent(
        animation: newAnimation,
        size: kSpriteSize,
        position: size / 2,
      );
      await add(fish!);
    } else {
      fish!.animation = newAnimation;
    }

    _isLoadingAnimation = false;
  }

  void _updateParallaxOffset() {
    for (ParallaxLayer layer in _backgroundParallax.parallax!.layers) {
      Vector2 currentOffset = layer.currentOffset();
      currentOffset.x += _parallaxOffset.x;
    }
  }

  String _getFishSprite() {
    switch (_joystick.direction) {
      case JoystickDirection.up:
      case JoystickDirection.down:
      case JoystickDirection.left:
        _fishDirection = _CachedFishDirection.left;
        _fishSpriteFile = 'swim_to_left_sheet.png';
        break;
      case JoystickDirection.right:
        _fishDirection = _CachedFishDirection.right;
        _fishSpriteFile = 'swim_to_right_sheet.png';
        break;
      case JoystickDirection.idle:
        _fishSpriteFile = _fishDirection == _CachedFishDirection.left
            ? 'rest_to_left_sheet.png'
            : 'rest_to_right_sheet.png';
        break;
      case JoystickDirection.upLeft:
        _fishDirection = _CachedFishDirection.left;
        _fishSpriteFile = 'swim_to_left_sheet.png';
        break;
      case JoystickDirection.upRight:
        _fishDirection = _CachedFishDirection.right;
        _fishSpriteFile = 'swim_to_right_sheet.png';
        break;
      case JoystickDirection.downRight:
        _fishDirection = _CachedFishDirection.right;
        _fishSpriteFile = 'swim_to_right_sheet.png';
        break;
      case JoystickDirection.downLeft:
        _fishDirection = _CachedFishDirection.left;
        _fishSpriteFile = 'swim_to_left_sheet.png';
        break;
      default:
        break;
    }
    return _fishSpriteFile;
  }
}

enum _CachedFishDirection { left, right }

extension FishAnimationExtension on FishAnimation {
  static double maxRotationAngle = 0.1;

  get speed => 200.0;

  void rotateTowardsJoystick(JoystickDirection direction) {
    if (direction == JoystickDirection.up ||
        direction == JoystickDirection.upLeft ||
        direction == JoystickDirection.upRight) {
      this?.angle = -maxRotationAngle; // Rotate upwards
    } else if (direction == JoystickDirection.down ||
        direction == JoystickDirection.downLeft ||
        direction == JoystickDirection.downRight) {
      this?.angle = maxRotationAngle; // Rotate downwards
    } else {
      this?.angle = 0; // No rotation
    }
  }
}
