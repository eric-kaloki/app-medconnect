import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dio/dio.dart';
import 'package:medconnect/utils/config.dart';

class VideoCallPage extends StatefulWidget {
  final String channelName;

  const VideoCallPage({Key? key, required this.channelName}) : super(key: key);

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _joined = false;
  bool _isMuted = false;
  bool _videoEnabled = true;
  String? _token;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    initializeAgoraMobile();
  }

  Future<void> initializeAgoraMobile() async {
    await fetchToken();
    if (_token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch token.')),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: Config.appId));
      await _engine.enableVideo();

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() {
                _joined = true;
              });
            }
            debugPrint(
                'Local user ${connection.localUid} joined channel ${connection.channelId}');
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
              });
            }
            debugPrint('Remote user $remoteUid joined channel');
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            if (mounted) {
              setState(() {
                _remoteUid = null;
              });
            }
            debugPrint('Remote user $remoteUid left channel');
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Error from Agora: $err, $msg');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Agora Error: $err, $msg')),
              );
            }
          },
        ),
      );

      await _engine.joinChannel(
        token: _token!,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      debugPrint("Error initializing Agora Mobile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing video call: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> fetchToken() async {
    try {
      final url = '${Config.apiUrl}/rtc/${widget.channelName}/0';
      debugPrint('Fetching token from: $url');
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _token = response.data['token'];
        });
        debugPrint('Token fetched successfully: $_token');
      } else {
        debugPrint('Failed to fetch token: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to fetch token: ${response.statusCode}')),
          );
          Navigator.pop(context);
        }
      }
    } on DioException catch (e) {
      debugPrint('Dio error fetching token: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dio error: ${e.message}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error fetching token: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  Widget _renderRemoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Waiting for remote user to join...',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }
  }

  Widget _renderLocalPreview() {
    if (_joined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agora Video Call')),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Center(child: _renderRemoteVideo()),
          ),
          Positioned(
            top: 20,
            right: 20,
            width: 120,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _renderLocalPreview(),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                    _engine.muteLocalAudioStream(_isMuted);
                  },
                ),
                FloatingActionButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                ),
                IconButton(
                  icon: Icon(
                    _videoEnabled ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoEnabled = !_videoEnabled;
                    });
                    _engine.muteLocalVideoStream(!_videoEnabled);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
