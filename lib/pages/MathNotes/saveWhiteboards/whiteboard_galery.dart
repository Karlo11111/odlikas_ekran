// whiteboard_gallery.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_ekran/pages/MathNotes/math_notes.dart';
import 'whiteboard_data.dart';

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

  // funkcija za kreiranje nove bilješke
  void _createNewNote(BuildContext context) async {
    final newNote = WhiteboardData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: "Nova bilješka ${DateTime.now().day}.${DateTime.now().month}",
      lastModified: DateTime.now(),
      paths: [],
      transformationMatrix: Matrix4.identity().storage.toList(),
      currentScale: 1.0,
      textElements: [],
    );

    // varijabla za spremanje nove bilješke
    final box = Hive.box<WhiteboardData>('whiteboards');
    final key = await box.add(newNote);
    final savedNote = box.get(key);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MathNotes(whiteboardData: savedNote!),
      ),
    );
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
                    padding: const EdgeInsets.only(top: 50),
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
                          width: MediaQuery.of(context).size.width * 0.3,
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "Znanstvene bilješke",
                              style: GoogleFonts.inter(
                                  fontSize: 36, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(left: 60, top: 30),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 40,
                      mainAxisSpacing: 40,
                      childAspectRatio: 1.2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // prvi container je za addanje novih bilješki
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 1.5,
                                child: GestureDetector(
                                  onTap: () => _createNewNote(context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 43,
                                        height: 43,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2196F3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // tekst ispod kontejnera
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  "Dodaj novu bilješku",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

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

// klasa za prikazivanje ostalih bilješke
class _WhiteboardCard extends StatelessWidget {
  final WhiteboardData whiteboard;
  final int index;

  const _WhiteboardCard({required this.whiteboard, required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: GestureDetector(
            onTap: () => _openWhiteboard(context),
            onLongPress: () => _showContextMenu(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // prikazivanje slike (preview) whiteboarda
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: whiteboard.screenshot != null
                    ? Image.memory(
                        whiteboard.screenshot!,
                        fit: BoxFit.cover,
                      )
                    : const Center(child: Text("No Preview")),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // ime whiteboarda
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            whiteboard.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // funkcija za otvaranje whiteboarda
  void _openWhiteboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MathNotes(whiteboardData: whiteboard),
      ),
    );
  }

  // funkcija za prikazivanje kontekstnog menija za brisanje
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

  // funkcija za prikazivanje dijaloga za preimenovanje
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

  // funkcija za brisanje whiteboarda
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
