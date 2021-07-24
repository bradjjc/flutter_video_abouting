import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';




class Gesture extends StatefulWidget {
  const Gesture({Key key}) : super(key: key);

  @override
  _GestureState createState() => _GestureState();
}

class _GestureState extends State<Gesture> {
  int index = 0;
  double _position = 0;
  double _buffer = 0;
  bool _lock = true;
  Map<String, VideoPlayerController> _controllers = {};
  Map<int, VoidCallback> _listeners = {};
  List<String> _urls = [
    'https://player.vimeo.com/external/572759990.sd.mp4?s=614bf1a09d2d27332f09df9ceddbc40edef23028&profile_id=165',
    'https://player.vimeo.com/external/572759932.hd.mp4?s=569906e8f424a0886822ef212426dde70151032b&profile_id=174',
    'https://player.vimeo.com/external/572759911.sd.mp4?s=fd2d17fef26ef5f98591810e3619481ff24b6dba&profile_id=165',
    'https://player.vimeo.com/external/572759882.sd.mp4?s=86d3d03191846b55a9708e59572e6dc9f4d9c1e9&profile_id=165',
    'https://player.vimeo.com/external/572759855.sd.mp4?s=ea38614b4bb11e5398d0e4bc9ede1abd59cbf047&profile_id=165',
    'https://player.vimeo.com/external/572759842.sd.mp4?s=61e4fd3e851bf4d357840c93bf73f9f9b279be12&profile_id=165',
    'https://player.vimeo.com/external/572759798.sd.mp4?s=101f06f0732302d09da52b15eb6b614611052a5c&profile_id=165',
    'https://player.vimeo.com/external/572759759.sd.mp4?s=fbd31573434450d83d99014d1cfd2ee781c3443d&profile_id=165',
  ];


  @override
  void initState() {
    super.initState();
    if (_urls.length > 0) {
      _initController(0).then((_) {
        _playController(0);
      });
    }


    if (_urls.length > 1) {
      _initController(1).whenComplete(() => _lock = false);
    }
  }

  VoidCallback _listenerSpawner(index) {
    return () {
      int dur = _controller(index).value.duration.inMilliseconds;
      int pos = _controller(index).value.position.inMilliseconds;
      int buf = _controller(index).value.buffered.last.end.inMilliseconds;

      setState(() {
        if (dur <= pos) {
          _position = 0;
          return;
        }
        _position = pos / dur;
        _buffer = buf / dur;
      });
      if (dur - pos < 1) {
        if (index < _urls.length - 1) {
          _nextVideo();
        }
      }
    };
  }

  VideoPlayerController _controller(int index) {
    return _controllers[_urls.elementAt(index)];
  }

  Future<void> _initController(int index) async {
    var controller = VideoPlayerController.network(_urls.elementAt(index),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controllers[_urls.elementAt(index)] = controller;
    await controller.initialize();
  }

  void _removeController(int index) {
    _controller(index).dispose();
    _controllers.remove(_urls.elementAt(index));
    _listeners.remove(index);
  }

  void _stopController(int index) {
    _controller(index).removeListener(_listeners[index]);
    _controller(index).pause();
    _controller(index).seekTo(Duration(milliseconds: 0));
  }

  void _playController(int index) async {
    if (!_listeners.keys.contains(index)) {
      _listeners[index] = _listenerSpawner(index);
    }
    _controller(index).addListener(_listeners[index]);
    await _controller(index).play();
    setState(() {});
  }

  void _previousVideo() {
    if (_lock || index == 0) {
      return;
    }
    _lock = true;

    _stopController(index);

    if (index + 1 < _urls.length) {
      _removeController(index + 1);
    }

    _playController(--index);

    if (index == 0) {
      _lock = false;
    } else {
      _initController(index - 1).whenComplete(() => _lock = false);
    }
  }

  void _nextVideo() async {
    if (_lock || index == _urls.length - 1) {
      return;
    }
    _lock = true;

    _stopController(index);

    if (index - 1 >= 0) {
      _removeController(index - 1);
    }

    _playController(++index);

    if (index == _urls.length - 1) {
      _lock = false;
    } else {
      _initController(index + 1).whenComplete(() => _lock = false);
    }
  }

  void _onHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity.compareTo(0) == -1) {
      _nextVideo();
      // print('dragged from left');
    }
    else {
      _previousVideo();
    }  // print('dragged from right');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onHorizontalDragEnd: (DragEndDetails details) => _onHorizontalDrag(details),
            onLongPressStart: (_) => _controller(index).pause(),
            onLongPressEnd: (_) => _controller(index).play(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: AspectRatio(
                aspectRatio: _controller(index).value.aspectRatio,
                child: Center(child: VideoPlayer(_controller(index))),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
              onPressed: _previousVideo, child: Icon(Icons.arrow_back)),
          SizedBox(width: 24),
          FloatingActionButton(
              onPressed: _nextVideo, child: Icon(Icons.arrow_forward)),
        ],
      ),
    );

  }

}
