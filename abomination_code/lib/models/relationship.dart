class Relationship {
  final double admiration; // 0.0 to 5.0
  final double respect; // 0.0 to 5.0
  final double fear; // 0.0 to 5.0
  final double attraction; // 0.0 to 5.0

  Relationship({
    this.admiration = 2.5,
    this.respect = 2.5,
    this.fear = 2.5,
    this.attraction = 2.5,
  });

  double get loyalty => (admiration + respect + fear) / 3.0;

  Relationship copyWith({
    double? admiration,
    double? respect,
    double? fear,
    double? attraction,
  }) {
    return Relationship(
      admiration: (admiration ?? this.admiration).clamp(0.0, 5.0),
      respect: (respect ?? this.respect).clamp(0.0, 5.0),
      fear: (fear ?? this.fear).clamp(0.0, 5.0),
      attraction: (attraction ?? this.attraction).clamp(0.0, 5.0),
    );
  }

  /// Evolve relationship based on butler disposition and general satisfaction.
  Relationship evolve({
    required bool isKind,
    required bool isStern,
    required double satisfaction,
  }) {
    double dAdmiration = 0.0;
    double dRespect = 0.0;
    double dFear = 0.0;
    double dAttraction = 0.0;

    // Passive evolution based on satisfaction
    if (satisfaction > 70) {
      dAdmiration += 0.005;
      dAttraction += 0.002;
    } else if (satisfaction < 30) {
      dRespect -= 0.005;
      dFear += 0.005;
    }

    // Butler Disposition impacts
    if (isKind) {
      dAdmiration += 0.01;
      dAttraction += 0.005;
    } else if (isStern) {
      dRespect += 0.015;
      dFear += 0.01;
      dAdmiration -= 0.005;
    }

    return copyWith(
      admiration: admiration + dAdmiration,
      respect: respect + dRespect,
      fear: fear + dFear,
      attraction: attraction + dAttraction,
    );
  }

  Map<String, dynamic> toJson() => {
    'admiration': admiration,
    'respect': respect,
    'fear': fear,
    'attraction': attraction,
  };

  factory Relationship.fromJson(Map<String, dynamic> json) => Relationship(
    admiration: (json['admiration'] as num?)?.toDouble() ?? 2.5,
    respect: (json['respect'] as num?)?.toDouble() ?? 2.5,
    fear: (json['fear'] as num?)?.toDouble() ?? 2.5,
    attraction: (json['attraction'] as num?)?.toDouble() ?? 2.5,
  );
}
