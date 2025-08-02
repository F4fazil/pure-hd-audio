import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeWebView();
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

  void _refreshWebView() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isLandscape ? _buildLandscapeLayout(context) : _buildPortraitLayout(context),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      children: [
        // Top bar with header and settings
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Back button
              SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: () {
                    context.pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms, delay: 200.ms)
                .scale(begin: const Offset(0.8, 0.8)),
              ),
              
              // Flexible space for header
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/header.svg',
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 70,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .slideY(begin: -0.2, end: 0),
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
                )
                .animate()
                .fadeIn(duration: 800.ms, delay: 200.ms)
                .scale(begin: const Offset(0.8, 0.8)),
              ),
            ],
          ),
        ),

        // Voice Composer Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: const Text(
            'Voice Composer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          )
          .animate()
          .fadeIn(duration: 800.ms, delay: 400.ms)
          .slideY(begin: 0.2, end: 0),
        ),

        const SizedBox(height: 20),

        // WebView Container
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildWebViewContent(),
            ),
          )
          .animate()
          .fadeIn(duration: 1000.ms, delay: 600.ms)
          .slideY(begin: 0.3, end: 0),
        ),

        const SizedBox(height: 20),

        // Refresh button (if error occurred)
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton(
              onPressed: _refreshWebView,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Colors.white30,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 2,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Column(
      children: [
        // Compact top bar for landscape
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: () {
                  context.pop();
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
                width: 120,
                height: 40,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Voice Composer title
              const Text(
                'Voice Composer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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

        // Full-height WebView Container for landscape
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildWebViewContent(),
            ),
          ),
        ),

        // Refresh button (if error occurred) - compact for landscape
        if (_errorMessage != null)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _refreshWebView,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(
                    color: Colors.white30,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 14),
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
              const Icon(
                Icons.error_outline,
                color: Colors.white54,
                size: 48,
              ),
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
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}