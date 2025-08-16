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
        constraint: "Easy"
    ),
    LevelModel(
        levelNumber: 2,
        maxRows: 3,
        maxColumns: 9,
        timeLimit: Duration(minutes: 2),
        maxAddRows: 3,
        constraint: "Medium"
    ),
    LevelModel(
        levelNumber: 3,
        maxRows: 3,
        maxColumns: 9,
        timeLimit: Duration(minutes: 2),
        maxAddRows: 4,
        constraint: "Hard"
    ),
  ];

  int _level3AddRowCount = 0;

  LevelModel getLevel(int number) => levels.firstWhere((l) => l.levelNumber == number);

  void resetLevelState(LevelModel level) {
    if (level.levelNumber == 3) {
      _level3AddRowCount = 0;
    }
  }

  List<List<CellModel>> generateGridForLevel(LevelModel level) {
    resetLevelState(level);
    if (level.levelNumber == 1) {
      return generateLevel1Grid(level.maxRows, level.maxColumns);
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

  // --- Level 1 Special Logic ---
  List<List<CellModel>> generateLevel1Grid(int rows, int columns) {
    final rnd = Random();
    int totalCells = rows * columns;
    int pairCount = (totalCells - 1) ~/ 2;

    List<int> pairs = [];
    for (int i = 0; i < pairCount; i++) {
      int a = rnd.nextInt(9) + 1;
      int b = rnd.nextBool() ? a : (10 - a);
      if (b < 1 || b > 9) b = a;
      pairs.add(a);
      pairs.add(b);
    }

    // Try to find a truly unmatchable number, but fallback if not possible
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
      // fallback: pick a number not overused
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

    pairs.shuffle();
    List<CellModel> cells = List.generate(totalCells, (i) => CellModel(id: i + 1, number: pairs[i], state: CellState.normal));
    List<List<CellModel>> grid = [];
    for (int r = 0; r < rows; r++) grid.add(cells.sublist(r * columns, (r + 1) * columns));
    return grid;
  }

  // --- Level 1 Add Row: Ensure every unmatched number gets a pair, filling row as needed ---
  List<List<CellModel>> addRowLevel1(List<List<CellModel>> grid, int columns) {
    final rnd = Random();
    int startId = grid.expand((row) => row).length + 1;

    // 1. Find all numbers that don't have a live pair
    List<CellModel> activeCells = grid.expand((row) => row).where((c) => c.state != CellState.faded).toList();
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

    // 2. Provide a pair for every unmatched number
    List<int> rowNums = [];
    for (var n in unmatched) {
      int partner = (10 - n >= 1 && 10 - n <= 9) ? 10 - n : n;
      rowNums.add(partner);
    }

    // 3. Fill out the row with full random pairs (all internal, so no new unmatched)
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
      fillPairs.add(rnd.nextInt(9) + 1); // singleton/fallback
    }
    rowNums.addAll(fillPairs);
    rowNums.shuffle();

    List<CellModel> newRow = List.generate(
      columns,
      (i) => CellModel(id: startId + i, number: rowNums[i], state: CellState.normal)
    );
    return [...grid, newRow];
  }

  // --- Level 2 & 3 and generic remain unchanged ---
  List<List<CellModel>> generateLevel2Grid(int rows, int columns) {
    final rnd = Random();
    int totalCells = rows * columns;
    int pairCount = (totalCells - 3) ~/ 2;
    List<int> pairs = pairedList(pairCount);
    for (int i = 0; i < 3; i++) {
      pairs.add(rnd.nextInt(9) + 1);
    }
    pairs.shuffle();
    List<CellModel> cells = List.generate(totalCells, (i) => CellModel(id: i + 1, number: pairs[i], state: CellState.normal));
    List<List<CellModel>> grid = [];
    for (int r = 0; r < rows; r++) grid.add(cells.sublist(r * columns, (r + 1) * columns));
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
    List<CellModel> cells = List.generate(totalCells, (i) => CellModel(id: i + 1, number: pairs[i], state: CellState.normal));
    List<List<CellModel>> grid = [];
    for (int r = 0; r < rows; r++) grid.add(cells.sublist(r * columns, (r + 1) * columns));
    return grid;
  }

  List<List<CellModel>> generateGrid(int rows, int columns) {
    final rnd = Random();
    int nextId = 1;
    List<List<CellModel>> grid = List.generate(rows, (r) =>
      List.generate(columns, (c) => CellModel(
        id: nextId++,
        number: rnd.nextInt(9) + 1,
        state: CellState.normal,
      )));
    return grid;
  }

  List<List<CellModel>> addRowLevel2(List<List<CellModel>> grid, int columns) {
    final rnd = Random();
    int startId = grid.expand((row) => row).length + 1;
    List<CellModel> allCells = grid.expand((row) => row).where((c) => c.state != CellState.faded).toList();
    Map<int, int> counts = {};
    for (var c in allCells) counts[c.number] = (counts[c.number] ?? 0) + 1;
    List<int> odds = [];
    counts.forEach((n, v) { if (v % 2 != 0) odds.add(n); });
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
      (i) => CellModel(id: startId + i, number: newRowNums[i], state: CellState.normal)
    );
    return [...grid, newRow];
  }

  List<List<CellModel>> addRowLevel3(List<List<CellModel>> grid, int columns) {
    final rnd = Random();
    _level3AddRowCount++;
    int startId = grid.expand((row) => row).length + 1;
    List<CellModel> allCells = grid.expand((row) => row).where((c) => c.state != CellState.faded).toList();
    Map<int, int> counts = {};
    for (var c in allCells) counts[c.number] = (counts[c.number] ?? 0) + 1;
    List<int> odds = [];
    counts.forEach((n, v) { if (v % 2 != 0) odds.add(n); });

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
      (i) => CellModel(id: startId + i, number: newRowNums[i], state: CellState.normal)
    );
    return [...grid, newRow];
  }

  List<List<CellModel>> addRow(List<List<CellModel>> grid, LevelModel level) {
    final columns = level.maxColumns;
    int startId = grid.expand((row) => row).length + 1;
    final rnd = Random();
    List<CellModel> newRow = List.generate(
      columns,
      (c) => CellModel(id: startId + c, number: rnd.nextInt(9) + 1, state: CellState.normal)
    );
    return [...grid, newRow];
  }

  bool isMatch(CellModel a, CellModel b, LevelModel level) {
    if (a.id == b.id) return false;
    return (a.number == b.number || a.number + b.number == 10);
  }
}
