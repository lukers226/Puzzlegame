class LevelModel {
  final int levelNumber;
  final int maxRows;
  final int maxColumns;
  final Duration timeLimit;
  final int maxAddRows;
  final String constraint;

  LevelModel({
    required this.levelNumber,
    required this.maxRows,
    required this.maxColumns,
    required this.timeLimit,
    required this.maxAddRows,
    required this.constraint,
  });
}
