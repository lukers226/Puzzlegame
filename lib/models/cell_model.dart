import 'package:equatable/equatable.dart';

enum CellState { normal, faded, selected, wrong, highlighted }

class CellModel extends Equatable {
  final int id;
  final int number;
  final CellState state;

  const CellModel({
    required this.id,
    required this.number,
    this.state = CellState.normal,
  });

  static CellModel empty() {
    return CellModel(id: -1, number: 0, state: CellState.normal);
  }

  CellModel copyWith({
    int? id,
    int? number,
    CellState? state,
  }) {
    return CellModel(
      id: id ?? this.id,
      number: number ?? this.number,
      state: state ?? this.state,
    );
  }

  @override
  List<Object?> get props => [id, number, state];
}
