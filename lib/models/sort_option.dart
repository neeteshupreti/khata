enum SortField { name, date, amount }

enum SortDirection { asc, desc }

class SortOption {
  final SortField field;
  final SortDirection direction;
  const SortOption(this.field, this.direction);

  static const SortOption dateNewest =
      SortOption(SortField.date, SortDirection.desc);
}
