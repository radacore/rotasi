import 'package:flutter/material.dart';
import '../models/app_state.dart';

class AnimatedPage extends StatelessWidget {
  final AppState appState;
  final Animation<double> rotationAnimation;
  final double finalPageWidth;
  final double finalPageHeight;

  const AnimatedPage({
    Key? key,
    required this.appState,
    required this.rotationAnimation,
    required this.finalPageWidth,
    required this.finalPageHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final swipeLeft = appState.isSwipingLeft;

    return Align(
      alignment:
          swipeLeft ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: rotationAnimation,
        builder: (context, child) {
          double rotationValue = rotationAnimation.value;
          bool isFront = rotationValue <= 0.5;

          /// Halaman muka = halaman saat ini; balikannya = halaman tetangga
          final frontPageIndex = appState.currentPageComplete;
          final backPageIndex = swipeLeft
              ? appState.currentPageComplete + 1
              : appState.currentPageComplete - 1;

          final hasFrontPage =
              frontPageIndex >= 0 && frontPageIndex < appState.pageImages.length;
          final hasBackPage =
              backPageIndex >= 0 && backPageIndex < appState.pageImages.length;

          return Transform(
            alignment:
                swipeLeft ? Alignment.centerRight : Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0004)
              ..rotateY(swipeLeft
                  ? rotationValue * 3.14
                  : -rotationValue * 3.14),
            child: Stack(
              children: [
                Container(
                  height: finalPageHeight,
                  width: finalPageWidth,
                  color: Colors.white,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(isFront ? 0 : 3.14),
                    child: (isFront ? hasFrontPage : hasBackPage)
                        ? Image.memory(
                            appState
                                .pageImages[isFront
                                    ? frontPageIndex
                                    : backPageIndex]
                                .bytes,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: Center(
                              child: Text(
                                'Loading...',
                                style:
                                    TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                  ),
                ),
                /// Bayangan sisi lipatan
                Align(
                  alignment: swipeLeft
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: 24,
                    height: finalPageHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
