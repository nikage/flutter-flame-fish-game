import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class FishGame extends FlameGame {
  late JoystickComponent joystick;
  SpriteAnimationComponent? fish;

  late ParallaxComponent parallaxComponent;
  Vector2 parallaxOffset = Vector2.zero();
  double elapsedTime = 0.0;
  final double backgroundSpeed = -1 / 60;

  CachedFishDirection _currentFishDirection = CachedFishDirection.left;

  bool _updateAnimationNeeded = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await addParallaxBackground();
    addJoystick();
    await loadFishAnimation();
  }

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

  Future<void> loadFishAnimation() async {
    await updateFishAnimation();
  }

  Future<void> updateFishAnimation() async {
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
  }

  var _fishSpriteFile = 'rest_to_left_sheet.png';
  CachedFishDirection _fishDirection = CachedFishDirection.left;

  String _getFishSprite() {
    switch (joystick.direction) {
      case JoystickDirection.up:
      case JoystickDirection.down:
      case JoystickDirection.left:
        _fishDirection = CachedFishDirection.left;
        _fishSpriteFile = 'swim_to_left_sheet.png';
      case JoystickDirection.right:
        _fishDirection = CachedFishDirection.right;
        _fishSpriteFile = 'swim_to_right_sheet.png';
      case JoystickDirection.idle:
        _fishDirection == CachedFishDirection.left
            ? _fishSpriteFile = 'rest_to_left_sheet.png'
            : _fishSpriteFile = 'rest_to_right_sheet.png';

      case JoystickDirection.upLeft:
        _fishDirection = CachedFishDirection.left;
        _fishSpriteFile = 'swim_to_left_sheet.png';
      case JoystickDirection.upRight:
        _fishDirection = CachedFishDirection.right;
        _fishSpriteFile = 'swim_to_right_sheet.png';
      case JoystickDirection.downRight:
        _fishDirection = CachedFishDirection.right;
        _fishSpriteFile = 'swim_to_right_sheet.png';
      case JoystickDirection.downLeft:
        _fishDirection = CachedFishDirection.left;
        _fishSpriteFile = 'swim_to_left_sheet.png';
    }
    return _fishSpriteFile;
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
    if (newDirection != _currentFishDirection) {
      _currentFishDirection = newDirection;
      _updateAnimationNeeded = true;
    }

    if (_updateAnimationNeeded) {
      _updateAnimationNeeded = false;
      updateFishAnimation();
    }

    if (fish != null) {
      Vector2 delta = joystick.relativeDelta;
      var fishSpeed = 200.0;
      Vector2 newPosition = fish!.position + delta * fishSpeed * dt;

      newPosition.x = newPosition.x.clamp(0, size.x - fish!.width);
      newPosition.y = newPosition.y.clamp(0, size.y - fish!.height);

      fish!.position.setFrom(newPosition);
    }
  }

  CachedFishDirection getDirectionFromJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        return CachedFishDirection.left;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        return CachedFishDirection.right;
      default:
        return _currentFishDirection;
    }
  }

  void updateParallaxOffset() {
    for (ParallaxLayer layer in parallaxComponent.parallax!.layers) {
      Vector2 currentOffset = layer.currentOffset();
      currentOffset.x += parallaxOffset.x;
    }
  }
}

enum CachedFishDirection { left, right }
