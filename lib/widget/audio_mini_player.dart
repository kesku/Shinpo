import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Persistent mini player with play/pause, seek, and speed.
class AudioMiniPlayer extends StatefulWidget {
  final AudioPlayer player;
  const AudioMiniPlayer({super.key, required this.player});

  @override
  State<AudioMiniPlayer> createState() => _AudioMiniPlayerState();
}

class _AudioMiniPlayerState extends State<AudioMiniPlayer> {
  static const _speeds = [0.75, 1.0, 1.25, 1.5];
  late StreamSubscription<PlayerState> _playerSub;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _speed = widget.player.speed;
    _playerSub = widget.player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _playerSub.cancel();
    super.dispose();
  }

  void _toggle() async {
    if (widget.player.playing) {
      await widget.player.pause();
    } else {
      await widget.player.play();
    }
    if (mounted) setState(() {});
  }

  void _seekBy(Duration delta) async {
    final pos = await widget.player.positionStream.first;
    final newPos = pos + delta;
    await widget.player.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void _cycleSpeed() async {
    final idx = _speeds.indexWhere((s) => (s - _speed).abs() < 0.01);
    final next = _speeds[(idx + 1) % _speeds.length];
    await widget.player.setSpeed(next);
    if (mounted) setState(() => _speed = next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 6,
        color: cs.surface,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Rewind 15s',
                icon: const Icon(Icons.replay_10),
                onPressed: () => _seekBy(const Duration(seconds: -15)),
              ),
              _PlayPauseButton(player: widget.player, onToggle: _toggle),
              IconButton(
                tooltip: 'Forward 15s',
                icon: const Icon(Icons.forward_10),
                onPressed: () => _seekBy(const Duration(seconds: 15)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProgressBar(player: widget.player),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _cycleSpeed,
                child: Text('${_speed.toStringAsFixed(2)}x'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final AudioPlayer player;
  final VoidCallback onToggle;
  const _PlayPauseButton({required this.player, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final playing = player.playing;
    return IconButton.filledTonal(
      onPressed: onToggle,
      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
      tooltip: playing ? 'Pause' : 'Play',
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AudioPlayer player;
  const _ProgressBar({required this.player});

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durationSnap) {
        final total = durationSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          initialData: Duration.zero,
          builder: (context, positionSnap) {
            final pos = positionSnap.data ?? Duration.zero;
            final value = total.inMilliseconds == 0
                ? 0.0
                : pos.inMilliseconds / total.inMilliseconds;
            return Row(
              children: [
                Text(_fmt(pos), style: Theme.of(context).textTheme.labelSmall),
                Expanded(
                  child: Slider(
                    value: value.clamp(0.0, 1.0),
                    onChanged: (v) {
                      final target = Duration(
                          milliseconds: (total.inMilliseconds * v).round());
                      player.seek(target);
                    },
                  ),
                ),
                Text(_fmt(total), style: Theme.of(context).textTheme.labelSmall),
              ],
            );
          },
        );
      },
    );
  }
}

