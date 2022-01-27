import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:agora_flutter_quickstart/model/users.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:agora_rtc_engine/rtc_engine.dart';
// import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
// import 'package:agora_rtc_engine/rtc_channel.dart' as RtcChannel;
// import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

const appId =
    "88aca9ae36b64c5fb1f5b27d2f867e20"; //given id is appid which is available in agora dashboard/console
const token =
    "00688aca9ae36b64c5fb1f5b27d2f867e20IADYqBSpCRJt5ooU4dydR5vIX23A9h7pxnMKmvirnTahIJU2fRgAAAAAEAD45Mp2X5vzYQEAAQBgm/Nh"; //given id is token  which can be generated  from agora dashboard/console
void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final _users = <int>[];
  Map<int, User> _userMap = new Map<int, User>();
  final _infoStrings = <String>[];

  int? _remoteUid;
  bool muted = true;
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

  Future<void> _handleMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  Future<void> initAgora() async {
    // retrieve permissions

    //create the engine
    _engine = await RtcEngine.create(appId);
    await _engine.enableAudio();
    // Enables the audioVolumeIndication
    await _engine.enableAudioVolumeIndication(250, 3, true);
    _engine.setEventHandler(
      RtcEngineEventHandler(
          joinChannelSuccess: (String channel, int uid, int elapsed) {
        print("local user $uid joined");
        setState(() {
          _localUserJoined = true;
          _remoteUid = uid;

          // _engine.setEnableSpeakerphone(true);
          _userMap.addAll({
            uid: User(
              uid,
              false,
            )
          });
        });
      }, userJoined: (int uid, int elapsed) {
        print("remote user $uid joined");
        setState(() {
          _userMap.addAll({
            uid: User(
              uid,
              false,
            )
          });
          // _users.add(_remoteUid!);
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
          muted = false;
        });
      }, microphoneEnabled: (enabled) {
        _engine.setEnableSpeakerphone(false);
      },

          /// Detecting active speaker by using audioVolumeIndication callback
          audioVolumeIndication: (volumeInfo, v) {
        volumeInfo.forEach((speaker) {
          //detecting speaking person whose volume more than 5
          if (speaker.volume > 5) {
            try {
              _userMap.forEach((key, value) {
                //Highlighting local user
                //In this callback, the local user is represented by an uid of 0.
                if ((_remoteUid?.compareTo(key) == 0) && (speaker.uid == 0)) {
                  setState(() {
                    _userMap.update(key, (value) => User(key, true));
                  });
                }

                //Highlighting remote user
                else if (key.compareTo(speaker.uid) == 0) {
                  setState(() {
                    _userMap.update(key, (value) => User(key, true));
                  });
                } else {
                  setState(() {
                    _userMap.update(key, (value) => User(key, false));
                  });
                }
              });
            } catch (error) {
              print('Error:${error.toString()}');
            }
          }
        });
      }),
    );
    _engine.setDefaultAudioRoutetoSpeakerphone(true);
    await _engine.joinChannel(token, "audio", null, 0);
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff1F1F1F),
      appBar: AppBar(
        title: const Text('Audio Room'),
        titleTextStyle:
            TextStyle(height: 1.5, fontWeight: FontWeight.w700, fontSize: 20.0),
        backgroundColor: Color(0xff323232),
      ),
      body: Stack(
        children: [
          // Center(
          //     child:
          //         // RtcLocalView.SurfaceView(
          //         //     mirrorMode: VideoMirrorMode.Enabled,
          //         //   )
          //         CircleAvatar(
          //   radius: 30.0,
          //   backgroundImage: AssetImage("assets/images/profile.png"),
          //   backgroundColor: Colors.transparent,
          // )),
          // _remoteVideo(),
          _buildGridVideoView(),
          toolbarWidget(),
        ],
      ),
    );
  }

  GridView _buildGridVideoView() {
    return GridView.builder(
        shrinkWrap: true,
        itemCount: _userMap.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: MediaQuery.of(context).size.height / 1100,
            crossAxisCount: 2),
        itemBuilder: (BuildContext context, int index) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: (_userMap.entries.elementAt(index).key == _remoteUid)
                  ? Column(
                      children: [
                        CircleAvatar(
                          radius: 43.0,
                          backgroundImage: AssetImage(
                            "assets/images/profile.png",
                          ),
                          backgroundColor: Color(0xff1F1F1F),
                        ),
                        Container(
                          transform: Matrix4.translationValues(0.0, -12.0, 0.0),
                          height: 35.0,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Color(0xff1F1F1F), width: 3.0)),
                          child: RawMaterialButton(
                            onPressed: () async {
                              var status = await Permission.microphone.status;
                              if (status.isDenied) {
                                await [Permission.microphone].request();
                              } else {
                                onToggleMute();
                              }
                            },
                            child: Center(
                              child: Icon(
                                muted ? Icons.mic_off : Icons.mic,
                                color: muted ? Colors.black : Colors.white,
                                size: 25.0,
                              ),
                            ),
                            shape: CircleBorder(side: BorderSide.none),
                            // elevation: 2.0,
                            fillColor: muted ? Colors.white : Color(0xffDC734C),
                            // padding: const EdgeInsets.all(12.0),
                          ),
                        ),
                        Text(
                          'Utsab',
                          style: GoogleFonts.poppins(
                              height: 1.57,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        Text(
                          'Host',
                          style: GoogleFonts.poppins(
                              height: 1.5,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w400,
                              color: Colors.white),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _userMap.entries.elementAt(index).value.isSpeaking
                            ? Column(
                                children: [
                                  AvatarGlow(
                                    glowColor: Color(0xff19A1AC),
                                    endRadius: 50.0,
                                    duration: Duration(milliseconds: 2000),
                                    repeat: true,
                                    showTwoGlows: true,
                                    repeatPauseDuration:
                                        Duration(milliseconds: 100),
                                    child: CircleAvatar(
                                      radius: 43.0,
                                      backgroundImage: AssetImage(
                                        "assets/images/profile.png",
                                      ),
                                      backgroundColor: Color(0xff1F1F1F),
                                    ),
                                  ),
                                  Container(
                                    transform: Matrix4.translationValues(
                                        0.0, -12.0, 0.0),
                                    height: 35.0,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Color(0xff1F1F1F),
                                            width: 3.0)),
                                    child: RawMaterialButton(
                                      onPressed: () async {
                                        var status =
                                            await Permission.microphone.status;
                                        if (status.isDenied) {
                                          await [Permission.microphone]
                                              .request();
                                        } else {
                                          onToggleMute();
                                        }
                                      },
                                      child: Center(
                                        child: Icon(
                                          muted ? Icons.mic_off : Icons.mic,
                                          color: muted
                                              ? Colors.black
                                              : Colors.white,
                                          size: 25.0,
                                        ),
                                      ),
                                      shape:
                                          CircleBorder(side: BorderSide.none),
                                      // elevation: 2.0,
                                      fillColor: muted
                                          ? Colors.white
                                          : Color(0xffDC734C),
                                      // padding: const EdgeInsets.all(12.0),
                                    ),
                                  ),
                                  Text(
                                    'Utsab',
                                    style: GoogleFonts.poppins(
                                        height: 1.57,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                  ),
                                  Text(
                                    'Host',
                                    style: GoogleFonts.poppins(
                                        height: 1.5,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  CircleAvatar(
                                    radius: 43.0,
                                    backgroundImage: AssetImage(
                                      "assets/images/profile.png",
                                    ),
                                    backgroundColor: Color(0xff1F1F1F),
                                  ),
                                  Container(
                                    transform: Matrix4.translationValues(
                                        0.0, -12.0, 0.0),
                                    height: 35.0,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Color(0xff1F1F1F),
                                            width: 3.0)),
                                    child: RawMaterialButton(
                                      onPressed: () async {
                                        var status =
                                            await Permission.microphone.status;
                                        if (status.isDenied) {
                                          await [Permission.microphone]
                                              .request();
                                        } else {
                                          onToggleMute();
                                        }
                                      },
                                      child: Center(
                                        child: Icon(
                                          muted ? Icons.mic_off : Icons.mic,
                                          color: muted
                                              ? Colors.black
                                              : Colors.white,
                                          size: 25.0,
                                        ),
                                      ),
                                      shape:
                                          CircleBorder(side: BorderSide.none),
                                      // elevation: 2.0,
                                      fillColor: muted
                                          ? Colors.white
                                          : Color(0xffDC734C),
                                      // padding: const EdgeInsets.all(12.0),
                                    ),
                                  ),
                                  Text(
                                    'Utsab',
                                    style: GoogleFonts.poppins(
                                        height: 1.57,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                  ),
                                  Text(
                                    'Host',
                                    style: GoogleFonts.poppins(
                                        height: 1.5,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white),
                                  ),
                                ],
                              )
                      ],
                    ),
            ));
  }

  // Display remote user's video
  Widget _remoteVideo() {
    // if (_remoteUid != null) {
    // return RtcRemoteView.SurfaceView(uid: _remoteUid!);
    return GridView.builder(
      shrinkWrap: true,
      physics: ScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      itemCount: _userMap.length,
      itemBuilder: (gc, index) {
        return (_userMap.entries.elementAt(index).key == _remoteUid)
            ? Wrap(
                spacing: 20.0,
                runSpacing: 20.0,
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      _userMap.entries.elementAt(index).value.isSpeaking
                          ? AvatarGlow(
                              glowColor: Colors.blue,
                              endRadius: 100.0,
                              duration: Duration(milliseconds: 2000),
                              repeat: true,
                              showTwoGlows: true,
                              repeatPauseDuration: Duration(milliseconds: 100),
                              child: Material(
                                // Replace this child with your own
                                elevation: 8.0,
                                shape: CircleBorder(),
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey[100],
                                  backgroundImage:
                                      AssetImage("assets/images/profile.png"),
                                  radius: 40.0,
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 30.0,
                              backgroundImage:
                                  AssetImage("assets/images/profile.png"),
                              backgroundColor: Colors.transparent,
                            ),
                      Positioned(
                        bottom: 10.0,
                        child: CircleAvatar(
                          radius: 10.0,
                          child: IconButton(
                              onPressed: () async {
                                await _handleMic(Permission.microphone);
                              },
                              icon: Icon(
                                Icons.mic,
                                color: Colors.black,
                              )),
                          backgroundColor: Colors.white,
                        ),
                      )
                    ],
                  )
                ],
              )
            : Text(
                'No user joined',
                textAlign: TextAlign.center,
              );
      },
    );
    // } else {
    //   return Text(
    //     'No user joined',
    //     textAlign: TextAlign.center,
    //   );
    // }
  }

