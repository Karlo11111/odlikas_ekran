// lib/pages/UploadFiles/uploaded_files.dart

// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odlikas_ekran/pages/UploadFiles/pdf_page_selector.dart';

class UploadFilesPages extends StatefulWidget {
  final Function(String imageUrl)? onImageSelected;

  const UploadFilesPages({
    super.key,
    this.onImageSelected,
  });

  @override
  State<UploadFilesPages> createState() => _UploadFilesPagesState();
}

class _UploadFilesPagesState extends State<UploadFilesPages> {
  String? _email;
  String? _password;
  bool _isLoading = true;

  // Ovdje ćemo pohraniti popis datoteka (trenutno samo slike).
  // Svaka datoteka je map s ključevima poput: { 'name': '...', 'url': '...' }
  List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    // Nakon što se widget inicijalizira, dohvatit ćemo podatke o uceniku i datoteke.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCredentials();
    });
  }

  /// Pokušava dohvatiti email i password iz Hive boxa 'user_credentials'.
  /// Ako ih nema, onda ih dohvaća iz Firestore (CreatedScreens).
  Future<void> _initCredentials() async {
    final box = await Hive.openBox('user_credentials');
    final storedEmail = box.get('email') as String?;
    final storedPassword = box.get('password') as String?;

    if (storedEmail != null && storedPassword != null) {
      // Već imamo email i password lokalno, pa ih možemo koristiti
      setState(() {
        _email = storedEmail;
        _password = storedPassword;
      });
      // Dohvati popis datoteka
      await _fetchFiles(storedEmail, storedPassword);
    } else {
      // Nema ih u Hive-u, pokušaj dohvatiti iz Firestorea
      debugPrint('No credentials found in Hive. Fetching from Firebase...');
      await _fetchCredentialsFromFirebase();
    }
  }

  /// Dohvaća email i password iz kolekcije 'CreatedScreens' (korištenjem screenId iz SharedPreferences),
  /// sprema ih u Hive, te zatim dohvaća datoteke.
  Future<void> _fetchCredentialsFromFirebase() async {
    final prefs = await SharedPreferences.getInstance();
    final screenId = prefs.getString('screenId');

    if (screenId == null) {
      debugPrint('No screen ID found');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('CreatedScreens')
          .doc(screenId)
          .get();

      if (doc.exists) {
        final fetchedEmail = doc.get('linkedUser') as String?;
        final fetchedPassword = doc.get('password') as String?;

        if (fetchedEmail != null && fetchedPassword != null) {
          setState(() {
            _email = fetchedEmail;
            _password = fetchedPassword;
          });

          final box = await Hive.openBox('user_credentials');
          await box.put('email', fetchedEmail);
          await box.put('password', fetchedPassword);

          await _fetchFiles(fetchedEmail, fetchedPassword);
        }
      }
    } catch (e) {
      debugPrint('Error fetching credentials: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Dohvaća datoteke iz Firestore kolekcije 'odlikasFiles' (ID = email) i sprema ih u _files.
  Future<void> _fetchFiles(String email, String password) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('odlikasFiles')
          .doc(email)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['files'] != null) {
          final filesData = data['files'] as List;
          setState(() {
            _files =
                filesData.map((file) => file as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching files: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleImageSelection(String fileUrl) {
    if (widget.onImageSelected != null) {
      widget.onImageSelected!(fileUrl);
      Navigator.of(context).pop();
    }
  }

  void _handlePdfSelection(String fileUrl, String fileName) {
    if (widget.onImageSelected == null) {
      return; // If no handler is provided, just return
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPageSelector(
          pdfUrl: fileUrl,
          fileName: fileName,
          onPagesSelected: (List<String> imageUrls) {
            // Handle each converted image URL
            for (final imageUrl in imageUrls) {
              widget.onImageSelected!(imageUrl);
            }
            // No need to call Navigator.pop() here as the selector will handle it
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1) Gornji dio (naslov i strelica za povratak)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.035),
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 50,
                    color: const Color.fromRGBO(236, 145, 32, 1),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.296),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Moji dokumenti",
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2) Glavni sadržaj ovisno o stanju (učitavanje / nema datoteka / ima datoteka)
          if (_isLoading)
            // Ako se još učitava, prikaži indikator
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_files.isEmpty)
            // Ako nema datoteka, prikaži poruku
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  "Trenutno nemate prenesenu datoteku.\nMolimo vas da kroz mobilnu aplikaciju Odlikaš dodate datoteku prije nastavka.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            // Ako ima datoteka, prikaži ih u gridu (za sada samo slike)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // četiri stupca
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final file = _files[index];
                    final fileName = file['name'] ?? 'N/A';
                    final fileUrl = file['url'] ?? '';

                    // Check if it's an image or PDF
                    final bool isImage = _isImageFile(fileName);
                    final bool isPdf = _isPdfFile(fileName);

                    return InkWell(
                      onTap: () {
                        if (isImage) {
                          _handleImageSelection(fileUrl);
                        } else if (isPdf) {
                          _handlePdfSelection(fileUrl, fileName);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Image or PDF icon
                          Container(
                            width: 200,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: isImage
                                ? Image.network(
                                    fileUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                : isPdf
                                    ? const Center(
                                        child: Icon(
                                          Icons.picture_as_pdf,
                                          size: 40,
                                          color: Colors.red,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.insert_drive_file,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fileName,
                            style: GoogleFonts.inter(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _files.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isImageFile(String fileName) {
    final lowerCaseName = fileName.toLowerCase();
    return lowerCaseName.endsWith('.jpg') ||
        lowerCaseName.endsWith('.jpeg') ||
        lowerCaseName.endsWith('.png') ||
        lowerCaseName.endsWith('.gif') ||
        lowerCaseName.endsWith('.webp');
  }

  bool _isPdfFile(String fileName) {
    final lowerCaseName = fileName.toLowerCase();
    return lowerCaseName.endsWith('.pdf');
  }
}
