import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/routes.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isHeaderVisible = true;
  bool _isFullscreen = false;
  Orientation? _previousOrientation;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    // Allow all orientations for voice composer
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Force portrait orientation when leaving voice composer
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _initializeWebView() {
    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading progress if needed
            },
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
              _addScrollListener();
            },
            onHttpError: (HttpResponseError error) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'HTTP Error: ${error.response?.statusCode}';
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Error loading page: ${error.description}';
              });
            },
          ),
        )
        ..loadRequest(Uri.parse('https://composer.silentsystem.com'));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  void _addScrollListener() {
    _webViewController.runJavaScript('''
      let isScrolling = false;
      let scrollTimer = null;
      let lastScrollY = window.scrollY;
      
      window.addEventListener('scroll', function() {
        if (!isScrolling) {
          isScrolling = true;
          window.flutter_inappwebview.callHandler('onScrollStart');
        }
        
        clearTimeout(scrollTimer);
        scrollTimer = setTimeout(function() {
          isScrolling = false;
          window.flutter_inappwebview.callHandler('onScrollEnd');
        }, 150);
        
        const currentScrollY = window.scrollY;
        if (Math.abs(currentScrollY - lastScrollY) > 5) {
          window.flutter_inappwebview.callHandler('onScroll', currentScrollY > lastScrollY);
          lastScrollY = currentScrollY;
        }
      });
    ''');

    _webViewController.addJavaScriptChannel(
      'flutter_inappwebview',
      onMessageReceived: (JavaScriptMessage message) {
        // Handle JavaScript messages if needed
      },
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      _isHeaderVisible = !_isFullscreen;
    });
  }

  void _refreshWebView() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final currentOrientation = MediaQuery.of(context).orientation;
    final screenHeight = MediaQuery.of(context).size.height;

    // Check if orientation changed from landscape to portrait
    if (_previousOrientation == Orientation.landscape && 
        currentOrientation == Orientation.portrait &&
        !_isHeaderVisible) {
      // Show header when returning from landscape to portrait
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isHeaderVisible = true;
          });
        }
      });
    }
    
    _previousOrientation = currentOrientation;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isFullscreen
            ? _buildFullscreenLayout(context)
            : (isLandscape
                  ? _buildLandscapeLayout(context)
                  : _buildPortraitLayout(context)),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Stack(
      children: [
        // WebView Container (fullscreen when header hidden)
        Positioned.fill(
          child: Container(
            margin: _isHeaderVisible
                ? const EdgeInsets.only(
                    top: 120,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  )
                : EdgeInsets.zero,
            decoration: _isHeaderVisible
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  )
                : null,
            child: ClipRRect(
              borderRadius: _isHeaderVisible
                  ? BorderRadius.circular(12)
                  : BorderRadius.zero,
              child: _buildWebViewContent(),
            ),
          ),
        ),

        // Header overlay (animated)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: _isHeaderVisible ? 0 : -120,
          left: 0,
          right: 0,
          height: 120,
          curve: Curves.easeInOut,
          child: Container(
            color: Colors.black,
            child: Column(
              children: [
                // Top bar with header and settings
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
                  child: Row(
                    children: [
                      // Back button
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          onPressed: () {
                            // Force portrait orientation before navigating back
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]).then((_) {
                              context.pop();
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // Flexible space for header
                      Expanded(
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/header.svg',
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: 50,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),

                      // Settings button
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          onPressed: () {
                            context.push(AppRoutes.settings);
                          },
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Voice Composer Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Text(
                    'Voice Composer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tap to toggle fullscreen (invisible overlay)
        if (!_isHeaderVisible)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isHeaderVisible = true;
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),

        // Error retry button
        if (_errorMessage != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _refreshWebView,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white30, width: 1),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 2,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Stack(
      children: [
        // WebView Container (fullscreen when header hidden)
        Positioned.fill(
          child: Container(
            margin: _isHeaderVisible
                ? const EdgeInsets.only(
                    top: 60,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  )
                : EdgeInsets.zero,
            decoration: _isHeaderVisible
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  )
                : null,
            child: ClipRRect(
              borderRadius: _isHeaderVisible
                  ? BorderRadius.circular(12)
                  : BorderRadius.zero,
              child: _buildWebViewContent(),
            ),
          ),
        ),

        // Header overlay (animated) - compact for landscape
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: _isHeaderVisible ? 0 : -60,
          left: 0,
          right: 0,
          height: 60,
          curve: Curves.easeInOut,
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () {
                    // Force portrait orientation before navigating back
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                      DeviceOrientation.portraitDown,
                    ]).then((_) {
                      context.pop();
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 8),

                // Compact header
                SvgPicture.asset(
                  'assets/images/header.svg',
                  width: 100,
                  height: 30,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),

                const SizedBox(width: 16),

                // Voice Composer title
                const Flexible(
                  child: Text(
                    'Voice Composer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                const Spacer(),

                // Settings button
                IconButton(
                  onPressed: () {
                    context.push(AppRoutes.settings);
                  },
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tap to toggle fullscreen (invisible overlay)
        if (!_isHeaderVisible)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isHeaderVisible = true;
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),

        // Error retry button
        if (_errorMessage != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _refreshWebView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white30, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWebViewContent() {
    if (_errorMessage != null) {
      return Container(
        color: Colors.grey.withOpacity(0.1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load Voice Composer',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onVerticalDragStart: (_) {
            // Hide header when scrolling starts
            if (_isHeaderVisible && !_isFullscreen) {
              setState(() {
                _isHeaderVisible = false;
              });
            }
          },
          child: WebViewWidget(
            controller: _webViewController,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
              ),
              Factory<HorizontalDragGestureRecognizer>(
                () => HorizontalDragGestureRecognizer(),
              ),
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            },
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.8),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Voice Composer...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFullscreenLayout(BuildContext context) {
    return Stack(
      children: [
        // Full screen WebView
        Positioned.fill(child: _buildWebViewContent()),

        // Tap to exit fullscreen (invisible overlay at top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isFullscreen = false;
                _isHeaderVisible = true;
              });
            },
            child: Container(color: Colors.transparent),
          ),
        ),

        // Exit fullscreen button (optional visible button)
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isFullscreen = false;
                  _isHeaderVisible = true;
                });
              },
              icon: const Icon(
                Icons.fullscreen_exit,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
