import 'package:flutter/foundation.dart';
import '../models/prediction.dart';

class PredictionProvider extends ChangeNotifier {
  final List<Prediction> _predictions = [];
  bool _isLoading = false;

  List<Prediction> get predictions => _predictions;
  bool get isLoading => _isLoading;

  // TODO: Load predictions from API
  Future<void> loadPredictions() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Fetch from API service
    _isLoading = false;
    notifyListeners();
  }

  Future<void> makePrediction(String challengeId, int value) async {
    // TODO: Submit prediction to API
    notifyListeners();
  }
}
