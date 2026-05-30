import 'package:flutter/material.dart';
import 'package:haam_counter/models/counter_model.dart';
import 'package:haam_counter/theme/app_colors.dart';

class CounterProvider extends ChangeNotifier {
  CounterModel _model = CounterModel();

  CounterModel get model => _model;
  int get count => _model.count;
  CounterMode get mode => _model.mode;
  String get label => _model.label;

  static const int maxCount = 9999;
  static const int minCount = 0;

  void increment() {
    if (_model.count < maxCount) {
      _model = CounterModel(
        count: _model.count + 1,
        mode: _model.mode,
        createdAt: _model.createdAt,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void decrement() {
    if (_model.count > minCount) {
      _model = CounterModel(
        count: _model.count - 1,
        mode: _model.mode,
        createdAt: _model.createdAt,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void reset() {
    _model = CounterModel(mode: _model.mode);
    notifyListeners();
  }

  void switchMode(CounterMode newMode) {
    _model = CounterModel(
      count: _model.count,
      mode: newMode,
      createdAt: _model.createdAt,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  double get progress => _model.count / maxCount;

  Color get accentColor {
    switch (_model.mode) {
      case CounterMode.threats:
        return AppColors.alertRed;
      case CounterMode.protected:
        return AppColors.activeMint;
      case CounterMode.scan:
        return AppColors.safeBlue;
    }
  }
}
