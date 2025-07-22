import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../view_models/welcome_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<HomeScreen> {
  late WelcomeViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = WelcomeViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 45),
              // Header Text
              Center(
                child:
                    Text(
                          'PURE HD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .slideY(begin: -0.2, end: 0),
              ),
              Center(
                child:
                    Text(
                          'Audio',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .slideY(begin: -0.2, end: 0),
              ),

              const Spacer(),

              // Center 3D Model
              Expanded(
                flex: 12,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.transparent,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ModelViewer(
                      backgroundColor: Colors.transparent,
                      src: 'assets/models/headphones.glb', // Replace with your GLB file name
                      alt: 'A 3D model of headphones',
                      ar: true,
                      autoRotate: true,
                      iosSrc: 'assets/models/headphones.glb',
                      disableZoom: false,
                      cameraControls: true,
                      touchAction: TouchAction.panY,
                      interactionPrompt: InteractionPrompt.none,
                      autoPlay: true,
                      animationName: null,
                      cameraOrbit: "0deg 75deg 105%",
                      minCameraOrbit: "auto auto auto",
                      maxCameraOrbit: "auto auto auto",
                      shadowIntensity: 0,
                      exposure: 1.0,
                      shadowSoftness: 0,
                      environmentImage: null,
                      skyboxImage: null,
                      loading: Loading.eager,
                    ),
                  ),
                )
                .animate()
                .scale(begin: const Offset(0.5, 0.5))
                .fadeIn(duration: 1000.ms, delay: 400.ms),
              ),

              const SizedBox(height: 40),

              // Description Text
              const Text(
                    'Advance EQ for SX-839\n HiFi Wireless Headphones',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.5,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 800.ms)
                  .slideY(begin: 0.2, end: 0),

              const Spacer(),

              // Get Started Button
              ListenableBuilder(
                    listenable: viewModel,
                    builder: (context, child) {
                      return SizedBox(
                        width: MediaQuery.of(context).size.width * 0.82,
                        height: 65,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading
                              ? null
                              : () => viewModel.navigateToHome(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF191819),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            elevation: 2,
                            shadowColor: Colors.black,
                          ),
                          child: viewModel.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'ENTER EQ MODE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
                  )
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8))
                  .fadeIn(duration: 800.ms, delay: 1200.ms),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
