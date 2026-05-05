/// Time window for AI report generation (filters stored assessments).
enum ReportTimeRange {
  last7Days,
  last30Days,
  last90Days,
  yearToDate,
  allTime,
}

extension ReportTimeRangeX on ReportTimeRange {
  String get labelAr => switch (this) {
        ReportTimeRange.last7Days => 'آخر 7 أيام',
        ReportTimeRange.last30Days => 'آخر 30 يوماً',
        ReportTimeRange.last90Days => 'آخر 90 يوماً',
        ReportTimeRange.yearToDate => 'من بداية السنة حتى اليوم',
        ReportTimeRange.allTime => 'كل الفترات',
      };

  /// Inclusive date bounds for filtering assessment `date` fields; `(null,null)` = no filter.
  (DateTime?, DateTime?) dateBounds(DateTime now) {
    final end = now;
    switch (this) {
      case ReportTimeRange.last7Days:
        return (now.subtract(const Duration(days: 7)), end);
      case ReportTimeRange.last30Days:
        return (now.subtract(const Duration(days: 30)), end);
      case ReportTimeRange.last90Days:
        return (now.subtract(const Duration(days: 90)), end);
      case ReportTimeRange.yearToDate:
        return (DateTime(now.year, 1, 1), end);
      case ReportTimeRange.allTime:
        return (null, null);
    }
  }
}
