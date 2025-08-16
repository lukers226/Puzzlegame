import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cell_model.dart';
import '../models/level_model.dart';
import '../services/game_controller.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameController gameController;
  LevelModel? currentLevel;

  GameBloc(this.gameController)
      : super(GameState(
          grid: [],
          levelNumber: 1,
          secondsRemaining: 120,
          matchStatus: MatchStatus.idle)) {
    on<InitializeLevel>(_onInitializeLevel);
    on<CellTapped>(_onCellTapped);
    on<AddRow>(_onAddRow);
    on<TimerTicked>(_onTimerTicked);
  }

  void _onInitializeLevel(InitializeLevel event, Emitter<GameState> emit) {
    currentLevel = gameController.getLevel(event.levelNumber);
    List<List<CellModel>> initialGrid = gameController.generateGridForLevel(currentLevel!);
    emit(GameState(
      grid: initialGrid,
      levelNumber: event.levelNumber,
      secondsRemaining: currentLevel!.timeLimit.inSeconds,
      matchStatus: MatchStatus.idle,
      firstSelectedCell: null,
      completed: false,
    ));
  }

  void _onCellTapped(CellTapped event, Emitter<GameState> emit) async {
    if (event.cell.state == CellState.faded || event.cell.state == CellState.wrong) return;
    if (state.firstSelectedCell == null) {
      var newGrid = state.grid
          .map((row) => row
              .map((cell) => cell.id == event.cell.id
                  ? cell.copyWith(state: CellState.selected)
                  : cell.state == CellState.selected
                      ? cell.copyWith(state: CellState.normal)
                      : cell)
              .toList())
          .toList();
      emit(state.copyWith(
          firstSelectedCell: event.cell.copyWith(state: CellState.selected),
          grid: newGrid,
          matchStatus: MatchStatus.matching,
      ));
    } else {
      final isMatch = gameController.isMatch(state.firstSelectedCell!, event.cell, currentLevel!);
      var newGrid = state.grid.map((row) => row.map((cell) {
        if (cell.id == state.firstSelectedCell!.id ||
            cell.id == event.cell.id) {
          if (isMatch) return cell.copyWith(state: CellState.faded);
          else return cell.copyWith(state: CellState.wrong);
        } else {
          return cell.state == CellState.selected
              ? cell.copyWith(state: CellState.normal)
              : cell.state == CellState.wrong
                  ? cell.copyWith(state: CellState.normal)
                  : cell;
        }
      }).toList()).toList();

      final totalCells = newGrid.fold(0, (sum, row) => sum + row.length);
      final fadedCells = newGrid.fold(0, (sum, row) => sum + row.where((cell) => cell.state == CellState.faded).length);
      final justCompleted = isMatch && fadedCells == totalCells;
      emit(state.copyWith(
        grid: newGrid,
        matchStatus: isMatch ? MatchStatus.valid : MatchStatus.invalid,
        firstSelectedCell: null,
        completed: justCompleted,
      ));

      if (!isMatch) {
        await Future.delayed(Duration(milliseconds: 500));
        var resetGrid = newGrid.map((row) => row.map((cell) =>
          cell.state == CellState.wrong ? cell.copyWith(state: CellState.normal) : cell
        ).toList()).toList();
        emit(state.copyWith(grid: resetGrid, matchStatus: MatchStatus.idle));
      }
    }
  }

  void _onAddRow(AddRow event, Emitter<GameState> emit) {
    if (currentLevel!.levelNumber == 1) {
      final updatedGrid = gameController.addRowLevel1(state.grid, currentLevel!.maxColumns);
      emit(state.copyWith(grid: updatedGrid));
    } else if (currentLevel!.levelNumber == 2) {
      final updatedGrid = gameController.addRowLevel2(state.grid, currentLevel!.maxColumns);
      emit(state.copyWith(grid: updatedGrid));
    } else if (currentLevel!.levelNumber == 3) {
      final updatedGrid = gameController.addRowLevel3(state.grid, currentLevel!.maxColumns);
      emit(state.copyWith(grid: updatedGrid));
    } else {
      final updatedGrid = gameController.addRow(state.grid, currentLevel!);
      emit(state.copyWith(grid: updatedGrid));
    }
  }

  void _onTimerTicked(TimerTicked event, Emitter<GameState> emit) {
    int remaining = event.secondsRemaining;
    if (remaining <= 0) {
      emit(state.copyWith(matchStatus: MatchStatus.timeUp));
    } else {
      emit(state.copyWith(secondsRemaining: remaining));
    }
  }
}
