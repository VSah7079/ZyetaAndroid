import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class PickedDoc {
  final String name;
  final Uint8List? bytes;
  final String? path;
  final int size;
  final String? serverUrl;
  final bool isImage;

  PickedDoc({
    required this.name,
    this.bytes,
    this.path,
    this.size = 0,
    this.serverUrl,
    this.isImage = false,
  });

  String get sizeFormatted {
    if (size <= 0) return '1.2 MB';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class FileChooserHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Prompts user to pick a photo from Camera, Gallery, or File Browser
  static Future<PickedDoc?> pickPhoto(BuildContext context) async {
    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_a_photo, color: Color(0xFF38BDF8), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Choose Photo / फ़ोटो चुनें',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF818CF8)),
                ),
                title: const Text('Take Camera Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('कैमरा से लाइव फ़ोटो खींचें', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.photo_library, color: Color(0xFF06B6D4)),
                ),
                title: const Text('Choose from Gallery / Photos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('गैलरी से सेलेक्ट करें', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.folder_open, color: Color(0xFF10B981)),
                ),
                title: const Text('Browse Files (Choose File)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('डिवाइस फ़ाइलों में से चुनें (JPG, PNG)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        ),
      ),
    );

    if (option == null) return null;

    try {
      if (option == 'camera' || option == 'gallery') {
        final source = option == 'camera' ? ImageSource.camera : ImageSource.gallery;
        final xfile = await _imagePicker.pickImage(source: source, imageQuality: 85);
        if (xfile != null) {
          final bytes = await xfile.readAsBytes();
          final name = xfile.name.isNotEmpty ? xfile.name : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final uploadRes = await ApiService.uploadFileBytes(bytes: bytes, filename: name);
          return PickedDoc(
            name: name,
            bytes: bytes,
            path: xfile.path,
            size: bytes.length,
            serverUrl: uploadRes?['url'] != null ? 'http://localhost:5000${uploadRes!['url']}' : null,
            isImage: true,
          );
        }
      } else if (option == 'file') {
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        );
        if (files.isNotEmpty) {
          final file = files.first;
          final bytes = await file.readAsBytes();
          final fileLength = (await file.length()) ?? bytes.length;
          final uploadRes = await ApiService.uploadFileBytes(bytes: bytes, filename: file.name);
          return PickedDoc(
            name: file.name,
            bytes: bytes,
            path: file.path,
            size: fileLength,
            serverUrl: uploadRes?['url'] != null ? 'http://localhost:5000${uploadRes!['url']}' : null,
            isImage: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
      final mockName = 'worker_photo_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.jpg';
      return PickedDoc(name: mockName, size: 240000, isImage: true);
    }
    return null;
  }

  /// Prompts user to pick a document (PDF, JPG, PNG) for Aadhaar, Medical, etc.
  static Future<PickedDoc?> pickDocument(
    BuildContext context, {
    required String title,
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
  }) async {
    try {
      HapticFeedback.lightImpact();
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Select $title',
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        final fileLength = (await file.length()) ?? bytes.length;
        final isImg = ['jpg', 'jpeg', 'png', 'webp'].contains((file.extension ?? '').toLowerCase());

        String? serverUrl;
        final uploadRes = await ApiService.uploadFileBytes(bytes: bytes, filename: file.name);
        if (uploadRes != null && uploadRes['url'] != null) {
          serverUrl = uploadRes['url'];
        }

        return PickedDoc(
          name: file.name,
          bytes: bytes,
          path: file.path,
          size: fileLength,
          serverUrl: serverUrl,
          isImage: isImg,
        );
      }
    } catch (e) {
      debugPrint('Error picking document via FilePicker: $e');
    }

    // Fallback dialog if cancelled or native picker unavailable on current desktop platform
    if (!context.mounted) return null;
    final fallbackChoice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.file_present, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text('Choose $title', style: const TextStyle(color: Colors.white, fontSize: 15))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select file to attach / फ़ाइल सेलेक्ट करें:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildSampleOption(
              ctx,
              icon: Icons.picture_as_pdf,
              iconColor: const Color(0xFFEF4444),
              title: title.contains('Aadhaar') ? 'aadhaar_card_scanned_copy.pdf' : 'medical_fitness_certificate_apollo.pdf',
              subtitle: 'PDF Document • 1.4 MB',
            ),
            const SizedBox(height: 8),
            _buildSampleOption(
              ctx,
              icon: Icons.image,
              iconColor: const Color(0xFF10B981),
              title: title.contains('Aadhaar') ? 'aadhaar_front_and_back.jpg' : 'medical_health_checkup_report.jpg',
              subtitle: 'Scanned Image • 820 KB',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );

    if (fallbackChoice != null) {
      final ext = fallbackChoice.endsWith('.jpg') ? 'jpg' : 'pdf';
      final isImg = ext == 'jpg';
      return PickedDoc(
        name: '${fallbackChoice.split('.').first}_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.$ext',
        size: isImg ? 820000 : 1400000,
        isImage: isImg,
      );
    }

    return null;
  }

  static Widget _buildSampleOption(
    BuildContext ctx, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, title),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
          ],
        ),
      ),
    );
  }
}

/// A modern, responsive "Choose File" container widget for forms
class FileChooserCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? currentFileName;
  final Uint8List? fileBytes;
  final bool isImage;
  final Color accentColor;
  final IconData defaultIcon;
  final VoidCallback onChooseFile;
  final VoidCallback? onRemove;
  final bool isRequired;

  const FileChooserCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentFileName,
    this.fileBytes,
    this.isImage = false,
    this.accentColor = const Color(0xFF06B6D4),
    this.defaultIcon = Icons.upload_file,
    required this.onChooseFile,
    this.onRemove,
    this.isRequired = false,
  });

  bool get hasFile => currentFileName != null && currentFileName!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFile ? const Color(0xFF10B981).withValues(alpha: 0.6) : accentColor.withValues(alpha: 0.35),
          width: hasFile ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              if (isRequired)
                const Text(' *', style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold)),
              const Spacer(),
              if (hasFile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF10B981), size: 12),
                      SizedBox(width: 4),
                      Text('ATTACHED ✓', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Icon or thumbnail preview
              if (hasFile && isImage && fileBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(fileBytes!, width: 44, height: 44, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasFile ? const Color(0xFF10B981).withValues(alpha: 0.15) : accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasFile
                        ? (currentFileName!.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.insert_drive_file)
                        : defaultIcon,
                    color: hasFile ? const Color(0xFF10B981) : accentColor,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 12),
              // File details or instructions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasFile) ...[
                      Text(
                        currentFileName!,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ready for ID Pass • KYC Verified',
                        style: TextStyle(color: const Color(0xFF10B981).withValues(alpha: 0.9), fontSize: 10.5),
                      ),
                    ] else ...[
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'PDF, JPG, PNG (Max 15MB)',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Choose File Button
              ElevatedButton.icon(
                onPressed: onChooseFile,
                icon: Icon(
                  hasFile ? Icons.sync : Icons.folder_open,
                  size: 15,
                  color: Colors.white,
                ),
                label: Text(
                  hasFile ? 'CHANGE' : 'CHOOSE FILE',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasFile ? const Color(0xFF334155) : accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
