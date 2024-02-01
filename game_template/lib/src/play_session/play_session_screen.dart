import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class FishGame extends FlameGame {
  late JoystickComponent joystick;
  late SpriteComponent? fish;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    addJoystick();
    await addFish();
  }

  void addJoystick() {
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: Paint()..color = Colors.blue),
      background: CircleComponent(
          radius: 60, paint: Paint()..color = Colors.blue.withOpacity(0.5)),
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
    fish?.position.add(joystick.relativeDelta * 200 * dt);
  }
}
