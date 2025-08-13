import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ScoreState extends Equatable {
  final int score;
  final int allTimeScore;

  const ScoreState({required this.score, required this.allTimeScore});
  @override
  List<Object> get props => [score, allTimeScore];
}

abstract class ScoreEvent {}

class UpdateScore extends ScoreEvent {
  final int score;
  UpdateScore(this.score);
}

class ScoreBloc extends Bloc<ScoreEvent, ScoreState> {
  ScoreBloc() : super(const ScoreState(score: 0, allTimeScore: 256));

  @override
  Stream<ScoreState> mapEventToState(ScoreEvent event) async* {
    if (event is UpdateScore) {
      yield ScoreState(score: event.score, allTimeScore: state.allTimeScore);
    }
  }
}
