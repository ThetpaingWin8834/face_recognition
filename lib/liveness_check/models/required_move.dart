
enum RequiredMove {
  turnLeft,
  turnRight,
  eyeBlink;

  String displayMessage() {
    return switch (this) {
      RequiredMove.turnLeft => 'Turn Your Face To LEFT',
      RequiredMove.turnRight => 'Turn Your Face To RIGHT',
      RequiredMove.eyeBlink => 'Blink Your EYES',
    };
  }
}
