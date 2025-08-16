import 'package:equatable/equatable.dart';
import '../models/cell_model.dart';

enum MatchStatus { idle, matching, valid, invalid, completed, timeUp }

class GameState extends Equatable {
  final List<List<CellModel>> grid;
  final int levelNumber;
  final int secondsRemaining;
  final MatchStatus matchStatus;
  final CellModel? firstSelectedCell;
  final bool completed;

  const GameState({
    required this.grid,
    required this.levelNumber,
    required this.secondsRemaining,
    required this.matchStatus,
    this.firstSelectedCell,
    this.completed = false,
  });

  bool get allPairsCompleted {
    final totalCells = grid.fold(0, (sum, row) => sum + row.length);
    final fadedCells = grid.fold(0, (sum, row) => sum + row.where((cell) => cell.state == CellState.faded).length);
    return fadedCells > 0 && fadedCells == totalCells;
  }

  GameState copyWith({
    List<List<CellModel>>? grid,
    int? levelNumber,
    int? secondsRemaining,
    MatchStatus? matchStatus,
    CellModel? firstSelectedCell,
    bool? completed,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      levelNumber: levelNumber ?? this.levelNumber,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      matchStatus: matchStatus ?? this.matchStatus,
      firstSelectedCell: firstSelectedCell,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props =>
      [grid, levelNumber, secondsRemaining, matchStatus, firstSelectedCell, completed];
}
