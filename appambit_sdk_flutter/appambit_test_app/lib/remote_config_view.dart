import 'package:flutter/material.dart';
import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';

class RemoteConfigView extends StatefulWidget {
  final bool isActive;
  const RemoteConfigView({super.key, this.isActive = false});

  @override
  State<RemoteConfigView> createState() => _RemoteConfigViewState();
}

class _RemoteConfigViewState extends State<RemoteConfigView> {
  String _data = "Loading...";
  bool _showBanner = false;
  int _discount = 0;
  double _maxUpload = 0.0;
  bool _isLoading = true;
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _fetchConfig();
    }
  }

  @override
  void didUpdateWidget(RemoteConfigView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_hasFetched) {
      _fetchConfig();
    }
  }

  Future<void> _fetchConfig() async {
    // Get values
    final data = await AppAmbitSdk.getString("data");
    final showBanner = await AppAmbitSdk.getBoolean("banner");
    final discount = await AppAmbitSdk.getLong("discount");
    final maxUpload = await AppAmbitSdk.getDouble("max_upload");

    if (mounted) {
      setState(() {
        _data = (data != null && data.isNotEmpty) ? data : "You're without Remote values";
        _showBanner = showBanner;
        _discount = discount;
        _maxUpload = maxUpload;
        _isLoading = false;
        _hasFetched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        color: const Color.fromARGB(255, 255, 255, 255),
        padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showBanner) _buildBannerCard(),
            const SizedBox(height: 24),
            _buildMessageCard(),
            const SizedBox(height: 24),
            if (_discount > 0) _buildDiscountCard(),
            if (_discount > 0) const SizedBox(height: 24),
            _buildUploadLimitCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: const Color(0xFFF66A0A),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: const Color(0xFFC34700),
              child: const Text(
                "NEW FEATURE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Discover what we have prepared for you in this new update enabled by Remote Config.",
              style: TextStyle(
                color: Color(0xFFE3F2FD),
                fontSize: 14,
                height: 1.5, // lineSpacingExtra equivalent approx
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "MESSAGE OF THE DAY",
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _data,
              style: const TextStyle(
                color: Color(0xFF212121),
                fontSize: 18,
                height: 1.2,
                fontWeight: FontWeight.w500, // sans-serif-medium approximate
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SPECIAL OFFER",
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.1,
                  ),
                ),
                SizedBox(height: 4),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "$_discount% OFF",
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadLimitCard() {
    final uploadText = _maxUpload > 0
        ? "${_maxUpload.toStringAsFixed(1)} MB"
        : "100 MB";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "UPLOAD LIMIT",
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Max file size allowed:",
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  uploadText,
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
