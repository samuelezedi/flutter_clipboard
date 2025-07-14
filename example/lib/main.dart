import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  Map<String, dynamic> debugInfo = {};
  List<String> clipboardHistory = [];

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
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
                    ElevatedButton(
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
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Output Section
            if (pasteValue.isNotEmpty)
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
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(pasteValue),
                      ),
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
                    Container(
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
