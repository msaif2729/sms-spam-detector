import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/prediction_result.dart';
import '../services/api_service.dart';
import '../services/sms_service.dart';
import '../theme/app_theme.dart';
import '../widgets/result_card.dart';
import '../widgets/sample_chips.dart';
import '../widgets/settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final SmsService _smsService = SmsService();

  bool _isLoading = false;
  PredictionResult? _currentResult;
  final List<PredictionResult> _history = [];

  // Device SMS Inbox State
  bool _isLoadingInbox = false;
  List<DeviceSmsItem> _inboxMessages = [];
  String? _inboxError;

  // Filter tab for Inbox: 0=All, 1=Spam, 2=Ham
  int _inboxFilterIndex = 0;
  String _searchQuery = '';
  StreamSubscription<DeviceSmsItem>? _smsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to live incoming SMS broadcast on Android
    if (!kIsWeb) {
      _loadDeviceInbox();

      _smsSubscription = _smsService.listenToIncomingSms().listen((smsItem) {
        if (mounted) {
          setState(() {
            _inboxMessages.removeWhere((item) =>
                item.sender == smsItem.sender && item.body == smsItem.body);
            _inboxMessages.insert(0, smsItem);
          });
          if (smsItem.result.isSpam) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Live Incoming Spam Intercepted from ${smsItem.sender}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.spamRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    _tabController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _analyzeMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter or select an SMS message first.'),
          backgroundColor: AppTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.predictSMS(text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentResult = result;
        _history.insert(0, result);
      });
    }
  }

  Future<void> _loadDeviceInbox() async {
    setState(() {
      _isLoadingInbox = true;
      _inboxError = null;
    });

    final items = await _smsService.fetchAndAnalyzeInbox(limit: 50);

    if (mounted) {
      setState(() {
        _isLoadingInbox = false;
        _inboxMessages = items;
        if (items.isEmpty) {
          _inboxError =
              'No SMS messages found or SMS permission was denied. Tap button above to grant permission or refresh.';
        }
      });
    }
  }

  void _openModelInfo() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalInbox = _inboxMessages.length;
    final spamInboxCount =
        _inboxMessages.where((item) => item.result.isSpam).length;
    final hamInboxCount =
        _inboxMessages.where((item) => !item.result.isSpam).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090D16), // Deepest obsidian background
              Color(0xFF0F172A),
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Futuristic Glass App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'SMS Shield AI',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textLight,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppTheme.hamGreen,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.hamGreen.withOpacity(0.8),
                                            blurRadius: 6,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Live ONNX Engine • Privacy Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: IconButton(
                        onPressed: _openModelInfo,
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        color: AppTheme.primaryLight,
                        tooltip: 'ONNX Model Specs',
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Tab Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    dividerHeight: 0.0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Manual Scan'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mark_email_unread_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Device Inbox'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildManualScanTab(),
                    _buildDeviceInboxTab(
                      totalInbox,
                      spamInboxCount,
                      hamInboxCount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualScanTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),

          // Input Box Container Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.borderDark),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.edit_note_rounded,
                              color: AppTheme.primaryLight, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'SMS Content Analysis',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      if (_messageController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _messageController.clear();
                              _currentResult = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.spamRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Clear Text',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.spamRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14.5, height: 1.4),
                    decoration: const InputDecoration(
                      hintText:
                          'Paste or type an SMS message to check for spam, phishing links, or suspicious patterns...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SampleChips(
                    onSelectSample: (content) {
                      setState(() {
                        _messageController.text = content;
                      });
                      _analyzeMessage();
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Primary CTA Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _analyzeMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                elevation: 6,
                shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 14),
                        Text('Evaluating ONNX Model...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shield_outlined, size: 22),
                        SizedBox(width: 10),
                        Text('Scan SMS for Spam & Phishing'),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Prediction Output Card
          if (_currentResult != null) ...[
            ResultCard(result: _currentResult!),
            const SizedBox(height: 24),
          ],

          // History Section
          if (_history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.history_rounded,
                        size: 18, color: AppTheme.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Scan History',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Text(
                    '${_history.length} scans',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length > 5 ? 5 : _history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _history[index];
                final isSpam = item.isSpam;
                final statusColor = isSpam ? AppTheme.spamRed : AppTheme.hamGreen;

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSpam
                          ? statusColor.withOpacity(0.3)
                          : AppTheme.borderDark,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSpam
                            ? Icons.gpp_bad_rounded
                            : Icons.verified_user_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        item.prediction.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _messageController.text = item.message;
                        _currentResult = item;
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceInboxTab(
    int total,
    int spamCount,
    int hamCount,
  ) {
    final filtered = _inboxMessages.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.sender.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.body.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_inboxFilterIndex == 1) return item.result.isSpam;
      if (_inboxFilterIndex == 2) return !item.result.isSpam;
      return true;
    }).toList();

    return Column(
      children: [
        // Top Header & Control Center
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Device SMS Monitor',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        Text(
                          'Real-time receiver & classifier',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoadingInbox ? null : _loadDeviceInbox,
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: Text(_inboxMessages.isEmpty ? 'Scan Inbox' : 'Rescan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_inboxMessages.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildStatCard('Total SMS', '$total', AppTheme.primaryLight),
                    const SizedBox(width: 8),
                    _buildStatCard('Spam Flagged', '$spamCount', AppTheme.spamRed),
                    const SizedBox(width: 8),
                    _buildStatCard('Legitimate', '$hamCount', AppTheme.hamGreen),
                  ],
                ),
                const SizedBox(height: 12),

                // Instant Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by sender or message content...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Pill Bar
                Row(
                  children: [
                    _buildFilterChip('All (${_inboxMessages.length})', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('🚨 Spam ($spamCount)', 1),
                    const SizedBox(width: 8),
                    _buildFilterChip('✅ Clean ($hamCount)', 2),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Message List State View
        Expanded(
          child: _isLoadingInbox
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(color: AppTheme.primaryLight),
                      SizedBox(height: 16),
                      Text(
                        'Reading device SMS & executing ONNX engine...',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : _inboxError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sms_failed_rounded,
                                size: 52, color: AppTheme.warningOrange),
                            const SizedBox(height: 14),
                            Text(
                              _inboxError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _inboxMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inbox_rounded,
                                  size: 52, color: AppTheme.textMuted),
                              SizedBox(height: 14),
                              Text(
                                'Tap "Scan Inbox" above to analyze your SMS messages',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final smsItem = filtered[index];
                            final isSpam = smsItem.result.isSpam;
                            final statusColor =
                                isSpam ? AppTheme.spamRed : AppTheme.hamGreen;

                            return Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSpam
                                      ? statusColor.withOpacity(0.4)
                                      : AppTheme.borderDark,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: statusColor.withOpacity(0.15),
                                  child: Icon(
                                    isSpam
                                        ? Icons.gpp_bad_rounded
                                        : Icons.verified_user_rounded,
                                    color: statusColor,
                                    size: 22,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        smsItem.sender,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: statusColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        isSpam ? 'SPAM' : 'HAM',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(
                                      smsItem.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textLight,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Received: ${smsItem.date.toString().substring(0, 16)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _messageController.text = smsItem.body;
                                    _currentResult = smsItem.result;
                                    _tabController.animateTo(0);
                                  });
                                },
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _inboxFilterIndex == index;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppTheme.textMuted,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceDark,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryLight : AppTheme.borderDark,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _inboxFilterIndex = index;
          });
        }
      },
    );
  }
}
