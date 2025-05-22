import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:ivy_path/models/subject_model.dart';
import 'package:ivy_path/services/subject_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ConnectionStatus {
  online,
  offline,
}

enum LoadingStatus {
  initial,
  loading,
  loaded,
  error,
}

class PracticeConfigProvider extends ChangeNotifier {
  final SubjectService _subjectService;
  final Connectivity _connectivity;
  StreamSubscription? _connectivitySubscription;

  ConnectionStatus _connectionStatus = ConnectionStatus.online;
  LoadingStatus _loadingStatus = LoadingStatus.initial;
  List<Subject> _subjects = [];
  String _errorMessage = '';

  PracticeConfigProvider({
    required SubjectService subjectService,
    Connectivity? connectivity,
  }) : _subjectService = subjectService,
       _connectivity = connectivity ?? Connectivity() {
    _initConnectivity();
    _setupConnectivityListener();
    loadSubjects();
  }

  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  LoadingStatus get loadingStatus => _loadingStatus;
  List<Subject> get subjects => _subjects;
  String get errorMessage => _errorMessage;

  // Initialize connectivity
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      _connectionStatus = ConnectionStatus.offline;
    }
  }

  // Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
      // Reload subjects when coming back online
      if (_connectionStatus == ConnectionStatus.online && 
          (_loadingStatus == LoadingStatus.initial || _loadingStatus == LoadingStatus.error)) {
        loadSubjects();
      }
    });
  }

  // Update connection status based on connectivity result
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _connectionStatus = ConnectionStatus.offline;
    } else {
      _connectionStatus = ConnectionStatus.online;
    }
    notifyListeners();
  }

  // Load subjects based on connection status
  Future<void> loadSubjects() async {
    _loadingStatus = LoadingStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // Check actual internet connectivity with a ping
      bool hasInternet = await _checkInternetConnection();
      if (hasInternet) {
        // Online: Get from API
        _subjects = await _subjectService.getSubjects();
      } else {
        // Offline: Get from Hive
        final subjectsBox = await Hive.openBox<Subject>('subjects');
        _subjects = subjectsBox.values.toList();
        
        if (_subjects.isEmpty) {
          throw Exception('No cached subjects available offline');
        }
      }
      
      _loadingStatus = LoadingStatus.loaded;
    } catch (e) {
      _loadingStatus = LoadingStatus.error;
      _errorMessage = e.toString();
    }
    
    notifyListeners();
  }

  // Check if device has actual internet connection
  Future<bool> _checkInternetConnection() async {
    if (_connectionStatus == ConnectionStatus.offline) {
      return false;
    }
    
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Refresh subjects (force reload from API if online)
  Future<void> refreshSubjects() async {
    await loadSubjects();
  }

  // Clean up
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
