import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;

/// Static JS interop for toggling fullscreen.
@JS('toggleFullscreen')
external void toggleFullscreen();

/// Static JS interop for entering fullscreen.
@JS('enterFullscreen')
external void enterFullscreen();

/// Static JS interop for exiting fullscreen.
@JS('exitFullscreen')
external void exitFullscreen();

void main() {
  _injectFullscreenScripts();
  runApp(const MyApp());
}

/// Injects a script element into the document head that defines three global JS functions.
void _injectFullscreenScripts() {
  final script = html.ScriptElement()
    ..text = '''
      window.toggleFullscreen = function() {
        if (!document.fullscreenElement) {
          document.documentElement.requestFullscreen();
        } else {
          document.exitFullscreen();
        }
      };
      window.enterFullscreen = function() {
        if (!document.fullscreenElement) {
          document.documentElement.requestFullscreen();
        }
      };
      window.exitFullscreen = function() {
        if (document.fullscreenElement) {
          document.exitFullscreen();
        }
      };
    ''';
  html.document.head?.append(script);
}

/// Entrypoint of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Flutter Demo', home: HomePage());
  }
}

/// [HomePage] displays the image area with a URL input and also includes the plus button with context menu.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  late html.ImageElement _imageElement;
  bool _imageLoaded = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();

    // Create and configure the HTML <img> element.
    _imageElement = html.ImageElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain';

    // Register the <img> element with the platform view registry.
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'my-image',
      (int viewId) => _imageElement,
    );
  }

  /// Toggles fullscreen via the JS interop function.
  void _toggleFullScreen() {
    toggleFullscreen();
  }

  /// Updates the <img> element's source URL and shows the image.
  void _updateImage() {
    final url = _controller.text;
    _imageElement.src = url;
    setState(() {
      _imageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content using a Scaffold.
        Scaffold(
          appBar: AppBar(),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _imageLoaded
                        // Wrap the HTML image in a GestureDetector to catch double-tap.
                        ? GestureDetector(
                            onDoubleTap: _toggleFullScreen,
                            child: const HtmlElementView(viewType: 'my-image'),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // URL input field and button.
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration:
                            const InputDecoration(hintText: 'Image URL'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _updateImage,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Icon(Icons.arrow_forward),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),

        // When the context menu is open, show a full-screen modal barrier that dims the background.
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isMenuOpen = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),

        // Floating Plus button (positioned at the bottom-right).
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _isMenuOpen = !_isMenuOpen;
              });
            },
            child: const Icon(Icons.add),
          ),
        ),

        // The context menu, shown above the Plus button when open.
        if (_isMenuOpen)
          Positioned(
            bottom: 80, // Positioned above the FAB.
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      enterFullscreen();
                      setState(() {
                        _isMenuOpen = false;
                      });
                    },
                    child: const Text("Enter fullscreen"),
                  ),
                  TextButton(
                    onPressed: () {
                      exitFullscreen();
                      setState(() {
                        _isMenuOpen = false;
                      });
                    },
                    child: const Text("Exit fullscreen"),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
