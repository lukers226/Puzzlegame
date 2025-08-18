import '../models/cell_model.dart';
import '../models/level_model.dart';
import 'dart:math';

class GameController {
  final List<LevelModel> levels = [
    LevelModel(
      levelNumber: 1,
      maxRows: 3,
      maxColumns: 9,
      timeLimit: Duration(minutes: 2),
      maxAddRows: 2,
      constraint: "Easy",
    ),
    LevelModel(
      levelNumber: 2,
      maxRows: 3,
      maxColumns: 9,
      timeLimit: Duration(minutes: 2),
      maxAddRows: 3,
      constraint: "Medium",
    ),
    LevelModel(
      levelNumber: 3,
      maxRows: 3,
      maxColumns: 9,
      timeLimit: Duration(minutes: 2),
      maxAddRows: 4,
      constraint: "Hard",
    ),
  ];

  int _level3AddRowCount = 0;

  LevelModel getLevel(int number) =>
      levels.firstWhere((l) => l.levelNumber == number);

  void resetLevelState(LevelModel level) {
    if (level.levelNumber == 3) {
      _level3AddRowCount = 0;
    }
  }

  // Helper method: initial row count per level
  int getInitialRows(LevelModel level) {
    if (level.levelNumber == 1) return 4; // Level 1 starts with 4 rows
    return level.maxRows; // Level 2 & 3 with maxRows (3)
  }

  bool canCompleteLevel(LevelModel level, List<List<CellModel>> currentGrid) {
    if (level.levelNumber == 3) {
      // Require at least 2 rows added before completion allowed
      if (_level3AddRowCount < 2) return false;

      // ✅ Ensure all pairs are solved (no matchable pairs remain)
      List<CellModel> activeCells = currentGrid
          .expand((row) => row)
          .where((c) => c.state != CellState.faded)
          .toList();

      for (int i = 0; i < activeCells.length; i++) {
        for (int j = i + 1; j < activeCells.length; j++) {
          if (isMatch(activeCells[i], activeCells[j], level)) {
            return false; // There’s still a matchable pair
          }
        }
      }
      return true; // No pairs remain AND 2 rows added
    }

    return true; // Other levels can complete anytime
  }

  List<List<CellModel>> generateGridForLevel(LevelModel level) {
    resetLevelState(level);
    if (level.levelNumber == 1) {
      return generateLevel1Grid(4, level.maxColumns);
    } else if (level.levelNumber == 2) {
      return generateLevel2Grid(level.maxRows, level.maxColumns);
    } else if (level.levelNumber == 3) {
      return generateLevel3Grid(level.maxRows, level.maxColumns);
    } else {
      return generateGrid(level.maxRows, level.maxColumns);
    }
  }

  List<int> pairedList(int pairCount) {
    final rnd = Random();
    List<int> pairs = [];
    for (int i = 0; i < pairCount; i++) {
      int a = rnd.nextInt(9) + 1;
      bool useEqual = rnd.nextBool();
      int b = useEqual ? a : (10 - a);
      if (b < 1 || b > 9) b = a;
      pairs.add(a);
      pairs.add(b);
    }
    return pairs;
  }

