class GameDate {
  final int minute;
  final int hour;
  final int day;
  final int month;
  final int year;

  GameDate({
    this.minute = 0,
    required this.hour,
    required this.day,
    required this.month,
    required this.year,
  });

  int get hourIndex => ((day - 1) % 7) * 24 + hour;

  int get totalMinutes {
    return (year - 1818) * 12 * 30 * 24 * 60 +
        (month - 1) * 30 * 24 * 60 +
        (day - 1) * 24 * 60 +
        hour * 60 +
        minute;
  }

  factory GameDate.initial() {
    // Starting in 1818
    return GameDate(minute: 0, hour: 8, day: 1, month: 3, year: 1818);
  }

  GameDate addMinute() {
    int newMinute = minute + 1;
    int newHour = hour;
    int newDay = day;
    int newMonth = month;
    int newYear = year;

    if (newMinute >= 60) {
      newMinute = 0;
      newHour++;
    }

    if (newHour >= 24) {
      newHour = 0;
      newDay++;
    }

    if (newDay > 30) {
      newDay = 1;
      newMonth++;
    }

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }

    return GameDate(
      minute: newMinute,
      hour: newHour,
      day: newDay,
      month: newMonth,
      year: newYear,
    );
  }

  GameDate addHour() {
    int newHour = hour + 1;
    int newDay = day;
    int newMonth = month;
    int newYear = year;

    if (newHour >= 24) {
      newHour = 0;
      newDay++;
    }

    if (newDay > 30) {
      newDay = 1;
      newMonth++;
    }

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }

    return GameDate(
      minute: minute,
      hour: newHour,
      day: newDay,
      month: newMonth,
      year: newYear,
    );
  }

  String get formattedDate {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return "${months[month - 1]} $day, $year";
  }

  String get formattedTime {
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  Map<String, dynamic> toJson() => {
    'minute': minute,
    'hour': hour,
    'day': day,
    'month': month,
    'year': year,
  };

  factory GameDate.fromJson(Map<String, dynamic> json) => GameDate(
    minute: json['minute'] as int? ?? 0,
    hour: json['hour'] as int,
    day: json['day'] as int,
    month: json['month'] as int,
    year: json['year'] as int,
  );

  DateTime toDateTime() {
    return DateTime(year, month, day, hour, minute);
  }

  GameDate copy() {
    return GameDate(
      minute: minute,
      hour: hour,
      day: day,
      month: month,
      year: year,
    );
  }

  GameDate copyWith({
    int? minute,
    int? hour,
    int? day,
    int? month,
    int? year,
  }) {
    return GameDate(
      minute: minute ?? this.minute,
      hour: hour ?? this.hour,
      day: day ?? this.day,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}
