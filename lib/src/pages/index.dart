import 'package:kumchat/src/pages/create_stream_data.dart';
import 'package:kumchat/src/pages/live_streaming.dart';
import 'package:kumchat/src/pages/media_channel_relay.dart';
import 'package:kumchat/src/pages/multichannel.dart';
import 'package:kumchat/src/pages/voice_change.dart';

/// Data source for advanced examples
// ignore: non_constant_identifier_names
final Advanced = [
  {'name': 'Advanced'},
  {'name': 'MultiChannel', 'widget': MultiChannel()},
  {'name': 'LiveStreaming', 'widget': LiveStreaming()},
  {
    'name': 'CreateStreamData',
    'widget': CreateStreamData(),
  },
  {
    'name': 'MediaChannelRelay',
    'widget': MediaChannelRelay(),
  },
  {'name': 'VoiceChange', 'widget': VoiceChange()},
];
