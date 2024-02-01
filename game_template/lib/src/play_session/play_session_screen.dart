import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

enum _CachedFishDirection { left, right }

typedef FishAnimation = SpriteAnimationComponent?;

class FishGame extends FlameGame {
  late JoystickComponent joystick;
  FishAnimation fish;

  late ParallaxComponent parallaxComponent;
  Vector2 parallaxOffset = Vector2.zero();
  double elapsedTime = 0.0;
  final double backgroundSpeed = -1 / 60;

  _CachedFishDirection _fishDirection = _CachedFishDirection.left;

  bool _updateAnimationNeeded = false;

  bool _isLoadingAnimation = false;

  var _fishSpriteFile = 'rest_to_left_sheet.png';

  void addJoystick() {
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: Paint()..color = Colors.blue),
      background: CircleComponent(
        radius: 60,
        paint: Paint()..color = Colors.blue.withOpacity(0.5),
      ),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick);
  }

  Future<void> addParallaxBackground() async {
    parallaxComponent = await loadParallaxComponent(
      [
        ParallaxImageData('background.png'),
      ],
      baseVelocity: Vector2(0, 0),
      velocityMultiplierDelta: Vector2(1, 1.0),
    );
    add(parallaxComponent);
  }

  _CachedFishDirection getDirectionFromJoystick() {
    switch (joystick.direction) {
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

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.cyan,
    );

    super.render(canvas);
  }

  @override
  void update(double dt) {
    super.update(dt);

    elapsedTime += dt;
    parallaxOffset.x = backgroundSpeed * dt;
    updateParallaxOffset();

    final newDirection = getDirectionFromJoystick();
    if (newDirection != _fishDirection ||
        joystick.direction == JoystickDirection.idle) {
      _fishDirection = newDirection;
      _updateAnimationNeeded = true;
    }

    if (_updateAnimationNeeded) {
      _updateAnimationNeeded = false;
      updateFishAnimation();
    }

    if (fish != null) {
      Vector2 delta = joystick.relativeDelta;
      const fishSpeed = 200.0;
      Vector2 newPosition = fish!.position + delta * fishSpeed * dt;

      newPosition.x = newPosition.x.clamp(0, size.x - fish!.width);
      newPosition.y = newPosition.y.clamp(0, size.y - fish!.height);

      fish!.position.setFrom(newPosition);
      fish?.rotateTowardsJoystick(joystick.direction);
    }
  }

  Future<void> updateFishAnimation() async {
    if (_isLoadingAnimation) return;
    _isLoadingAnimation = true;

    final spriteSheet = await images.load(_getFishSprite());
    const spriteWidth = 256.0;
    final spriteSize = Vector2(spriteWidth, spriteWidth);
    const animationFramesCount = 6;

    final newAnimation = SpriteAnimation.spriteList(
      List.generate(
        animationFramesCount,
        (index) => Sprite(
          spriteSheet,
          srcPosition: Vector2(spriteWidth * index, 0),
          srcSize: spriteSize,
        ),
      ),
      stepTime: 0.1,
    );

    if (fish == null) {
      fish = SpriteAnimationComponent(
        animation: newAnimation,
        size: spriteSize,
        position: size / 2,
      );
      await add(fish!);
    } else {
      fish!.animation = newAnimation;
    }

    _isLoadingAnimation = false;
  }

  void updateParallaxOffset() {
    for (ParallaxLayer layer in parallaxComponent.parallax!.layers) {
      Vector2 currentOffset = layer.currentOffset();
      currentOffset.x += parallaxOffset.x;
    }
  }

  String _getFishSprite() {
    switch (joystick.direction) {
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

extension FishAnimationExtension on FishAnimation {
  static double maxRotationAngle = 0.1;

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
