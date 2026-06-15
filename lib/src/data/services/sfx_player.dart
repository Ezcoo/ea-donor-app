import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the app's short UI sound effects.
///
/// Boost blips are pre-pitched files — one per ladder rung, climbing a
/// pentatonic scale — rather than one file plus setPlaybackRate, because
/// rate changing is not reliably supported on every audioplayers backend
/// (notably Linux/GStreamer), while plain playback is.
///
/// Sound is decoration: if anything fails (missing audio backend, asset
/// problems, running in a widget test where the plugin has no platform
/// channel) the app must keep working, so [init] swallows errors and the
/// play methods no-op when pools are absent.
class SfxPlayer {
  /// One pool per ladder rung lets rapid taps overlap (each pool keeps up
  /// to [_maxOverlap] native players warm) and gives each rung its pitch.
  final List<AudioPool> _boostPools = [];
  AudioPool? _tapPool;
  AudioPool? _donatePool;
  AudioPool? _resetPool;

  static const _boostVariants = 13; // == DonationLadder.steps.length
  static const _maxOverlap = 2;

  Future<void> init() async {
    try {
      for (var rung = 0; rung < _boostVariants; rung++) {
        _boostPools.add(await AudioPool.createFromAsset(
          path: 'sfx/boost_$rung.wav',
          maxPlayers: _maxOverlap,
        ));
      }
      _tapPool =
          await AudioPool.createFromAsset(path: 'sfx/tap.wav', maxPlayers: 3);
      _donatePool = await AudioPool.createFromAsset(
          path: 'sfx/donate.wav', maxPlayers: 1);
      _resetPool = await AudioPool.createFromAsset(
          path: 'sfx/reset.wav', maxPlayers: 1);
    } catch (error) {
      debugPrint('Sound effects unavailable: $error');
      _boostPools.clear();
      _tapPool = null;
      _donatePool = null;
      _resetPool = null;
    }
  }

  /// Blip pitched to the given ladder rung — higher rung, higher note.
  void boost(int rung) {
    if (_boostPools.isEmpty) return;
    _boostPools[rung.clamp(0, _boostPools.length - 1)].start();
  }

  void donate() => _donatePool?.start();

  void reset() => _resetPool?.start();

  void tap() => _tapPool?.start();
}
