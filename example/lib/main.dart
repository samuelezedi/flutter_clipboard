import 'dart:typed_data';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:io' show Platform;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Clipboard Enhanced',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController textController = TextEditingController();
  TextEditingController htmlController = TextEditingController();
  String pasteValue = '';
  String clipboardStatus = 'Ready';
  bool isMonitoring = false;
  Map<String, dynamic> debugInfo = {'info': 'Tap "Load Debug Info" to fetch'};
  List<String> clipboardHistory = [];
  Uint8List? selectedImageBytes;
  Uint8List? pastedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _setupClipboardListener();
  }

  @override
  void dispose() {
    FlutterClipboard.stopMonitoring();
    FlutterClipboard.removeListener(_onClipboardChanged);
    super.dispose();
  }

  void _setupClipboardListener() {
    FlutterClipboard.addListener(_onClipboardChanged);
  }

  void _onClipboardChanged(EnhancedClipboardData data) {
    setState(() {
      if (data.hasText) {
        clipboardHistory.insert(
            0, '${data.text} (${DateTime.now().toString().substring(11, 19)})');
        if (clipboardHistory.length > 10) {
          clipboardHistory.removeLast();
        }
      } else if (data.hasImage) {
        clipboardHistory.insert(0,
            'Image (${data.imageBytes?.length ?? 0} bytes) - ${DateTime.now().toString().substring(11, 19)}');
        if (clipboardHistory.length > 10) {
          clipboardHistory.removeLast();
        }
      }
    });
  }

  Future<void> _loadDebugInfo() async {
    final info = await FlutterClipboard.getDebugInfo();
    setState(() {
      debugInfo = info;
    });
  }

  Future<void> _copyText() async {
    if (textController.text.trim().isEmpty) {
      _showSnackBar('Please enter text to copy');
      return;
    }

    try {
      await FlutterClipboard.copy(textController.text);
      setState(() {
        clipboardStatus = 'Text copied successfully!';
      });
      _showSnackBar('Text copied to clipboard');
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Copy failed: $e';
      });
      _showSnackBar('Copy failed: $e');
    }
  }

  Future<void> _copyRichText() async {
    if (textController.text.trim().isEmpty &&
        htmlController.text.trim().isEmpty) {
      _showSnackBar('Please enter text or HTML to copy');
      return;
    }

    try {
      await FlutterClipboard.copyRichText(
        text: textController.text,
        html: htmlController.text.isNotEmpty ? htmlController.text : null,
      );
      setState(() {
        clipboardStatus = 'Rich text copied successfully!';
      });
      _showSnackBar('Rich text copied to clipboard');
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Rich text copy failed: $e';
      });
      _showSnackBar('Rich text copy failed: $e');
    }
  }

  Future<void> _copyWithCallback() async {
    if (textController.text.trim().isEmpty) {
      _showSnackBar('Please enter text to copy');
      return;
    }

    await FlutterClipboard.copyWithCallback(
      text: textController.text,
      onSuccess: () {
        setState(() {
          clipboardStatus = 'Copy successful with callback!';
        });
        _showSnackBar('Copy successful with callback');
        _loadDebugInfo();
      },
      onError: (error) {
        setState(() {
          clipboardStatus = 'Copy failed with callback: $error';
        });
        _showSnackBar('Copy failed with callback: $error');
      },
    );
  }

  Future<void> _pasteText() async {
    try {
      final text = await FlutterClipboard.paste();
      setState(() {
        pasteValue = text;
        clipboardStatus = 'Text pasted successfully!';
      });
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Paste failed: $e';
      });
      _showSnackBar('Paste failed: $e');
    }
  }

  Future<void> _pasteRichText() async {
    try {
      final data = await FlutterClipboard.pasteRichText();
      setState(() {
        pasteValue = 'Text: ${data.text ?? "N/A"}\nHTML: ${data.html ?? "N/A"}';
        clipboardStatus = 'Rich text pasted successfully!';
      });
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Rich text paste failed: $e';
      });
      _showSnackBar('Rich text paste failed: $e');
    }
  }

  Future<void> _checkClipboardStatus() async {
    try {
      final hasData = await FlutterClipboard.hasData();
      final isEmpty = await FlutterClipboard.isEmpty();
      final contentType = await FlutterClipboard.getContentType();
      final dataSize = await FlutterClipboard.getDataSize();

      setState(() {
        clipboardStatus =
            'Has data: $hasData, Empty: $isEmpty, Type: $contentType, Size: $dataSize';
      });
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Status check failed: $e';
      });
    }
  }

  Future<void> _clearClipboard() async {
    try {
      await FlutterClipboard.clear();
      setState(() {
        pasteValue = '';
        clipboardStatus = 'Clipboard cleared!';
      });
      _showSnackBar('Clipboard cleared');
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Clear failed: $e';
      });
      _showSnackBar('Clear failed: $e');
    }
  }

  void _toggleMonitoring() {
    if (isMonitoring) {
      FlutterClipboard.stopMonitoring();
      setState(() {
        isMonitoring = false;
        clipboardStatus = 'Monitoring stopped';
      });
    } else {
      FlutterClipboard.startMonitoring();
      setState(() {
        isMonitoring = true;
        clipboardStatus = 'Monitoring started';
      });
    }
    _loadDebugInfo();
  }

  Future<void> _pickImage() async {
    try {
      // On macOS, use file picker directly if image_picker doesn't work
      if (Platform.isMacOS) {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );
        if (image == null) {
          // User cancelled or no file selected
          return;
        }

        try {
          // Read the image file
          final bytes = await image.readAsBytes();

          // Convert HEIC/HEIF to PNG if needed
          Uint8List convertedBytes = bytes;
          try {
            // Try to decode and re-encode as PNG to handle HEIC format
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            final uiImage = frame.image;

            // Convert to PNG format
            final byteData =
                await uiImage.toByteData(format: ui.ImageByteFormat.png);
            if (byteData != null) {
              convertedBytes = byteData.buffer.asUint8List();
            }
            uiImage.dispose();
          } catch (e) {
            // If conversion fails, use original bytes (might already be PNG/JPEG)
            // This handles cases where the image is already in a compatible format
          }

          setState(() {
            selectedImageBytes = convertedBytes;
            clipboardStatus = 'Image selected (${convertedBytes.length} bytes)';
          });
          _showSnackBar('Image selected successfully');
        } catch (e) {
          _showSnackBar(
              'Failed to read image: $e\n\nTip: The image might be in an unsupported format. Try using JPEG or PNG images.');
        }
      } else {
        // iOS/Android implementation
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
          requestFullMetadata:
              true, // Need metadata to handle format conversion
        );
        if (image != null) {
          try {
            // Read the image file
            final bytes = await image.readAsBytes();

            // Convert HEIC/HEIF to PNG if needed
            Uint8List convertedBytes = bytes;
            try {
              // Try to decode and re-encode as PNG to handle HEIC format
              final codec = await ui.instantiateImageCodec(bytes);
              final frame = await codec.getNextFrame();
              final uiImage = frame.image;

              // Convert to PNG format
              final byteData =
                  await uiImage.toByteData(format: ui.ImageByteFormat.png);
              if (byteData != null) {
                convertedBytes = byteData.buffer.asUint8List();
              }
              uiImage.dispose();
            } catch (e) {
              // If conversion fails, use original bytes (might already be PNG/JPEG)
              // This handles cases where the image is already in a compatible format
            }

            setState(() {
              selectedImageBytes = convertedBytes;
              clipboardStatus =
                  'Image selected (${convertedBytes.length} bytes)';
            });
          } catch (e) {
            _showSnackBar(
                'Failed to read image: $e\n\nTip: The image might be in HEIC format. Try converting it to JPEG/PNG first.');
          }
        }
      }
    } on PlatformException catch (e) {
      String errorMsg = 'Failed to pick image: ${e.message ?? 'Unknown error'}';
      if (e.code == 'invalid_image' ||
          e.message?.contains('NSItemProviderErrorDomain') == true ||
          e.message?.contains('public.jpeg') == true ||
          e.message?.contains('public.heic') == true ||
          e.message?.contains('HEIC') == true ||
          e.message?.contains('Cannot load representation') == true) {
        errorMsg +=
            '\n\nTip: iPhone photos are often in HEIC format. The app will convert them automatically. If this error persists, try:\n1. Adding JPEG/PNG images to the simulator\n2. Using a real device\n3. Converting HEIC to JPEG in Photos app first';
      }
      _showSnackBar(errorMsg);
    } catch (e) {
      _showSnackBar(
          'Failed to pick image: $e\n\nTip: iPhone photos use HEIC format. The app will convert them automatically.');
    }
  }

  Future<void> _pickImageFromCamera() async {
    // Camera is not well supported on macOS desktop
    if (Platform.isMacOS) {
      _showSnackBar(
          'Camera is not available on macOS desktop.\n\nPlease use the Gallery button to select an image from your files.');
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (image != null) {
        try {
          final bytes = await image.readAsBytes();

          // Convert to PNG format (camera might capture in HEIC on some devices)
          Uint8List convertedBytes = bytes;
          try {
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            final uiImage = frame.image;
            final byteData =
                await uiImage.toByteData(format: ui.ImageByteFormat.png);
            if (byteData != null) {
              convertedBytes = byteData.buffer.asUint8List();
            }
            uiImage.dispose();
          } catch (e) {
            // Use original bytes if conversion fails
          }

          setState(() {
            selectedImageBytes = convertedBytes;
            clipboardStatus =
                'Image selected from camera (${convertedBytes.length} bytes)';
          });
        } catch (e) {
          _showSnackBar('Failed to read image: $e');
        }
      }
    } on PlatformException catch (e) {
      String errorMsg =
          'Failed to capture image: ${e.message ?? 'Unknown error'}';
      if (e.code == 'camera_access_denied') {
        errorMsg += '\n\nPlease grant camera permission in Settings.';
      } else if (e.code == 'camera_unavailable') {
        errorMsg +=
            '\n\nCamera is not available (simulator doesn\'t have a camera).';
      } else if (e.message?.contains('cameraDelegate') == true) {
        errorMsg +=
            '\n\nCamera functionality requires additional setup on this platform.';
      }
      _showSnackBar(errorMsg);
    } catch (e) {
      String errorMsg = 'Failed to capture image: $e';
      if (e.toString().contains('cameraDelegate')) {
        errorMsg +=
            '\n\nCamera functionality is not available on macOS desktop. Please use the Gallery button instead.';
      }
      _showSnackBar(errorMsg);
    }
  }

  Future<void> _copyImage() async {
    if (selectedImageBytes == null) {
      _showSnackBar('Please select an image first');
      return;
    }

    try {
      await FlutterClipboard.copyImage(selectedImageBytes!);
      setState(() {
        clipboardStatus =
            'Image copied successfully! (${selectedImageBytes!.length} bytes)';
      });
      _showSnackBar('Image copied to clipboard');
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Copy image failed: $e';
      });
      _showSnackBar('Copy image failed: $e');
    }
  }

  Future<void> _pasteImage() async {
    try {
      final imageBytes = await FlutterClipboard.pasteImage();
      setState(() {
        pastedImageBytes = imageBytes;
        if (imageBytes != null) {
          clipboardStatus =
              'Image pasted successfully! (${imageBytes.length} bytes)';
          pasteValue = 'Image: ${imageBytes.length} bytes';
        } else {
          clipboardStatus = 'No image in clipboard';
          pasteValue = 'No image found';
        }
      });
      if (imageBytes != null) {
        _showSnackBar('Image pasted from clipboard');
      } else {
        _showSnackBar(
            'No image in clipboard.\n\nTip: While text clipboard is shared with macOS, images are NOT. Copy an image within the simulator first (e.g., from Photos app or Safari).');
      }
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Paste image failed: $e';
      });
      _showSnackBar('Paste image failed: $e');
    }
  }

  Future<void> _pasteRichTextWithImage() async {
    try {
      final data = await FlutterClipboard.pasteRichText();
      setState(() {
        pastedImageBytes = data.imageBytes;
        if (data.hasText || data.hasHtml || data.hasImage) {
          final parts = <String>[];
          if (data.hasText) parts.add('Text: ${data.text}');
          if (data.hasHtml) parts.add('HTML: ${data.html}');
          if (data.hasImage)
            parts.add('Image: ${data.imageBytes?.length} bytes');
          pasteValue = parts.join('\n');
          clipboardStatus = 'Rich content pasted successfully!';
        } else {
          pasteValue = 'Clipboard is empty';
          clipboardStatus = 'Clipboard is empty';
        }
      });
      _showSnackBar('Rich content pasted');
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Paste rich text failed: $e';
      });
      _showSnackBar('Paste rich text failed: $e');
    }
  }

  Future<void> _copyMultipleWithImage() async {
    if (textController.text.trim().isEmpty && selectedImageBytes == null) {
      _showSnackBar('Please enter text or select an image');
      return;
    }

    try {
      final formats = <String, dynamic>{};
      if (textController.text.trim().isNotEmpty) {
        formats['text/plain'] = textController.text;
      }
      if (htmlController.text.trim().isNotEmpty) {
        formats['text/html'] = htmlController.text;
      }
      if (selectedImageBytes != null) {
        formats['image/png'] = selectedImageBytes!;
      }

      await FlutterClipboard.copyMultiple(formats);
      setState(() {
        clipboardStatus = 'Multiple formats copied successfully!';
      });
      _showSnackBar('Multiple formats copied to clipboard');
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        clipboardStatus = 'Copy multiple formats failed: $e';
      });
      _showSnackBar('Copy multiple formats failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced Clipboard Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clipboard Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(clipboardStatus),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _checkClipboardStatus,
                            child: Text(
                              'Check Status',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearClipboard,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _toggleMonitoring,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isMonitoring ? Colors.orange : Colors.green,
                            ),
                            child: Text(
                              isMonitoring ? 'Stop Monitor' : 'Start Monitor',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Input Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        labelText: 'Text to copy',
                        border: OutlineInputBorder(),
                        hintText: 'Enter text here...',
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: htmlController,
                      decoration: InputDecoration(
                        labelText: 'HTML (optional)',
                        border: OutlineInputBorder(),
                        hintText: '<b>Bold text</b> or <i>italic text</i>',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Image Selection',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.image),
                            label: Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromCamera,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'iOS Simulator: Add photos by dragging images into the Photos app first',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedImageBytes != null) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(height: 4),
                                  Text(
                                    '${(selectedImageBytes!.length / 1024).toStringAsFixed(1)} KB',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (selectedImageBytes != null) ...[
                      SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            selectedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Copy Buttons
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Copy Operations',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _copyText,
                            child: Text('Copy Text'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _copyRichText,
                            child: Text('Copy Rich Text'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _copyWithCallback,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple),
                            child: Text(
                              'Copy with Callback',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _copyImage,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            child: Text(
                              'Copy Image',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _copyMultipleWithImage,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo),
                      child: Text(
                        'Copy Multiple (Text + Image)',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Paste Buttons
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paste Operations',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _pasteText,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            child: Text(
                              'Paste Text',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _pasteRichText,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal),
                            child: Text(
                              'Paste Rich Text',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _pasteImage,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange),
                            child: Text(
                              'Paste Image',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _pasteRichTextWithImage,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan),
                            child: Text(
                              'Paste All Formats',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'iOS Simulator Tip: Text clipboard is shared with macOS ✅, but images are NOT ❌. To test image paste:\n1. Copy an image within the simulator (from Photos, Safari, etc.)\n2. Then paste it here',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Output Section
            if (pasteValue.isNotEmpty || pastedImageBytes != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pasted Content',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      if (pasteValue.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(pasteValue),
                        ),
                      if (pastedImageBytes != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'Pasted Image (${pastedImageBytes!.length} bytes)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              pastedImageBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),

            // Clipboard History
            if (clipboardHistory.isNotEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clipboard History (Last 10)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 200,
                        child: Column(
                          children: clipboardHistory
                              .map((item) => Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text(item),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),

            // Debug Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _loadDebugInfo,
                          child: Text('Load Debug Info'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        debugInfo.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
