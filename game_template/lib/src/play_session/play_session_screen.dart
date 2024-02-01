import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class FishGame extends FlameGame {
  late JoystickComponent joystick;
  late SpriteComponent? fish;

  late ParallaxComponent parallaxComponent;
  Vector2 parallaxOffset = Vector2.zero();
  double elapsedTime = 0.0;
  final double backgroundSpeed = -.1 / 4;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await addParallaxBackground();
    addJoystick();
    await addFish();
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

  addFish() async {
    fish = SpriteComponent()
      ..sprite = await loadSprite('back.png')
      ..size = Vector2(55, 55)
      ..position = size / 2;
    add(fish!);
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

    if (fish != null) {
      Vector2 delta = joystick.relativeDelta;
      var fishSpeed = 200.0;
      Vector2 newPosition = fish!.position + delta * fishSpeed * dt;

      newPosition.x = newPosition.x.clamp(0, size.x - fish!.width);
      newPosition.y = newPosition.y.clamp(0, size.y - fish!.height);

      fish!.position.setFrom(newPosition);
    }
  }

  void updateParallaxOffset() {
    for (ParallaxLayer layer in parallaxComponent.parallax!.layers) {
      Vector2 currentOffset = layer.currentOffset();
      currentOffset.x += parallaxOffset.x;
    }
  }
}
