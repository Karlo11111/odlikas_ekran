import 'dart:typed_data';
import 'package:hive/hive.dart';

// Register this adapter in your initHive method above after the WhiteboardDataAdapter
// Add: Hive.registerAdapter(Uint8ListAdapter());
class Uint8ListAdapter extends TypeAdapter<Uint8List> {
  @override
  final int typeId = 200; // Use a typeId that won't conflict with others

  @override
  Uint8List read(BinaryReader reader) {
    final length = reader.readInt();
    return reader.readByteList(length);
  }

  @override
  void write(BinaryWriter writer, Uint8List obj) {
    writer.writeInt(obj.length);
    writer.writeByteList(obj);
  }
}