  List<List<CellModel>> generateLevel1Grid(int rows, int columns) {
    final rnd = Random();
    int totalCells = rows * columns;
    int pairCount = totalCells ~/ 2;

    List<int> pairs = [];
    for (int i = 0; i < pairCount; i++) {
      int a = rnd.nextInt(9) + 1;
      int b = rnd.nextBool() ? a : (10 - a);
      if (b < 1 || b > 9) b = a;
      pairs.add(a);
      pairs.add(b);
    }

    if (totalCells % 2 != 0) {
      int unmatchable = -1;
      Set<int> used = pairs.toSet();
      int tryCount = 0;
      while (tryCount < 50) {
        int candidate = rnd.nextInt(9) + 1;
        if (!pairs.contains(candidate) &&
            !pairs.contains(10 - candidate) &&
            (candidate * 2 != 10)) {
          unmatchable = candidate;
          break;
        }
        tryCount++;
      }
      if (unmatchable == -1) {
        for (var candidate = 1; candidate <= 9; candidate++) {
          if (!used.contains(candidate) ||
              (!used.contains(10 - candidate) && candidate * 2 != 10)) {
            unmatchable = candidate;
            break;
          }
        }
        if (unmatchable == -1) unmatchable = rnd.nextInt(9) + 1;
      }
      pairs.add(unmatchable);
    }

    pairs.shuffle();
    List<CellModel> cells = List.generate(
      totalCells,
      (i) => CellModel(id: i + 1, number: pairs[i], state: CellState.normal),
    );
    List<List<CellModel>> grid = [];
    for (int r = 0; r < rows; r++) {
      grid.add(cells.sublist(r * columns, (r + 1) * columns));
    }
    return grid;
  }

  List<List<CellModel>> addRowLevel1(List<List<CellModel>> grid, int columns) {
    final rnd = Random();
    int startId = grid.expand((row) => row).length + 1;

    List<CellModel> activeCells = grid
        .expand((row) => row)
        .where((c) => c.state != CellState.faded)
        .toList();
    Map<int, int> counts = {};
    for (var c in activeCells) counts[c.number] = (counts[c.number] ?? 0) + 1;

    List<int> unmatched = [];
    for (var c in activeCells) {
      int n = c.number;
      int pairSame = (counts[n] ?? 0);
      int pairTen = (counts[10 - n] ?? 0);
      if (!(pairSame > 1 || pairTen > 0) && !unmatched.contains(n)) {
        unmatched.add(n);
      }
    }

    List<int> rowNums = [];
    for (var n in unmatched) {
      int partner = (10 - n >= 1 && 10 - n <= 9) ? 10 - n : n;
      rowNums.add(partner);
    }

    List<int> fillPairs = [];
    int slotsLeft = columns - rowNums.length;
    for (int i = 0; i < slotsLeft ~/ 2; i++) {
      int a = rnd.nextInt(9) + 1;
      int b = rnd.nextBool() ? a : (10 - a);
      if (b < 1 || b > 9) b = a;
      fillPairs.add(a);
      fillPairs.add(b);
    }
    if (slotsLeft % 2 == 1) {
      fillPairs.add(rnd.nextInt(9) + 1);
    }
    rowNums.addAll(fillPairs);
    rowNums.shuffle();

    List<CellModel> newRow = List.generate(
      columns,
      (i) => CellModel(id: startId + i, number: rowNums[i], state: CellState.normal),
    );
    return [...grid, newRow];
  }

  List<List<CellModel>> generateLevel2Grid(int rows, int columns) {
    final rnd = Random();
    int totalCells = rows * columns;
    int pairCount = (totalCells - 3) ~/ 2;
    List<int> pairs = pairedList(pairCount);
    for (int i = 0; i < 3; i++) {
      pairs.add(rnd.nextInt(9) + 1);
    }
    pairs.shuffle();
    List<CellModel> cells = List.generate(
      totalCells,
      (i) => CellModel(id: i + 1, number: pairs[i], state: CellState.normal),
    );
    List<List<CellModel>> grid = [];
    for (int r = 0; r < rows; r++) {
      grid.add(cells.sublist(r * columns, (r + 1) * columns));
    }
    return grid;
  }

  List<List<CellModel>> generateLevel3Grid(int rows, int columns) {
    final rnd = Random();
    int totalCells = rows * columns;
    int oddCount = 5;
    int pairCount = (totalCells - oddCount) ~/ 2;
    List<int> pairs = pairedList(pairCount);
    for (int i = 0; i < oddCount; i++) {
      pairs.add(rnd.nextInt(9) + 1);
    }
    pairs.shuffle();
    List<CellModel> cells = List.generate(
      totalCells,
      (i) => CellModel(id: i + 1, number: pairs[i], state: CellState.normal),
    );
    List<List<CellModel>> grid = [];
    for (int r = 0; r < rows; r++) {
      grid.add(cells.sublist(r * columns, (r + 1) * columns));
    }
    return grid;
  }

