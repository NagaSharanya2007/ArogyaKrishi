import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_service.dart';
import '../services/api_service.dart';
import '../services/offline_detector.dart';
import '../services/search_cache_service.dart';
import '../services/notification_service.dart';
import '../models/detection_result.dart';
import '../models/nearby_alert.dart';
import 'offline_detection_screen.dart';
import 'detection_result_screen.dart';
import 'chat_screen.dart';
import 'search_history_screen.dart';
import 'notification_inbox_screen.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_ui_components.dart';

/// Home screen with image capture/selection and preview
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImageService _imageService = ImageService();
  final ApiService _apiService = ApiService();
  final LocalizationService _localizationService = LocalizationService();

  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = true;
  String _languageCode = AppConstants.fallbackLanguageCode;
  Map<String, String> _strings = {};
  List<LanguagePack> _languagePacks = [];
  List<NearbyAlert> _nearbyAlerts = [];
  bool _isFetchingAlerts = false;
  bool _isLanguageDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initializeLanguage();
    _fetchNearbyAlerts();
    _registerDevice();
  }

  Future<void> _registerDevice({String? language}) async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return;

      final deviceToken = await _getDeviceToken();
      if (deviceToken == null || deviceToken.isEmpty) return;

      await _apiService.registerDevice(
        deviceToken: deviceToken,
        lat: position.latitude,
        lng: position.longitude,
        notificationsEnabled: true,
        language: language,
      );
    } catch (_) {
      // Silent fail for MVP registration
    }
  }

  Future<String?> _getDeviceToken() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id;
      }
      if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchNearbyAlerts() async {
    setState(() {
      _isFetchingAlerts = true;
    });

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        setState(() {
          _isFetchingAlerts = false;
          _nearbyAlerts = [];
        });
        return;
      }

      final response = await _apiService.getNearbyAlerts(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _isFetchingAlerts = false;
        _nearbyAlerts = response.alerts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetchingAlerts = false;
      });
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _initializeLanguage() async {
    await _localizationService.loadAll();
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(AppConstants.prefLanguageCode);
    final packs = _localizationService.languagePacks;
    if (!mounted) return;
    setState(() {
      _languagePacks = packs;
      if (savedCode != null && _localizationService.hasLanguage(savedCode)) {
        _languageCode = savedCode;
      } else if (!_localizationService.hasLanguage(_languageCode) &&
          packs.isNotEmpty) {
        _languageCode = packs.first.code;
      }
      _strings = _localizationService.getPack(_languageCode)?.strings ?? {};
    });

    if (savedCode != null && _localizationService.hasLanguage(savedCode)) {
      await _syncLanguageToServer(savedCode);
    }

    final hasChosen = prefs.getBool(AppConstants.prefLanguageChosen) ?? false;
    if (!hasChosen && packs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showLanguagePreferenceDialog();
        }
      });
    }
  }

  void _setLanguage(String code) {
    _applyLanguageSelection(code, markChosen: true);
  }

  Future<void> _applyLanguageSelection(
    String code, {
    bool markChosen = false,
  }) async {
    setState(() {
      _languageCode = code;
      _strings = _localizationService.getPack(_languageCode)?.strings ?? {};
    });

    await _persistLanguage(code, markChosen: markChosen);

    await _syncLanguageToServer(code);
  }

  Future<void> _persistLanguage(String code, {bool markChosen = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLanguageCode, code);
    if (markChosen) {
      await prefs.setBool(AppConstants.prefLanguageChosen, true);
    }
  }

  Future<void> _syncLanguageToServer(String code) async {
    await _registerDevice(language: code);
  }

  Future<void> _showLanguagePreferenceDialog() async {
    if (_isLanguageDialogOpen) return;
    _isLanguageDialogOpen = true;
    String selectedCode = _languageCode;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_t('select_language_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('select_language_body')),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      child: Column(
                        children: _languagePacks
                            .map(
                              (pack) => RadioListTile<String>(
                                value: pack.code,
                                groupValue: selectedCode,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(() {
                                    selectedCode = value;
                                  });
                                },
                                title: Text(pack.name),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Close dialog first
                    Navigator.of(context).pop();

                    // Then apply language selection
                    try {
                      await _applyLanguageSelection(
                        selectedCode,
                        markChosen: true,
                      );
                    } catch (e) {
                      // Silent fail - language is saved locally even if server sync fails
                    }
                  },
                  child: Text(_t('continue')),
                ),
              ],
            );
          },
        );
      },
    );

    _isLanguageDialogOpen = false;
  }

  String _t(String key) {
    return _strings[key] ?? _localizationService.translate(_languageCode, key);
  }

  String _tWithVars(String key, Map<String, String> vars) {
    var value = _t(key);
    vars.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }

  /// Check initial connectivity and listen for changes
  void _checkConnectivity() async {
    final isOnline = await OfflineDetector.isOnline();
    setState(() {
      _isOnline = isOnline;
    });

    // Listen for connectivity changes
    OfflineDetector.onConnectivityChanged.listen((isOnline) {
      setState(() {
        _isOnline = isOnline;
      });
    });
  }

  /// Show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(_t('take_photo')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(_t('choose_from_gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final image = await _imageService.pickFromCamera();

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showPermissionDialog();
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final image = await _imageService.pickFromGallery();

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showPermissionDialog();
    }
  }

  /// Show permission denied dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_t('permission_required')),
          content: Text(_t('permission_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _imageService.openSystemSettings();
              },
              child: Text(_t('open_settings')),
            ),
          ],
        );
      },
    );
  }

  /// Clear selected image
  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _errorMessage = null;
    });
  }

  /// Navigate to offline detection mode
  void _goToOfflineMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OfflineDetectionScreen(initialLanguageCode: _languageCode),
      ),
    );
  }

  /// Call backend API to detect disease from image
  Future<void> _detectDisease() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = _t('no_image_selected');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get device token for search history
      final deviceToken = await _getDeviceToken();

      // Get current position for location tracking
      final position = await _getCurrentPosition();

      final result = await _apiService.detectImage(
        imageFile: _selectedImage!,
        language: _languageCode,
        deviceToken: deviceToken,
        lat: position?.latitude,
        lng: position?.longitude,
      );

      // Cache the result locally with image
      await SearchCacheService.saveSearch(
        result: result,
        imageFile: _selectedImage,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      setState(() {
        _isLoading = false;
      });

      // Send detection notification
      if (result.disease.isNotEmpty) {
        await NotificationService.sendDetectionNotification(
          crop: result.crop,
          disease: result.disease,
          confidence: result.confidence,
          language: _languageCode,
        );
        setState(() {}); // Refresh to update badge count
      }

      // Show result screen
      if (mounted) {
        _showDetectionResult(result);
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = '${_t('error_detection_failed')}: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '${_t('unexpected_error')}: $e';
        _isLoading = false;
      });
    }
  }

  /// Show detection result in full page
  void _showDetectionResult(DetectionResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetectionResultScreen(result: result, languageCode: _languageCode),
      ),
    );
  }

  /// Get count of unread notifications
  Future<int> _getUnreadNotificationCount() async {
    try {
      final notifications = await NotificationService.getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (_) {
      return 0;
    }
  }

  /// Build a modern quick action card
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ModernCard(
      onTap: onTap,
      borderRadius: AppTheme.radiusXL,
      padding: const EdgeInsets.all(AppTheme.paddingXL),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 40, color: AppTheme.white),
          ),
          const SizedBox(height: AppTheme.paddingL),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.charcoal,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.paddingS),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('app_title'),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          // Notifications button with badge
          FutureBuilder<int>(
            future: _getUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationInboxScreen(),
                        ),
                      );
                    },
                    tooltip: _t('notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Language selector
          if (_languagePacks.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _setLanguage,
              tooltip: _t('select_language'),
              icon: const Icon(Icons.language),
              itemBuilder: (context) {
                return _languagePacks
                    .map(
                      (pack) => PopupMenuItem<String>(
                        value: pack.code,
                        child: Text(pack.name),
                      ),
                    )
                    .toList();
              },
            ),
          // AI Chat button (prominent)
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
            tooltip: _t('ai_assistant'),
          ),
          // More options menu
          PopupMenuButton<String>(
            tooltip: _t('more_options'),
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchHistoryScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'history',
                child: Row(
                  children: [
                    const Icon(Icons.history, color: AppTheme.primaryGreen),
                    const SizedBox(width: AppTheme.paddingM),
                    Text(_t('search_history')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Banner (if offline)
              if (!_isOnline)
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  color: AppTheme.warningOrange.withOpacity(0.15),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        color: AppTheme.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.paddingM),
                      Expanded(
                        child: Text(
                          _t('you_are_offline'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.warningOrange,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Nearby Alerts Banner
              if (!_isFetchingAlerts && _nearbyAlerts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  color: AppTheme.accentGreen.withOpacity(0.15),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.paddingM),
                      Expanded(
                        child: Text(
                          _tWithVars('nearby_alerts_body', {
                            'count': _nearbyAlerts.length.toString(),
                          }),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Main Content
              Padding(
                padding: const EdgeInsets.all(AppTheme.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Section
                    if (_selectedImage == null && _isOnline) ...[
                      Text(
                        _t('app_welcome_title'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.charcoal,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Text(
                        _t('app_welcome_subtitle'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingXL),
                    ],

                    // Error Message
                    if (_errorMessage != null) ...[
                      ModernCard(
                        backgroundColor: AppTheme.dangerRed.withOpacity(0.1),
                        border: Border.all(
                          color: AppTheme.dangerRed.withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.all(AppTheme.paddingM),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.dangerRed,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.paddingM),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.dangerRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingL),
                    ],

                    // Image Preview or Quick Actions
                    if (_selectedImage != null) ...[
                      ModernCard(
                        borderRadius: AppTheme.radiusXL,
                        padding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXL,
                              ),
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 350,
                                ),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Positioned(
                              top: AppTheme.paddingM,
                              right: AppTheme.paddingM,
                              child: GestureDetector(
                                onTap: _clearImage,
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    AppTheme.paddingS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: AppTheme.charcoal,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingXL),
                      GradientButton(
                        label: _isLoading
                            ? _t('detecting')
                            : _t('detect_disease'),
                        icon: _isLoading ? null : Icons.analytics,
                        onPressed: _isLoading ? () {} : _detectDisease,
                        isLoading: _isLoading,
                      ),
                    ] else ...[
                      // Quick Action Cards
                      if (_isOnline)
                        _buildQuickActionCard(
                          context,
                          icon: Icons.add_a_photo,
                          title: _t('scan_plant'),
                          subtitle: _t('take_photo_or_gallery'),
                          color: AppTheme.primaryGreen,
                          onTap: _showImageSourceDialog,
                        )
                      else
                        _buildQuickActionCard(
                          context,
                          icon: Icons.eco,
                          title: _t('offline_diagnosis'),
                          subtitle: _t('offline_diagnosis_subtitle'),
                          color: AppTheme.accentGreen,
                          onTap: _goToOfflineMode,
                        ),

                      const SizedBox(height: AppTheme.paddingL),

                      // Secondary Actions
                      if (_isOnline) ...[
                        Text(
                          _t('or'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.mediumGrey,
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.paddingL),
                        OutlinedButton.icon(
                          onPressed: _goToOfflineMode,
                          icon: const Icon(Icons.eco),
                          label: Text(_t('use_offline_mode')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.paddingL,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusM,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