//for mic, call end and camera switch
  Widget toolbarWidget() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // RawMaterialButton(
          //   onPressed: onToggleMute,
          //   child: Icon(
          //     muted ? Icons.mic_off : Icons.mic,
          //     color: muted ? Colors.white : Colors.blueAccent,
          //     size: 20.0,
          //   ),
          //   shape: CircleBorder(),
          //   elevation: 2.0,
          //   fillColor: muted ? Colors.blueAccent : Colors.white,
          //   padding: const EdgeInsets.all(12.0),
          // ),
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
  Widget commonAvatar() {
    return Column(
      children: [
        CircleAvatar(
          radius: 43.0,
          backgroundImage: AssetImage(
            "assets/images/profile.png",
          ),
          backgroundColor: Color(0xff1F1F1F),
        ),
        Container(
          transform: Matrix4.translationValues(0.0, -12.0, 0.0),
          height: 35.0,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xff1F1F1F), width: 3.0)),
          child: RawMaterialButton(
            onPressed: () async {
              var status = await Permission.microphone.status;
              if (status.isDenied) {
                await [Permission.microphone].request();
              } else {
                onToggleMute();
              }
            },
            child: Center(
              child: Icon(
                muted ? Icons.mic_off : Icons.mic,
                color: muted ? Colors.black : Colors.white,
                size: 25.0,
              ),
            ),
            shape: CircleBorder(side: BorderSide.none),
            // elevation: 2.0,
            fillColor: muted ? Colors.white : Color(0xffDC734C),
            // padding: const EdgeInsets.all(12.0),
          ),
        ),
        Text(
          'Utsab',
          style: GoogleFonts.poppins(
              height: 1.57,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
        Text(
          'Host',
          style: GoogleFonts.poppins(
              height: 1.5,
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: Colors.white),
        ),
      ],
    );
  }

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
