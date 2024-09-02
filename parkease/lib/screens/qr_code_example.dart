// qr_code_example.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeExample extends StatelessWidget {
  final String qrCode;

  QrCodeExample({required this.qrCode});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double qrSize = screenWidth * 0.5; // 50% of the screen width

    return Center(
      child: QrImageView(
        data: 'This is a simple QR code',
        version: QrVersions.auto,
        size: 200,
        gapless: false,
      ),
    );
  }
}
