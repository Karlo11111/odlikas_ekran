// whiteboard_gallery.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_ekran/pages/MathNotes/math_notes.dart';
import 'whiteboard_data.dart';
import 'package:intl/intl.dart';

class WhiteboardGalleryPage extends StatefulWidget {
  const WhiteboardGalleryPage({super.key});

  @override
  State<WhiteboardGalleryPage> createState() => _WhiteboardGalleryPageState();
}

class _WhiteboardGalleryPageState extends State<WhiteboardGalleryPage> {
  late Box<WhiteboardData> whiteboardsBox;

  @override
  void initState() {
    super.initState();
    whiteboardsBox = Hive.box<WhiteboardData>('whiteboards');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: ValueListenableBuilder(
          valueListenable: Hive.box<WhiteboardData>('whiteboards').listenable(),
          builder: (context, Box<WhiteboardData> box, _) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: Row(
                      children: [
                        // RETURN BUTTON
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.035,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          iconSize: 50,
                          color: const Color.fromRGBO(236, 145, 32, 1),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.27,
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "Matematičke bilješke",
                              style: GoogleFonts.inter(
                                  fontSize: 36, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) return _AddNewWhiteboardCard();
                        final whiteboard = box.getAt(index - 1);
                        return _WhiteboardCard(
                          whiteboard: whiteboard!,
                          index: index - 1,
                        );
                      },
                      childCount: box.length + 1,
                    ),
                  ),
                ),
              ],
            );
          },
        ));
  }
}

class _AddNewWhiteboardCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _createNewWhiteboard(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              "Dodaj novu bilješku",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewWhiteboard(BuildContext context) async {
    final newWhiteboard = WhiteboardData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: "Nova bilješka ${DateTime.now().day}.${DateTime.now().month}",
        lastModified: DateTime.now(),
        paths: [],
        transformationMatrix: Matrix4.identity().storage.toList(),
        currentScale: 1.0,
        textElements: []);

    final box = Hive.box<WhiteboardData>('whiteboards');
    await box.add(newWhiteboard);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MathNotes(whiteboardData: newWhiteboard),
      ),
    );
  }
}

class _WhiteboardCard extends StatelessWidget {
  final WhiteboardData whiteboard;
  final int index;

  const _WhiteboardCard({required this.whiteboard, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openWhiteboard(context),
      onLongPress: () => _showContextMenu(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  color: Colors.white,
                ),
                // ako je screenshot dostupan pokazi ga, inace prikazi text "No Preview"
                child: whiteboard.screenshot != null
                    ? Image.memory(
                        whiteboard.screenshot!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error_outline),
                      )
                    : const Center(child: Text("No Preview")),
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      whiteboard.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Zadnja promjena: ${DateFormat('dd.MM.yyyy HH:mm').format(whiteboard.lastModified)}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  void _openWhiteboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MathNotes(whiteboardData: whiteboard),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Preimenuj'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Obriši'),
              onTap: () {
                Navigator.pop(context);
                _deleteWhiteboard(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final textController = TextEditingController(text: whiteboard.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preimenuj bilješku'),
        content: TextField(controller: textController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () {
              whiteboard.name = textController.text;
              whiteboard.save();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ime promijenjeno')),
              );
            },
            child: const Text('Spremi'),
          ),
        ],
      ),
    );
  }

  void _deleteWhiteboard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši bilješku?'),
        content:
            const Text('Jeste li sigurni da želite obrisati ovu bilješku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () {
              final box = Hive.box<WhiteboardData>('whiteboards');
              box.deleteAt(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bilješka obrisana')),
              );
            },
            child: const Text('Obriši', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
