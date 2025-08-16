import 'package:flutter/material.dart';
import '../models/cell_model.dart';

class GridCellWidget extends StatelessWidget {
  final CellModel cell;
  final VoidCallback onTap;

  const GridCellWidget({Key? key, required this.cell, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color cellColor;
    switch (cell.state) {
      case CellState.faded:
        cellColor = Colors.grey.shade400;
        break;
      case CellState.selected:
        cellColor = Colors.greenAccent.shade200;
        break;
      case CellState.wrong:
        cellColor = Colors.redAccent.shade200;
        break;
      case CellState.highlighted:
        cellColor = Colors.yellow.shade300;
        break;
      default:
        cellColor = Colors.blue.shade200;
    }

    return GestureDetector(
      onTap: cell.state == CellState.faded ? null : onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26),
        ),
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Text(
          cell.number.toString(),
          style: TextStyle(
            fontSize: 20,
            color: cell.state == CellState.faded ? Colors.black38 : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
