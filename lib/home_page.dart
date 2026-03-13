import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:path/path.dart' as p;


import 'package:recorder/parse_locale_tag.dart';
import 'package:recorder/recorded_audio.dart';
import 'package:recorder/recorder_controller.dart';
import 'package:recorder/setting_page.dart';
import 'package:recorder/theme_color.dart';
import 'package:recorder/theme_mode_number.dart';
import 'package:recorder/ad_manager.dart';
import 'package:recorder/loading_screen.dart';
import 'package:recorder/model.dart';
import 'package:recorder/main.dart';
import 'package:recorder/ad_banner_widget.dart';
import 'package:recorder/l10n/app_localizations.dart';


class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> with TickerProviderStateMixin {
  late AdManager _adManager;
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;
  //
  RecorderController? _recorderController;
  bool _isStopPressed = false;
  late AnimationController _spinLeft;
  late AnimationController _spinRight;
  double _spinLeftDirection = 1.0;
  double _spinRightDirection = 1.0;
  //
  double _knobX = 0.77;
  bool _isDraggingVolume = false;
  double _volume = 0.0;
  //
  String _message = '';
  //

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initState();
    });
  }

  void _initState() async {
    _adManager = AdManager();
    _wakelock();
    _spinLeft = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _spinRight = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    //
    await _initRecorderController();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    if (_recorderController != null && _recorderController!.recorder.isRecording) {
      _recorderController?.stopPlay();
    }
    _recorderController?.dispose();
    _spinLeft.dispose();
    _spinRight.dispose();
    super.dispose();
  }

  Future<void> _initRecorderController() async {
    setState(() {
      _message = '';
    });
    PermissionStatus status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (status.isGranted) {
      _recorderController = RecorderController();
      await _recorderController?.init();
      _recorderController?.isRecording.addListener(_updateSpin);
      _recorderController?.isPlaying.addListener(_updateSpin);
      _recorderController?.isRewinding.addListener(_updateSpin);
    } else {
      setState(() {
        _message = AppLocalizations.of(context)!.microphonePermission;
      });
    }
  }

  Future<void> _refreshMessage() async {
    setState(() {
      _message = '';
    });
    PermissionStatus status = await Permission.microphone.status;
    if (!status.isGranted) {
      setState(() {
        _message = AppLocalizations.of(context)!.microphonePermission;
      });
    }
  }

  void _wakelock() {
    if (Model.wakelockEnabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _updateSpin() {
    if (_recorderController == null) {
      return;
    }
    final rec = _recorderController!.isRecording.value;
    final play = _recorderController!.isPlaying.value;
    final rew = _recorderController!.isRewinding.value;
    if (rew) {
      _spinLeft.duration = const Duration(milliseconds: 600);
      _spinRight.duration = const Duration(milliseconds: 200);
      _spinLeftDirection = 1.0;
      _spinRightDirection = 1.0;
      _spinLeft.repeat();
      _spinRight.repeat();
      return;
    }
    if (rec || play) {
      _spinLeft.duration = const Duration(milliseconds: 6000);
      _spinRight.duration = const Duration(milliseconds: 2000);
      _spinLeftDirection = -1.0;
      _spinRightDirection = -1.0;
      _spinLeft.repeat();
      _spinRight.repeat();
      return;
    }
    _spinLeft.stop();
    _spinRight.stop();
  }

  void _openSetting() async {
    final updatedSettings = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingPage(),
      ),
    );
    if (updatedSettings != null) {
      if (mounted) {
        final mainState = context.findAncestorStateOfType<MainAppState>();
        if (mainState != null) {
          mainState
            ..locale = parseLocaleTag(Model.languageCode)
            ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
            ..setState(() {});
        }
        _wakelock();
      }
      if (mounted) {
        setState(() {
          _isFirst = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady == false) {
      return const LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _refreshMessage();
      _themeColor = ThemeColor(context: context);
    }
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: _themeColor.mainBackColor,
      body: Stack(children:[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_themeColor.mainBackColor2, _themeColor.mainBackColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            image: DecorationImage(
              image: AssetImage('assets/image/tile.png'),
              repeat: ImageRepeat.repeat,
              opacity: 0.1,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Text('RECORDER',
                      style: t.titleMedium?.copyWith(
                        fontFamily: GoogleFonts.orbitron().fontFamily,
                        color: _themeColor.mainForeColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _openSetting,
                      icon: Icon(Icons.settings,color: _themeColor.mainForeColor.withValues(alpha: 0.6)),
                    ),
                  ],
                )
              ),
              _buildRecorder(),
              SizedBox(
                width: double.infinity,
                child: Text(_message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _themeColor.mainForeColor,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SingleChildScrollView(
                          child: _buildAudioList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]
          ),
        ),
      ]),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildRecorder() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 8),
      child: AspectRatio(
        aspectRatio: 1024 / 763,
        child: Stack(
          children: [
            Image.asset(_themeColor.mainRecorderBody),
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, 0.3),
                child: _buildRecordingListenable()
              )
            ),
            _buildSpinLeft(),
            _buildSpinRight(),
            _buildVolumeKnob(),
            _buildStopButton(),
            _buildRewindButton(),
            _buildPlayButton(),
            _buildRecButton(),
          ]
        )
      )
    );
  }

  Widget _buildRecordingListenable() {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _recorderController!.isRecording,
      builder: (_, recording, __) {
        if (!recording) {
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder<Duration>(
          valueListenable: _recorderController!.recordingElapsed,
          builder: (_, elapsed, __) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _format(elapsed),
                style: GoogleFonts.robotoMono(
                  fontSize: 18,
                  color: _themeColor.mainForeColor.withValues(alpha: 0.7),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpinLeft() {
    return Positioned.fill(
      child: Align(
        alignment: const Alignment(-0.445, -0.255),
        child: FractionallySizedBox(
          widthFactor: 106 / 1024,
          child: AnimatedBuilder(
            animation: _spinLeft,
            builder: (_, child) {
              return Transform.rotate(
                angle: _spinLeft.value * 2 * 3.141592 * _spinLeftDirection,
                child: child,
              );
            },
            child: Image.asset('assets/image/recorder_spin.png'),
          ),
        ),
      ),
    );
  }

  Widget _buildSpinRight() {
    return Positioned.fill(
      child: Align(
        alignment: const Alignment(0.445, -0.255),
        child: FractionallySizedBox(
          widthFactor: 106 / 1024,
          child: AnimatedBuilder(
            animation: _spinRight,
            builder: (_, child) {
              return Transform.rotate(
                angle: _spinRight.value * 2 * 3.141592 * _spinRightDirection,
                child: child,
              );
            },
            child: Image.asset('assets/image/recorder_spin.png'),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeKnob() {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment(_knobX, -1.02),
          child: FractionallySizedBox(
            widthFactor: 120 / 1024,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) {
                setState(() => _isDraggingVolume = true);
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _knobX += (details.delta.dx / screenWidth) * 2.8;
                  _knobX = _knobX.clamp(-0.77, 0.77);
                  _volume = (_knobX - (-0.77)) / (0.77 - (-0.77));
                  _recorderController?.setVolume(_volume);
                });
              },
              onHorizontalDragEnd: (_) {
                setState(() => _isDraggingVolume = false);
              },
              child: Image.asset(
                'assets/image/recorder_knob.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (_isDraggingVolume)
          Positioned(
            top: 20,
            child: Align(
              alignment: Alignment(_knobX, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_up, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "${(_volume * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStopButton() {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _recorderController!.isRewinding,
      builder: (_, isRewinding, __) {
        final enabled = !isRewinding;
        return Align(
          alignment: const Alignment(-0.973, 0.97),
          child: FractionallySizedBox(
            widthFactor: 242 / 1024,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: enabled
                ? (_) {
                  setState(() => _isStopPressed = true);
                  _recorderController?.stopRecording();
                  _recorderController?.stopPlay();
                }
                : null,
              onTapUp: enabled
                ? (_) {
                  setState(() => _isStopPressed = false);
                }
                : null,
              onTapCancel: enabled
                ? () {
                  setState(() => _isStopPressed = false);
                }
                : null,
              child: Image.asset(
                _isStopPressed
                  ? 'assets/image/recorder_stop.png'
                  : 'assets/image/recorder_transparent.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewindButton() {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _recorderController!.isRecording,
      builder: (_, isRecording, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: _recorderController!.isPlaying,
          builder: (_, isPlaying, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: _recorderController!.isRewinding,
              builder: (_, isRewinding, __) {
                final enabled = !isRecording && !isPlaying && !isRewinding;
                return Align(
                  alignment: const Alignment(-0.323, 0.97),
                  child: FractionallySizedBox(
                    widthFactor: 242 / 1024,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: enabled
                        ? (_) {
                          _recorderController?.rewind();
                        }
                        : null,
                      child: Image.asset(
                        isRewinding
                          ? 'assets/image/recorder_rewind.png'
                          : 'assets/image/recorder_transparent.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlayButton() {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _recorderController!.isRecording,
      builder: (_, isRecording, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: _recorderController!.isPlaying,
          builder: (_, isPlaying, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: _recorderController!.isRewinding,
              builder: (_, isRewinding, __) {
                final enabled = !(isRecording || isRewinding);
                final pressed = isPlaying;
                return Align(
                  alignment: const Alignment(0.327, 0.97),
                  child: FractionallySizedBox(
                    widthFactor: 242 / 1024,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: enabled
                        ? (_) async {
                          if (_recorderController!.isPlaying.value) {
                            _recorderController?.stopPlay();
                          } else {
                            if (Model.rewindEnabled) {
                              await _recorderController?.rewind();
                            }
                            _recorderController?.playLatest();
                          }
                        }
                        : null,
                      child: Image.asset(
                        pressed
                          ? 'assets/image/recorder_play.png'
                          : 'assets/image/recorder_transparent.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecButton() {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _recorderController!.isRecording,
      builder: (_, isRecording, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: _recorderController!.isPlaying,
          builder: (_, isPlaying, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: _recorderController!.isRewinding,
              builder: (_, isRewinding, __) {
                final enabled = !(isPlaying || isRewinding);
                final pressed = isRecording;
                return Align(
                  alignment: const Alignment(0.975, 0.97),
                  child: FractionallySizedBox(
                    widthFactor: 242 / 1024,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: enabled
                        ? (_) {
                          if (_recorderController!.isRecording.value) {
                            _recorderController?.stopRecording();
                          } else {
                            _recorderController?.startRecording();
                          }
                        }
                        : null,
                      child: Image.asset(
                        pressed
                          ? 'assets/image/recorder_rec.png'
                          : 'assets/image/recorder_transparent.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAudioList() {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<List<RecordedAudio>>(
      valueListenable: _recorderController!.audios,
      builder: (_, list, __) {
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(children:[
          Column(children: list.map((audio) => _buildAudioCard(audio)).toList()),
          const SizedBox(height: 200),
        ]);
      },
    );
  }

  Widget _buildAudioCard(RecordedAudio audio) {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      color: _themeColor.mainCardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: _themeColor.mainAccentForeColor2,
          width: 1,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 2),
        leading: _buildAudioCardLeading(),
        title: _buildAudioCardTitle(audio),
        trailing: _buildAudioCardTrailing(audio),
        onTap: () async {
          if (Model.rewindEnabled) {
            await _recorderController?.rewind();
          }
          _recorderController?.play(audio.path);
        },
      ),
    );
  }

  Widget _buildAudioCardLeading() {
    return SvgPicture.asset('assets/image/icon_cassette.svg',
      width: 24,
      colorFilter: ColorFilter.mode(
        _themeColor.mainAccentForeColor,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildAudioCardTitle(RecordedAudio audio) {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${DateFormat('yyyy-MM-dd HH:mm:ss').format(audio.createdAt)}\n${p.extension(audio.path)}  ${(audio.sizeBytes / 1000).ceil()} KB  ${audio.duration.inSeconds} sec.",
          style: GoogleFonts.orbitron(
            fontSize: t.bodyMedium?.fontSize,
            color: _themeColor.mainAccentForeColor,
          ),
        ),
        StreamBuilder<Duration>(
          stream: _recorderController?.player.positionStream,
          builder: (context, snapshot) {
            final pos = snapshot.data ?? Duration.zero;
            return StreamBuilder<Duration?>(
              stream: _recorderController?.player.durationStream,
              builder: (context, snapshot2) {
                final dur = snapshot2.data ?? Duration.zero;
                if (!_recorderController!.isPlaying.value ||
                    _recorderController?.currentPlayingPath != audio.path) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_format(pos)} / ${_format(dur)}",
                      style: GoogleFonts.robotoMono(
                        fontSize: t.bodyMedium?.fontSize,
                        color: _themeColor.mainAccentForeColor,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                        minThumbSeparation: 0,
                      ),
                      child: Slider(
                        value: (() {
                          final posMs = pos.inMilliseconds;
                          final durMs = dur.inMilliseconds;
                          final safePos = posMs > durMs ? durMs : posMs;
                          return safePos.toDouble();
                        })(),
                        min: 0,
                        max: dur.inMilliseconds.toDouble(),
                        activeColor: _themeColor.mainAccentForeColor,
                        inactiveColor: _themeColor.mainAccentForeColor.withValues(alpha: 0.3),
                        onChanged: (value) {
                          _recorderController?.player.seek(
                            Duration(milliseconds: value.toInt()),
                          );
                        },
                      ),
                    )
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAudioCardTrailing(RecordedAudio audio) {
    if (_recorderController == null) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: _themeColor.mainAccentForeColor),
      onSelected: (value) async {
        if (value == 'share') {
          _recorderController?.sendAudio(audio.id);
        } else if (value == 'delete') {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("delete?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text("Delete"),
                  ),
                ],
              );
            },
          );
          if (result == true) {
            _recorderController?.deleteAudio(audio.id);
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, color: _themeColor.mainAccentForeColor),
              const SizedBox(width: 8),
              Text("Share"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: _themeColor.mainAccentForeColor),
              const SizedBox(width: 8),
              Text("Delete"),
            ],
          ),
        ),
      ],
    );
  }

}
