import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../theme.dart';

/// Opens an in-app YouTube player sheet for a video id, with an
/// external-browser fallback if embedding fails.
Future<void> showVideoSheet(BuildContext context, String title, String videoId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: T.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _VideoSheet(title: title, videoId: videoId),
  );
}

class _VideoSheet extends StatefulWidget {
  final String title;
  final String videoId;
  const _VideoSheet({required this.title, required this.videoId});

  @override
  State<_VideoSheet> createState() => _VideoSheetState();
}

class _VideoSheetState extends State<_VideoSheet> {
  late final YoutubePlayerController _ctrl;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        enableJavaScript: true,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            if (!_failed)
              YoutubePlayer(
                controller: _ctrl,
                aspectRatio: 16 / 9,
                backgroundColor: Colors.black,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _failed
                          ? 'Embedding failed (region/network). Open it on YouTube:'
                          : 'Video won\'t load? Watch it directly on YouTube:',
                      style: TextStyle(color: T.dim, fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await launchUrl(
                          Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}'),
                          mode: LaunchMode.externalApplication);
                      if (!ok && widget.videoId.isNotEmpty) {
                        setState(() => _failed = true);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('YouTube'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
