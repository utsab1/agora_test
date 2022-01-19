import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:agora_rtc_engine/rtc_engine.dart';
// import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
// import 'package:agora_rtc_engine/rtc_channel.dart' as RtcChannel;
// import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

const appId =
    "955c5df0b5ad45e5a3fa1edb81962e1d"; //given id is appid which is available in agora dashboard/console
const token =
    "006955c5df0b5ad45e5a3fa1edb81962e1dIADVwyWpjl8eC+V7qOgagQIygCzSrhOoSmChATNMx9mlWJU2fRgAAAAAIgDC8VeAwHbpYQQAAQDAdulhAgDAdulhAwDAdulhBADAdulh"; //given id is token  which can be generated  from agora dashboard/console
void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final _users = <int>[];
  final _infoStrings = <String>[];

  int? _remoteUid;
  bool muted = false;
  bool _localUserJoined = false;
//Initialize rtc engine for video call p2p
  late RtcEngine _engine;
//for mic,call end and camera switch

  @override
  void initState() {
    super.initState();

    //It initialize the agora for permissions
    initAgora();
  }

  Future<void> initAgora() async {
    debugger();
    // retrieve permissions
    await [Permission.microphone].request();

    //create the engine
    _engine = await RtcEngine.create(appId);
    await _engine.enableAudio();
    _engine.setEventHandler(
      RtcEngineEventHandler(
          joinChannelSuccess: (String channel, int uid, int elapsed) {
        print("local user $uid joined");
        setState(() {
          _localUserJoined = true;
        });
      }, userJoined: (int uid, int elapsed) {
        print("remote user $uid joined");
        setState(() {
          _remoteUid = uid;
          _users.add(_remoteUid!);
        });
      }, userOffline: (int uid, UserOfflineReason reason) {
        print("remote user $uid left channel");
        setState(() {
          // _remoteUid = null;
          _users.remove(_remoteUid!);
        });
      }, leaveChannel: (stats) {
        setState(() {
          // _remoteUid = null;

          _users.clear();
        });
      }, userMuteAudio: (uid, muted) {
        print("remote user $uid left channel");
        setState(() {
          muted = true;
        });
      },

          /// Detecting active speaker by using audioVolumeIndication callback
          audioVolumeIndication: (volumeInfo, v) {
        //core logic will be here
      }),
    );

    await _engine.joinChannel(token, "audio", null, 0);
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Video Call'),
      ),
      body: Stack(
        children: [
          Center(
              child:
                  // RtcLocalView.SurfaceView(
                  //     mirrorMode: VideoMirrorMode.Enabled,
                  //   )
                  CircleAvatar(
            radius: 30.0,
            backgroundImage: AssetImage("assets/images/profile.png"),
            backgroundColor: Colors.transparent,
          )),
          _remoteVideo(),
          toolbarWidget(),
        ],
      ),
    );
  }

  // Display remote user's video
  Widget _remoteVideo() {
    // if (_remoteUid != null) {
    // return RtcRemoteView.SurfaceView(uid: _remoteUid!);
    if (_users.isNotEmpty) {
      return GridView.builder(
        shrinkWrap: true,
        physics: ScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: _users.length,
        itemBuilder: (gc, index) {
          return Column(
            children: [
              Container(
                color: Colors.blue,
                height: 50,
                width: 50,
                margin: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    image: AssetImage("assets/images/profile.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Text(
              //       _users..name.split(' ')[0],
              //       overflow: TextOverflow.ellipsis,
              //       textAlign: TextAlign.center,
              //       style: TextStyle(
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //   ],
              // ),
            ],
          );
        },
      );
    } else {
      return Text(
        'No user joined',
        textAlign: TextAlign.center,
      );
    }
  }

//for mic, call end and camera switch
  Widget toolbarWidget() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: onSwitchCamera,
            child: Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
          )
        ],
      ),
    );
  }
  // Display remote user's video
  // Widget _renderLocalPreview() {
  //   return RtcLocalView.SurfaceView();
  // }

  void onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void onSwitchCamera() {
    _engine.switchCamera();
  }
}
