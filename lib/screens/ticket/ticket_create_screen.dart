import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ticket_service.dart';

// FR-005: User dapat membuat tiket baru dengan:
// 1. Membuat tiket (judul & deskripsi)
// 2. Upload laporan (gambar/file dari galeri atau kamera)

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({
    super.key,
    this.embeddedMode = false,
    this.onTicketCreated,
  });

  final bool embeddedMode;
  final void Function(Map<String, String> ticketData)? onTicketCreated;

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TicketService ticketService = TicketService();
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  final List<XFile> _attachments = [];

  Future<void> _pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _attachments.addAll(images);
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) {
      setState(() {
        _attachments.add(photo);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _showPickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Lampiran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0F766E),
                child: Icon(Icons.photo_library_outlined, color: Colors.white),
              ),
              title: const Text('Dari Galeri'),
              subtitle: const Text('Pilih satu atau lebih foto'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0D9488),
                child: Icon(Icons.camera_alt_outlined, color: Colors.white),
              ),
              title: const Text('Buka Kamera'),
              subtitle: const Text('Ambil foto langsung'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Tiket")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Form Ticket Baru",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Silakan isi judul dan deskripsi masalah dengan jelas.",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Judul Tiket",
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Deskripsi",
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attachment Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Lampiran",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "${_attachments.length} file",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Upload gambar atau foto sebagai bukti laporan.",
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    // Preview grid
                    if (_attachments.isNotEmpty) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _attachments.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_attachments[index].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeAttachment(index),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Add button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Tambah Lampiran"),
                      onPressed: _showPickerDialog,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_outlined),
                onPressed: isLoading ? null : submitTicket,
                label: Text(isLoading ? "Loading..." : "Submit Tiket"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> submitTicket() async {
    final String title = titleController.text.trim();
    final String desc = descriptionController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dan deskripsi wajib diisi")),
      );
      return;
    }

    setState(() => isLoading = true);

    final error = await ticketService.createTicket(
      title: title,
      description: desc,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final ticketData = <String, String>{'title': title, 'description': desc};

    if (widget.onTicketCreated != null) {
      widget.onTicketCreated!(ticketData);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Tiket berhasil dikirim"),
        backgroundColor: Colors.green,
      ),
    );

    if (widget.embeddedMode) {
      titleController.clear();
      descriptionController.clear();
      setState(() => _attachments.clear());
    } else {
      Navigator.pop(context, ticketData);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
