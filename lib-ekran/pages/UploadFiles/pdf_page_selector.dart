// lib/pages/UploadFiles/pdf_page_selector.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf_render/pdf_render.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:image/image.dart' as imglib;

class PdfPageSelector extends StatefulWidget {
  final String pdfUrl;
  final String fileName;
  final Function(List<String> imageUrls) onPagesSelected;
  final int maxPages;

  const PdfPageSelector({
    Key? key,
    required this.pdfUrl,
    required this.fileName,
    required this.onPagesSelected,
    this.maxPages = 5,
  }) : super(key: key);

  @override
  State<PdfPageSelector> createState() => _PdfPageSelectorState();
}

class _PdfPageSelectorState extends State<PdfPageSelector> {
  bool _isLoading = true;
  late PdfDocument _pdfDocument;
  int _pageCount = 0;
  final List<int> _selectedPages = [];
  final List<String> _convertedImageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfDocument.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      // Download the PDF file
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to load PDF');
      }

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${widget.fileName}';
      final file = File(tempPath);
      await file.writeAsBytes(response.bodyBytes);

      // Open the PDF document
      _pdfDocument = await PdfDocument.openFile(tempPath);

      setState(() {
        _pageCount = _pdfDocument.pageCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog('Could not load PDF file. Please try again.');
      });
    }
  }

  void _togglePageSelection(int pageIndex) {
    setState(() {
      if (_selectedPages.contains(pageIndex)) {
        _selectedPages.remove(pageIndex);
      } else {
        if (_selectedPages.length < widget.maxPages) {
          _selectedPages.add(pageIndex);
        } else {
          // Show limit reached message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum ${widget.maxPages} pages can be selected',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  // Fixed _convertSelectedPagesToImages() function in pdf_page_selector.dart
  Future<void> _convertSelectedPagesToImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _convertedImageUrls.clear();
      final tempDir = await getTemporaryDirectory();

      for (final pageIndex in _selectedPages) {
        // Render the page to an image with higher resolution
        final page = await _pdfDocument.getPage(pageIndex + 1);

        // Use higher resolution for better quality - multiply by 2 for retina-quality
        final width = (page.width * 2).toInt();
        final height = (page.height * 2).toInt();

        final pageImage = await page.render(
          width: width,
          height: height,
        );

        // Get the image file path
        final imagePath =
            '${tempDir.path}/pdf_page_${widget.fileName.replaceAll(' ', '_')}_$pageIndex.png';
        final imageFile = File(imagePath);

        // Convert to PNG bytes - in 1.4.7 pixels is a Uint8List of RGBA values
        final bytes = pageImage.pixels;

        // Create a properly encoded PNG from the RGBA pixel data
        final imglib.Image image = imglib.Image.fromBytes(
          width: pageImage.width,
          height: pageImage.height,
          bytes: bytes.buffer,
          numChannels: 4, // RGBA
        );

        // Use the image package to encode as PNG
        final pngBytes = imglib.encodePng(image);

        // Write the PNG data to file
        await imageFile.writeAsBytes(pngBytes);

        // Add the file path as a URL (using file:// protocol)
        _convertedImageUrls.add('file://$imagePath');
      }

      // Pass converted images back
      widget.onPagesSelected(_convertedImageUrls);

      // Return to previous screen
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Pop the PDF selector

        // This is the key change - we're ensuring we get back to the MathNotes screen
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Pop the UploadFilesPage too
        }
      }
    } catch (e) {
      debugPrint('Error converting PDF pages: $e');
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog(
          'Failed to convert PDF pages to images. Please try again. Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 40,
          color: const Color.fromRGBO(236, 145, 32, 1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Odaberi stranice PDF-a",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Selection progress indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "Odabrano: ${_selectedPages.length}/${widget.maxPages} stranica",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "Preostalo: ${widget.maxPages - _selectedPages.length}",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _selectedPages.length / widget.maxPages,
                        backgroundColor: Colors.grey[200],
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 10,
                      ),
                    ],
                  ),
                ),

                // PDF page grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _pageCount,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedPages.contains(index);

                        return GestureDetector(
                          onTap: () => _togglePageSelection(index),
                          child: Column(
                            children: [
                              // Page number indicator above the preview
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected ? Colors.blue : Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Stranica ${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // PDF page preview with selection indicator
                              Expanded(
                                child: Stack(
                                  children: [
                                    // PDF page preview
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.grey[300]!,
                                          width: isSelected ? 3 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: PdfPageView(
                                        pdfDocument: _pdfDocument,
                                        pageNumber: index + 1,
                                      ),
                                    ),

                                    // Selection indicator
                                    if (isSelected)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed:
                _selectedPages.isEmpty ? null : _convertSelectedPagesToImages,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Uvezi ${_selectedPages.length} odabrane stranice",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
