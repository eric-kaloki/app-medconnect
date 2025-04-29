import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:medconnect/utils/config.dart';

class VideoCallPage extends StatefulWidget {
  final String channelName;

  const VideoCallPage({Key? key, required this.channelName}) : super(key: key);

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  bool _videoEnabled = true;

  @override
  void initState() {
    super.initState();
    print('Initializing VideoCallPage with roomId: ${widget.channelName}');
    _initializeRenderers();
    _initializeMediaStream();
    _listenForSignalingMessages();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _initializeMediaStream() async {
    print('Initializing media stream for roomId: ${widget.channelName}');
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    _localRenderer.srcObject = _localStream;
    await _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
         {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      print('Local ICE candidate generated: ${candidate.toMap()}');
      FirebaseDatabase.instance.ref('signaling/${widget.channelName}/candidates').push().set(candidate.toMap());
        };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        print('Remote video track received.');
        _remoteRenderer.srcObject = event.streams[0];
      } else if (event.track.kind == 'audio') {
        print('Remote audio track received.');
      }
    };

    _localStream?.getTracks().forEach((track) {
      print('Adding local track: ${track.kind}');
      _peerConnection!.addTrack(track, _localStream!);
    });

    _sendOffer();
  }

  void _sendOffer() async {
    final offer = await _peerConnection!.createOffer();
    print('SDP offer created for roomId ${widget.channelName}: ${offer.sdp}');
    await _peerConnection!.setLocalDescription(offer);
    FirebaseDatabase.instance.ref('signaling/${widget.channelName}/offer').set({
      'sdp': offer.sdp,
      'type': offer.type,
    });
    print('SDP offer sent to Firebase for roomId: ${widget.channelName}');
  }

  void _listenForSignalingMessages() {
    final signalingRef = FirebaseDatabase.instance.ref('signaling/${widget.channelName}');

    signalingRef.child('answer').onValue.listen((event) {
      final answer = event.snapshot.value as Map<dynamic, dynamic>?;
      if (answer != null) {
        print('SDP answer received for roomId ${widget.channelName}: ${answer['sdp']}');
        _peerConnection!.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));
      }
    });

    signalingRef.child('candidates').onChildAdded.listen((event) {
      final candidate = event.snapshot.value as Map<dynamic, dynamic>?;
      if (candidate != null) {
        print('Remote ICE candidate received for roomId ${widget.channelName}: $candidate');
        _peerConnection!.addCandidate(RTCIceCandidate(candidate['candidate'], candidate['sdpMid'], candidate['sdpMLineIndex']));
      }
    });
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebRTC Video Call')),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Stack(
              children: [
                RTCVideoView(_remoteRenderer),
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
                    child: RTCVideoView(_localRenderer),
                  ),
                ),
              ],
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
                    _localStream?.getAudioTracks().forEach((track) {
                      track.enabled = !_isMuted;
                    });
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
                    _localStream?.getVideoTracks().forEach((track) {
                      track.enabled = _videoEnabled;
                    });
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
