import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// YouTube embeds are unreliable on Android devices (some return error 152-4)
/// and strict web CSPs can block iframe players. Use a dependable thumbnail and
/// open the official YouTube app/browser instead of showing a broken player.
Future<void> showVideoSheet(
  BuildContext context,
  String title,
  String videoId,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: T.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _VideoSheet(title: title, videoId: videoId),
  );
}

class _VideoSheet extends StatelessWidget {
  final String title;
  final String videoId;
  const _VideoSheet({required this.title, required this.videoId});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open YouTube on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _open(context),
                borderRadius: BorderRadius.circular(14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: T.surface2,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.ondemand_video,
                              size: 56,
                              color: T.dim,
                            ),
                          ),
                        ),
                        Container(color: Colors.black38),
                        const Center(
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: T.coral,
                            child: Icon(
                              Icons.play_arrow,
                              color: T.bg,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tutorial opens in the YouTube app or browser. Keep the app cues beside you and ask your gym trainer to check your first light set.',
                style: TextStyle(color: T.dim, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: T.coral,
                    foregroundColor: T.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _open(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in YouTube'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
