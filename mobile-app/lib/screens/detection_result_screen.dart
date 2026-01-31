import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_ui_components.dart';
import 'suggested_treatments_screen.dart';

/// Full-page detection result screen for online mode
class DetectionResultScreen extends StatefulWidget {
  final DetectionResult result;
  final String languageCode;

  const DetectionResultScreen({
    super.key,
    required this.result,
    required this.languageCode,
  });

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {
  final LocalizationService _localizationService = LocalizationService();
  String _languageCode = AppConstants.fallbackLanguageCode;
  Map<String, String> _strings = {};

  @override
  void initState() {
    super.initState();
    _languageCode = widget.languageCode;
    _loadLocalization();
  }

  Future<void> _loadLocalization() async {
    await _localizationService.loadAll();
    if (!mounted) return;
    setState(() {
      if (!_localizationService.hasLanguage(_languageCode)) {
        _languageCode = AppConstants.fallbackLanguageCode;
      }
      _strings = _localizationService.getPack(_languageCode)?.strings ?? {};
    });
  }

  String _t(String key) {
    return _strings[key] ?? _localizationService.translate(_languageCode, key);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final confidencePercent = (result.confidence * 100).toStringAsFixed(1);
    final isHighConfidence = result.confidence >= 0.85;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('detection_result'),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Result Card
              ModernCard(
                borderRadius: AppTheme.radiusXL,
                padding: const EdgeInsets.all(AppTheme.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Confidence badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _t('detection_result'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.charcoal,
                              ),
                        ),
                        StatusBadge(
                          label: '$confidencePercent%',
                          backgroundColor: isHighConfidence
                              ? AppTheme.successGreen.withOpacity(0.2)
                              : AppTheme.warningOrange.withOpacity(0.2),
                          textColor: isHighConfidence
                              ? AppTheme.successGreen
                              : AppTheme.warningOrange,
                          icon: isHighConfidence
                              ? Icons.check_circle
                              : Icons.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingL),
                    // Crop Info
                    InfoRow(
                      icon: Icons.agriculture,
                      label: _t('crop'),
                      value: result.crop,
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    // Disease Info
                    InfoRow(
                      icon: Icons.nature,
                      label: _t('disease'),
                      value: result.disease,
                      valueColor: AppTheme.dangerRed,
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    // Confidence Info
                    InfoRow(
                      icon: Icons.trending_up,
                      label: _t('confidence'),
                      value: '$confidencePercent%',
                      valueColor: isHighConfidence
                          ? AppTheme.successGreen
                          : AppTheme.warningOrange,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.paddingXXL),

              // Remedies Section
              SectionHeader(title: _t('remedies')),
              const SizedBox(height: AppTheme.paddingM),

              if (result.remedies.isEmpty)
                EmptyState(
                  icon: Icons.medical_services,
                  title: _t('no_remedies'),
                  subtitle: _t('contact_support'),
                  iconColor: AppTheme.accentGreen.withOpacity(0.4),
                )
              else
                ModernCard(
                  borderRadius: AppTheme.radiusXL,
                  padding: const EdgeInsets.all(AppTheme.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: result.remedies.asMap().entries.map((entry) {
                      final index = entry.key;
                      final remedy = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXL,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.paddingM),
                              Expanded(
                                child: Text(
                                  remedy,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.charcoal,
                                        height: 1.5,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if (index < result.remedies.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.paddingM,
                              ),
                              child: Divider(
                                color: AppTheme.dividerColor,
                                height: 1,
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: AppTheme.paddingXXL),

              // Action Buttons
              GradientButton(
                label: _t('treatment_options'),
                icon: Icons.medical_services,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SuggestedTreatmentsScreen(
                        disease: result.disease,
                        remedies: result.remedies,
                        languageCode: _languageCode,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.paddingM),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.paddingL,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                child: Text(_t('back_to_home')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
