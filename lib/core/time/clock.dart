/// Fonte de tempo injetável, para que regras que dependem da data
/// possam ser testadas com um relógio fixo.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
