import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../view_models/equalizer_view_model.dart';
import '../services/global_eq_service.dart';
import '../core/routes.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  late EqualizerViewModel viewModel;
  final GlobalEQService _globalEQService = GlobalEQService.instance;

  @override
  void initState() {
    super.initState();
    viewModel = EqualizerViewModel();
    _initializeViewModel();
  }

  Future<void> _initializeViewModel() async {
    try {
      await viewModel.initialize(); // Load JSON presets
    } catch (e) {
      debugPrint('Error initializing equalizer: $e');
      // Show error to user but don't crash
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load equalizer settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Top bar with app name and settings
              Row(
                children: [
                  // Flexible space for header
                  Expanded(
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/header.svg',
                        width: MediaQuery.of(context).size.width * 0.5, // Reduced from 0.63 to 0.5
                        height: 80, // Reduced height from 100 to 80
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
                  // Settings and Voice buttons
                  Row(
                    children: [
                      // Voice button
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          onPressed: () {
                            context.push(AppRoutes.voice);
                          },
                          icon: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 200.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
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
                        .fadeIn(duration: 800.ms, delay: 250.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Control buttons row

              // EQ Sliders
              Expanded(
                    child: ListenableBuilder(
                      listenable: viewModel,
                      builder: (context, child) {
                        return Column(
                          children: [
                            // Frequency labels and sliders
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: List.generate(8, (index) {
                                  return Expanded(
                                    child: Column(
                                      children: [
                                        // +12dB label
                                        const Text(
                                          '+12',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Vertical Slider
                                        Expanded(
                                          child: RotatedBox(
                                            quarterTurns: -1,
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                trackHeight: 3,
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                      enabledThumbRadius: 8,
                                                    ),
                                                overlayShape:
                                                    const RoundSliderOverlayShape(
                                                      overlayRadius: 16,
                                                    ),
                                                activeTrackColor: Colors.white,
                                                inactiveTrackColor:
                                                    Colors.white24,
                                                thumbColor: Colors.white,
                                                overlayColor: Colors.white
                                                    .withValues(alpha: 0.1),
                                              ),
                                              child: Slider(
                                                value:
                                                    viewModel.bandValues[index],
                                                min: -12.0,
                                                max: 12.0,
                                                onChanged: viewModel.isEQOn
                                                    ? (value) => viewModel
                                                          .updateBandValue(
                                                            index,
                                                            value,
                                                          )
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 8),
                                        // -12dB label
                                        const Text(
                                          '-12',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Frequency label
                                        Text(
                                          viewModel.frequencyLabels[index],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 1000.ms, delay: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 30),

              // Presets section
              ListenableBuilder(
                    listenable: viewModel,
                    builder: (context, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Presets',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Preset buttons grid (8 presets in 2 rows of 4)
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.2,

                            children: List.generate(viewModel.presets.length, (
                              index,
                            ) {
                              final preset = viewModel.presets[index];
                              final isSelected =
                                  viewModel.currentPresetIndex == index;
                              return ElevatedButton(
                                onPressed: viewModel.isEQOn
                                    ? () => viewModel.applyPreset(index)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : const Color(0xFF191819),
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.black
                                          : Color(0xFF191819),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  elevation: isSelected ? 4 : 1,
                                ),
                                child: Text(
                                  preset.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 800.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: viewModel,
                builder: (context, child) {
                  return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Reset EQ Button
                          ElevatedButton(
                            onPressed: viewModel.resetEQ,
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
                              'Reset EQ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // EQ ON/OFF Toggle
                          ElevatedButton(
                            onPressed: viewModel.toggleEQ,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: viewModel.isEQOn
                                  ? Colors.black
                                  : Color(0xFF191819),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: viewModel.isEQOn
                                      ? Colors.grey
                                      : Color(0xFF191819),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              viewModel.isEQOn ? 'EQ ON' : 'EQ OFF',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 400.ms)
                      .slideY(begin: 0.3, end: 0);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
