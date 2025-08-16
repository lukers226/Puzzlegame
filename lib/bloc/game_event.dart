import 'package:equatable/equatable.dart';
import '../models/cell_model.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();
}

class InitializeLevel extends GameEvent {
  final int levelNumber;
  const InitializeLevel(this.levelNumber);

  @override
  List<Object?> get props => [levelNumber];
}

class CellTapped extends GameEvent {
  final CellModel cell;
  const CellTapped(this.cell);

  @override
  List<Object?> get props => [cell];
}

class AddRow extends GameEvent {
  const AddRow();

  @override
  List<Object?> get props => [];
}

class TimerTicked extends GameEvent {
  final int secondsRemaining;
  const TimerTicked(this.secondsRemaining);

  @override
  List<Object?> get props => [secondsRemaining];
}
