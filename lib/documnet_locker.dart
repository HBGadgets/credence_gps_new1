import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DocumentLockerScreen(CarID: 0),
  ));
}

class DocumentLockerScreen extends StatefulWidget {
  final int CarID;

  const DocumentLockerScreen({Key? key, required this.CarID}) : super(key: key);

  @override
  _DocumentLockerScreenState createState() => _DocumentLockerScreenState();
}

class _DocumentLockerScreenState extends State<DocumentLockerScreen> {
  int columnsCount = 2;
  final List<String> _initialContainers = [
    'Aadhar Card',
    'Registration Certificate',
    'PUC',
    'Insurance'
  ];
  Map<String, List<dynamic>> _containerMap = {};
  String _newContainerName = '';
  final Map<String, String> _containerImages = {
    'Aadhar Card': 'assets/aadhar_logo.png',
    'Registration Certificate': 'assets/rc_logo.png',
    'PUC': 'assets/puc_logo.png',
    'Insurance': 'assets/insurance_logo.png',
  };

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
    _initializeContainers();
  }

  void _initializeContainers() {
    for (String containerName in _initialContainers) {
      _containerMap[containerName] = [];
    }
  }

  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Permission Denied"),
            content: const Text(
                "Please grant storage permission to use this feature."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _pickDocument(String containerName) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _containerMap[containerName]!.add(file);
      });
    } else {
      // Handle the case where the user canceled the file picker.
    }
  }

  void _deleteContainer(String containerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content:
          const Text("Are you sure you want to delete this container?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _containerMap.remove(containerName);
                });
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _addContainer() {
    if (_newContainerName.isNotEmpty) {
      setState(() {
        _containerMap[_newContainerName] = [];
      });
    }
  }

  void _createNewContainer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create New Container"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    _newContainerName = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Container Name'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _addContainer();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openContainerPopupMenu(String containerName) {
    final RenderBox overlay =
    Overlay.of(context)!.context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _getContainerButtonRect(containerName),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            title: const Text('Delete'),
            leading: const Icon(Icons.delete),
            onTap: () {
              _deleteContainer(containerName);
            },
          ),
        ),
        PopupMenuItem<String>(
          value: 'AddDocument',
          child: ListTile(
            title: const Text('Add Document'),
            leading: const Icon(Icons.add),
            onTap: () {
              _pickDocument(containerName);
            },
          ),
        ),
        const PopupMenuItem<String>(
          value: 'download',
          child: ListTile(
            title: Text('Download'),
            leading: Icon(Icons.download),
          ),
        ),
        PopupMenuItem<String>(
          value: 'view_documents',
          child: ListTile(
            title: const Text('View Documents'),
            onTap: () {
              Navigator.of(context).pop(); // Close the menu
              _navigateToDocumentsScreen(containerName);
            },
            leading: const Icon(Icons.remove_red_eye),
          ),
        ),
      ],
    );
  }

  Rect _getContainerButtonRect(String containerName) {
    RenderBox button = context.findRenderObject() as RenderBox;
    return button.localToGlobal(Offset.zero) & button.size;
  }

  @override
  Widget build(BuildContext context) {
    int columnsCount = 2;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(8.0),
          ),
          child: AppBar(
            elevation: 0.1,
            backgroundColor: Colors.black,
            title: Text(
              "Document Locker",
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                onPressed: () {
                  _createNewContainer();
                },
              ),
            ],
            leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back_ios_new_outlined,
                  color: Colors.white),
            ),
          ),
        ),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnsCount,
        ),
        itemCount: _containerMap.length,
        itemBuilder: (context, index) {
          String containerName = _containerMap.keys.elementAt(index);
          String customImagePath =
              _containerImages[containerName] ?? 'assets/license.png';
          return Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(8),
            child: InkWell(
              onTap: () {
                _openContainerPopupMenu(containerName);
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      customImagePath,
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      containerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload Documents',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDocumentsScreen(String containerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentsScreen(
          containerName: containerName,
          documents: _containerMap[containerName] ?? [],
        ),
      ),
    );
  }
}

class DocumentsScreen extends StatefulWidget {
  final String containerName;
  final List<dynamic> documents;

  DocumentsScreen({required this.containerName, required this.documents});

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  Future<void> _pickAndDownloadDocument() async {
    try {
      if (await Permission.storage.request().isGranted) {
        FilePickerResult? result = await FilePicker.platform.pickFiles();

        if (result != null) {
          File document = File(result.files.single.path!);
          await downloadDocument(document);
        }
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> downloadDocument(File document) async {
    try {
      const customPath = ('/storage/emulated/0/DCIM/credence ');
      final directory = Directory(customPath);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final documentPath = '${directory.path}/${path.basename(document.path)}';
      final File documentFile = File(documentPath);

      await document.copy(documentPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document downloaded to $documentPath'),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content:
            const Text("Failed to download document. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void _deleteDocument(File document) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                try {
                  document.deleteSync();
                  setState(() {
                    widget.documents.remove(document);
                  });
                  Navigator.of(context).pop();
                } catch (e) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Error"),
                        content: const Text(
                            "Failed to delete item. Please try again."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents for ${widget.containerName}'),
      ),
      body:
      ListView.builder(
        itemCount: widget.documents.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(
                path.basename(widget.documents[index].path),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      downloadDocument(widget.documents[index]);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteDocument(widget.documents[index]);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndDownloadDocument,
        tooltip: 'Pick and Download Document',
        child: const Icon(Icons.add),
      ),
    );
  }
}
