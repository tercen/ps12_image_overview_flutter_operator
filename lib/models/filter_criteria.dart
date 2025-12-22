/// Criteria for filtering images.
class FilterCriteria {
  final int? cycle;
  final int? exposureTime;

  const FilterCriteria({
    this.cycle,
    this.exposureTime,
  });

  /// Creates a copy with updated fields.
  FilterCriteria copyWith({
    int? cycle,
    int? exposureTime,
  }) {
    return FilterCriteria(
      cycle: cycle ?? this.cycle,
      exposureTime: exposureTime ?? this.exposureTime,
    );
  }

  /// Checks if any filters are active.
  bool get hasActiveFilters => cycle != null || exposureTime != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterCriteria &&
          runtimeType == other.runtimeType &&
          cycle == other.cycle &&
          exposureTime == other.exposureTime;

  @override
  int get hashCode => cycle.hashCode ^ exposureTime.hashCode;
}
