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
      ..sprite = await loadSprite('back.png') // Replace with your fish sprite
      ..size = Vector2(55, 55) // Adjust the size as needed
      ..position = size / 2; // Start in the middle of the screen
    add(fish!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Use the joystick's delta to move the fish
    fish?.position.add(joystick.relativeDelta * 200 * dt);
  }
}
