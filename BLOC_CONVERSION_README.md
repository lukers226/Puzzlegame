# NumberGridPage BLoC Conversion

This document describes the conversion of the `NumberGridPage` from a `StatefulWidget` to a BLoC (Business Logic Component) pattern.

## Overview

The original `NumberGridPage` was a complex `StatefulWidget` with all game logic embedded within the widget. It has been converted to use the BLoC pattern for better separation of concerns, testability, and maintainability.

## File Structure

### BLoC Files
- `lib/blocs/numbergrid/numbergrid_event.dart` - Defines all events that can be dispatched to the BLoC
- `lib/blocs/numbergrid/numbergrid_state.dart` - Defines the state classes and data structures
- `lib/blocs/numbergrid/numbergrid_bloc.dart` - Contains all the business logic and event handlers

### UI Files
- `lib/screens/numbergridpage.dart` - Converted to use `BlocBuilder` and `BlocListener`

## Key Changes

### 1. Event-Driven Architecture
All user interactions and game logic are now handled through events:

```dart
// Example events
SelectCell(row, col)
AddRowsToBottom()
UpdateScore(scoreToAdd)
PlayAudio(audioPath)
CheckRowBonus()
CheckStageClear()
```

### 2. State Management
The game state is now managed centrally in the BLoC:

```dart
class NumberGridLoaded extends NumberGridState {
  final List<List<CellData>> grid;
  final int filledRows;
  final int score;
  final int addRowCredits;
  final int bulbCredits;
  // ... other state properties
}
```

### 3. Business Logic Separation
All game logic has been moved from the UI to the BLoC:

- Grid generation algorithms
- Cell matching logic
- Score calculation
- Audio playback
- Animation state management
- Row bonus checking
- Stage clear detection

### 4. UI Simplification
The UI is now purely presentational:

```dart
class NumberGridPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NumberGridBloc()..add(StartGame()),
      child: NumberGridView(),
    );
  }
}
```

## Usage

### Basic Usage
```dart
// The BLoC is automatically created and started when the page loads
BlocProvider(
  create: (context) => NumberGridBloc()..add(StartGame()),
  child: NumberGridView(),
)
```

### Dispatching Events
```dart
// From the UI
context.read<NumberGridBloc>().add(SelectCell(row, col));
context.read<NumberGridBloc>().add(AddRowsToBottom());
context.read<NumberGridBloc>().add(UpdateScore(10));
```

### Listening to State Changes
```dart
BlocBuilder<NumberGridBloc, NumberGridState>(
  builder: (context, state) {
    if (state is NumberGridLoaded) {
      return Text('Score: ${state.score}');
    }
    return CircularProgressIndicator();
  },
)
```

## Benefits of BLoC Conversion

### 1. Testability
- Business logic can be tested independently of the UI
- Events and states can be easily mocked
- Unit tests can verify game behavior without UI dependencies

### 2. Maintainability
- Clear separation between UI and business logic
- Easier to modify game rules without touching UI code
- Better code organization and readability

### 3. Reusability
- BLoC can be reused in different UI implementations
- Game logic can be shared across different screens
- Easier to implement features like game replay or AI opponents

### 4. State Management
- Predictable state updates
- Immutable state objects
- Easy to track state changes for debugging

## Testing

A test file has been created at `test/numbergrid_bloc_test.dart` that demonstrates how to test the BLoC:

```dart
test('emits updated score when UpdateScore is added', () async {
  numberGridBloc.add(StartGame());
  await emitUntil(numberGridBloc, (state) => state is NumberGridLoaded);
  
  final initialState = numberGridBloc.state as NumberGridLoaded;
  numberGridBloc.add(UpdateScore(10));
  
  await emitUntil(numberGridBloc, (state) => 
    state is NumberGridLoaded && (state as NumberGridLoaded).score > initialState.score);
});
```

## Migration Notes

### Preserved Functionality
- All original game features are preserved
- Audio playback works the same way
- Animations and visual effects remain unchanged
- Game mechanics and scoring are identical

### Improvements
- Better error handling
- More predictable state updates
- Easier to add new features
- Better performance through optimized rebuilds

### Dependencies
The conversion uses existing dependencies:
- `flutter_bloc: ^8.1.4`
- `bloc: ^8.1.4`
- `equatable: ^2.0.7`

## Future Enhancements

With the BLoC structure in place, it's now easier to add features like:

1. **Game Persistence** - Save/load game state
2. **Multiplayer Support** - Share game state across devices
3. **Analytics** - Track game events and player behavior
4. **AI Opponents** - Implement computer players
5. **Game Replay** - Record and replay games
6. **Achievements** - Track player accomplishments

## Conclusion

The BLoC conversion provides a solid foundation for future development while maintaining all existing functionality. The code is now more maintainable, testable, and extensible.
