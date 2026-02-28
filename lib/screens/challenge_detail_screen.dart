import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/theme.dart';
import '../config/routes.dart';
import '../controllers/tts_controller.dart';
import '../models/map_place_detail.dart';
import '../services/map_places_repository.dart';
import '../services/api_service.dart';
import '../providers/challenge_provider.dart';
import '../widgets/challenge/challenge_header.dart';
import '../widgets/challenge/challenge_info_section.dart';
import '../widgets/challenge/challenge_reviews_section.dart';
import '../widgets/challenge/tts_listen_button.dart';

/// Challenge/place detail screen. Fetches data by [placeId] from the repository.
///
/// Opened when the user taps a map marker or "View details" on the map place card.
/// Uses the same repository pattern as the map; swap repository implementation
/// for real API when backend is ready.
class ChallengeDetailScreen extends StatefulWidget {
  /// Place/challenge id; from route arguments when navigated from map.
  final String? placeId;

  const ChallengeDetailScreen({super.key, this.placeId});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final MapPlacesRepository _repository =
      ApiMapPlacesRepository(ApiService());

  MapPlaceDetail? _detail;
  bool _loading = true;
  String? _error;

  late final TtsController _ttsController;

  @override
  void initState() {
    super.initState();
    _ttsController = createDefaultTtsController();
    _ttsController.addListener(_onTtsStateChanged);
    _loadDetail();
  }

  void _onTtsStateChanged() {
    if (_ttsController.state == TtsState.error &&
        _ttsController.errorMessage != null &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ttsController.errorMessage!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ttsController.removeListener(_onTtsStateChanged);
    _ttsController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final id = widget.placeId;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No challenge selected';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _detail = null;
    });

    try {
      final detail = await _repository.getPlaceDetailById(id);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _detail = detail;
        if (detail == null) _error = 'Challenge not found';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.secondaryColor,
          title: const Text('Challenge'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_error != null || _detail == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.secondaryColor,
          title: const Text('Challenge'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final detail = _detail!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            foregroundColor: AppTheme.secondaryColor,
            title: Text(
              detail.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ChallengeHeader(detail: detail),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          detail.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TtsListenButton(
                        controller: _ttsController,
                        text: detail.description,
                        showLabel: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ChallengeInfoSection(detail: detail),
                  const SizedBox(height: 24),
                  ChallengeReviewsSection(detail: detail),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null && widget.placeId != null) {
                          final provider = context.read<ChallengeProvider>();
                          await provider.acceptChallenge(widget.placeId!, userId);
                        }
                        if (mounted && widget.placeId != null) {
                          Navigator.of(context).pushNamed(
                            AppRoutes.challengeHub,
                            arguments: {
                              'challengeId': widget.placeId,
                              'challengeTitle': detail.title,
                            },
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Join Challenge'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Placeholder: Navigate / Open in maps
                      },
                      icon: const Icon(Icons.directions, size: 20),
                      label: const Text('Navigate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondaryColor,
                        side: const BorderSide(color: AppTheme.secondaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
