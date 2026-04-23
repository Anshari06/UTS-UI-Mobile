import 'package:flutter/material.dart';
import '../../services/ticket_store.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Tiket")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Form Ticket Baru",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: () {
                      final String title = titleController.text;
                      final String desc = descriptionController.text;

                      if (title.isEmpty || desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Semua field wajib diisi"),
                          ),
                        );
                      } else {
                        final ticketData = {
                          'title': title,
                          'description': desc,
                        };

                        if (widget.onTicketCreated != null) {
                          widget.onTicketCreated!(ticketData);
                        }

                        if (widget.embeddedMode) {
                          TicketStore.instance.addTicket(
                            title: title,
                            description: desc,
                          );
                          titleController.clear();
                          descriptionController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Tiket berhasil dikirim"),
                            ),
                          );
                        } else {
                          Navigator.pop(context, ticketData);
                        }
                      }
                    },
                    label: const Text("Submit"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
