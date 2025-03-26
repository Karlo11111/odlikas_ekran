// class to track actions for undo/redo
enum ActionType {
  addPath,
  addShape,
  addText,
  deletePath,
  deleteShape,
  deleteText
}

class UndoableAction {
  final ActionType type;
  final dynamic item;
  final int index; // For delete operations, store the original index
  final DateTime timestamp;

  UndoableAction({
    required this.type,
    required this.item,
    this.index = -1,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
