import 'package:adhan/adhan.dart';

class PrayerService {
  // Cairo Coordinates
  static const Coordinates cairo = Coordinates(30.0444, 31.2357);

  static CalculationParameters cairoParams() {
    // Egyptian General Authority of Survey (adhan supports it via CalculationMethod.egyptian) :contentReference[oaicite:2]{index=2}
    final p = CalculationMethod.egyptian.getParameters();
    p.madhab = Madhab.shafi; // Asr method (Shafi is common default)
    return p;
  }

  static PrayerTimes forCairo(DateTime date) {
    final dc = DateComponents.from(date);
    return PrayerTimes(cairo, dc, cairoParams());
  }
}
