import 'package:flutter/material.dart';
import '../models/app_state.dart';

class BookPage extends StatelessWidget {
  final AppState appState;
  final double finalPageWidth;
  final double finalPageHeight;

  const BookPage({
    Key? key,
    required this.appState,
    required this.finalPageWidth,
    required this.finalPageHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Halaman saat ini (mode satu halaman)
    final pageIndex = appState.currentPageComplete;

    return Container(
      height: finalPageHeight,
      width: finalPageWidth,
      color: Colors.white,
      child: pageIndex < appState.pageImages.length
          ? Image.memory(
              appState.pageImages[pageIndex].bytes,
              fit: BoxFit.fill,
              gaplessPlayback: true,
            )
          : Container(
              color: Colors.grey.shade300,
              child: Center(
                child: Text(
                  'Loading...',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
    );
  }
}