  List<List<CellModel>> generateGrid(int rows, int columns) {
    final rnd = Random();
    int nextId = 1;
    List<List<CellModel>> grid = List.generate(rows, (r) => List.generate(columns, (c) {
          return CellModel(
            id: nextId++,
            number: rnd.nextInt(9) + 1,
            state: CellState.normal,
          );
        }));
    return grid;
  }

  List<List<CellModel>> addRowLevel2(List<List<CellModel>> grid, int columns) {
    final rnd = Random();
    int startId = grid.expand((row) => row).length + 1;
    List<CellModel> allCells =
        grid.expand((row) => row).where((c) => c.state != CellState.faded).toList();
    Map<int, int> counts = {};
    for (var c in allCells) counts[c.number] = (counts[c.number] ?? 0) + 1;
    List<int> odds = [];
    counts.forEach((n, v) {
      if (v % 2 != 0) odds.add(n);
    });
    List<int> newRowNums = [];
    for (var odd in odds) {
      int pairNum = rnd.nextBool() ? odd : (10 - odd);
      if (pairNum < 1 || pairNum > 9) pairNum = odd;
      newRowNums.add(pairNum);
    }
    int remain = columns - odds.length;
    List<int> rowPairs = pairedList(remain ~/ 2);
    if (remain % 2 == 1) rowPairs.add(rnd.nextInt(9) + 1);
    rowPairs.shuffle();
    newRowNums.addAll(rowPairs);
    List<CellModel> newRow = List.generate(
        columns,
        (i) => CellModel(id: startId + i, number: newRowNums[i], state: CellState.normal));
    return [...grid, newRow];
  }

  List<List<CellModel>> addRowLevel3(List<List<CellModel>> grid, int columns) {
    _level3AddRowCount++;
    final rnd = Random();
    int startId = grid.expand((row) => row).length + 1;
    List<CellModel> allCells =
        grid.expand((row) => row).where((c) => c.state != CellState.faded).toList();
    Map<int, int> counts = {};
    for (var c in allCells) counts[c.number] = (counts[c.number] ?? 0) + 1;
    List<int> odds = [];
    counts.forEach((n, v) {
      if (v % 2 != 0) odds.add(n);
    });

    List<int> newRowNums = [];
    int toPair = odds.length >= 3 ? 3 : odds.length;
    for (int i = 0; i < toPair; i++) {
      int odd = odds[i];
      bool useEqual = rnd.nextBool();
      int pairNum = useEqual ? odd : (10 - odd);
      if (pairNum < 1 || pairNum > 9) pairNum = odd;
      newRowNums.add(pairNum);
    }
    int remain = columns - toPair;
    List<int> rowPairs = pairedList(remain ~/ 2);
    if (remain % 2 == 1) rowPairs.add(rnd.nextInt(9) + 1);
    rowPairs.shuffle();
    newRowNums.addAll(rowPairs);

    while (newRowNums.length < columns) {
      newRowNums.add(rnd.nextInt(9) + 1);
    }

    List<CellModel> newRow = List.generate(
      columns,
      (i) => CellModel(id: startId + i, number: newRowNums[i], state: CellState.normal),
    );
    return [...grid, newRow];
  }

  List<List<CellModel>> addRow(List<List<CellModel>> grid, LevelModel level) {
    final columns = level.maxColumns;
    int startId = grid.expand((row) => row).length + 1;
    final rnd = Random();
    List<CellModel> newRow = List.generate(
      columns,
      (c) => CellModel(id: startId + c, number: rnd.nextInt(9) + 1, state: CellState.normal),
    );
    return [...grid, newRow];
  }

  bool isMatch(CellModel a, CellModel b, LevelModel level) {
    if (a.id == b.id) return false;
    return (a.number == b.number || a.number + b.number == 10);
  }
}
