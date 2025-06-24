// lib/services/multi_account_manager.dart - UPDATED: Single Active Account Mode

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'sip_service.dart';

class AccountInfo {
  final String id;
  final String sipServer;
  final String username;
  final String password;
  final String domain;
  final int port;
  final String accountName;
  final String organization;
  final DateTime createdAt;
  
  AccountInfo({
    required this.id,
    required this.sipServer,
    required this.username,
    required this.password,
    required this.domain,
    required this.port,
    required this.accountName,
    required this.organization,
    required this.createdAt,
  });

  String get displayName => accountName.isNotEmpty ? accountName : username;
  String get identifier => '$username@$sipServer';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sipServer': sipServer,
      'username': username,
      'password': password,
      'domain': domain,
      'port': port,
      'accountName': accountName,
      'organization': organization,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      id: json['id'],
      sipServer: json['sipServer'],
      username: json['username'],
      password: json['password'],
      domain: json['domain'],
      port: json['port'],
      accountName: json['accountName'] ?? '',
      organization: json['organization'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MultiAccountManager extends ChangeNotifier {
  static const String _accountsKey = 'logged_in_accounts';
  static const String _activeAccountKey = 'active_account_id';

  final Map<String, SipService> _sipServices = {};
  final Map<String, AccountInfo> _accounts = {};
  String? _activeAccountId;
  bool _isInitialized = false;
  
  Timer? _statusUpdateTimer;

  // Getters
  Map<String, AccountInfo> get accounts => Map.unmodifiable(_accounts);
  String? get activeAccountId => _activeAccountId;
  AccountInfo? get activeAccount => _activeAccountId != null ? _accounts[_activeAccountId] : null;
  SipService? get activeSipService => _activeAccountId != null ? _sipServices[_activeAccountId] : null;
  bool get isInitialized => _isInitialized;
  bool get hasAccounts => _accounts.isNotEmpty;
  int get accountCount => _accounts.length;

  /// Get SipService for specific account
  SipService? getSipService(String accountId) => _sipServices[accountId];

  /// Get all SipServices
  Map<String, SipService> get allSipServices => Map.unmodifiable(_sipServices);

  /// Initialize multi-account manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔄 [MultiAccountManager] Initializing...');
    
    try {
      await _loadAccounts();
      await _initializeSipServices();
      _startStatusUpdateTimer();
      _isInitialized = true;
      
      print('✅ [MultiAccountManager] Initialized with ${_accounts.length} accounts');
      notifyListeners();
    } catch (e) {
      print('❌ [MultiAccountManager] Initialization failed: $e');
      rethrow;
    }
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      bool shouldNotify = false;
      
      for (final sipService in _sipServices.values) {
        if (sipService.hasListeners) {
          shouldNotify = true;
          break;
        }
      }
      
      if (shouldNotify) {
        notifyListeners();
      }
    });
    
    print('⏱️ [MultiAccountManager] Status update timer started');
  }

  /// Load accounts from SharedPreferences
  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load accounts
      final accountsJson = prefs.getString(_accountsKey);
      if (accountsJson != null) {
        final List<dynamic> accountsList = jsonDecode(accountsJson);
        for (final accountData in accountsList) {
          final account = AccountInfo.fromJson(accountData);
          _accounts[account.id] = account;
        }
      }

      // Load active account
      _activeAccountId = prefs.getString(_activeAccountKey);
      
      // Validate active account exists
      if (_activeAccountId != null && !_accounts.containsKey(_activeAccountId)) {
        _activeAccountId = null;
        await prefs.remove(_activeAccountKey);
      }

      // Set first account as active if none selected
      if (_activeAccountId == null && _accounts.isNotEmpty) {
        _activeAccountId = _accounts.keys.first;
        await _saveActiveAccount();
      }

      print('📂 [MultiAccountManager] Loaded ${_accounts.length} accounts');
      if (_activeAccountId != null) {
        print('🎯 [MultiAccountManager] Active account: ${_accounts[_activeAccountId]?.displayName}');
      }
    } catch (e) {
      print('❌ [MultiAccountManager] Error loading accounts: $e');
    }
  }

  /// Save accounts to SharedPreferences
  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsList = _accounts.values.map((account) => account.toJson()).toList();
      await prefs.setString(_accountsKey, jsonEncode(accountsList));
      print('💾 [MultiAccountManager] Saved ${_accounts.length} accounts');
    } catch (e) {
      print('❌ [MultiAccountManager] Error saving accounts: $e');
    }
  }

  /// Save active account to SharedPreferences
  Future<void> _saveActiveAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeAccountId != null) {
        await prefs.setString(_activeAccountKey, _activeAccountId!);
      } else {
        await prefs.remove(_activeAccountKey);
      }
      print('💾 [MultiAccountManager] Saved active account: $_activeAccountId');
    } catch (e) {
      print('❌ [MultiAccountManager] Error saving active account: $e');
    }
  }

  /// Initialize SipServices for all accounts (but don't connect them)
  Future<void> _initializeSipServices() async {
    for (final account in _accounts.values) {
      await _createSipService(account);
    }
  }

  /// Create and initialize SipService for an account
  Future<void> _createSipService(AccountInfo account) async {
    try {
      print('🔧 [MultiAccountManager] Creating SipService for ${account.displayName}');
      
      final sipService = SipService();
      await sipService.initialize();
      
      sipService.addListener(() {
        print('📡 [MultiAccountManager] SipService status changed for ${account.displayName}: ${sipService.status}');
        notifyListeners();
      });
      
      // Configure the service with account settings
      await sipService.saveSettings(
        account.sipServer,
        account.username,
        account.password,
        account.domain,
        account.port,
        accountName: account.accountName,
        organization: account.organization,
      );

      _sipServices[account.id] = sipService;
      print('✅ [MultiAccountManager] SipService created for ${account.displayName}');
    } catch (e) {
      print('❌ [MultiAccountManager] Error creating SipService for ${account.displayName}: $e');
    }
  }

  /// Add a new account
  Future<bool> addAccount({
    required String sipServer,
    required String username,
    required String password,
    required String domain,
    required int port,
    String? accountName,
    String? organization,
  }) async {
    try {
      // Check if account already exists
      final identifier = '$username@$sipServer';
      final existingAccount = _accounts.values.firstWhere(
        (account) => account.identifier == identifier,
        orElse: () => AccountInfo(
          id: '',
          sipServer: '',
          username: '',
          password: '',
          domain: '',
          port: 0,
          accountName: '',
          organization: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existingAccount.id.isNotEmpty) {
        print('⚠️ [MultiAccountManager] Account already exists: $identifier');
        return false;
      }

      // Create new account
      final accountId = DateTime.now().millisecondsSinceEpoch.toString();
      final newAccount = AccountInfo(
        id: accountId,
        sipServer: sipServer,
        username: username,
        password: password,
        domain: domain,
        port: port,
        accountName: accountName ?? '',
        organization: organization ?? '',
        createdAt: DateTime.now(),
      );

      // Add to accounts map
      _accounts[accountId] = newAccount;

      // Create SipService for new account
      await _createSipService(newAccount);

      // UPDATED: Disconnect current active account before setting new one
      if (_activeAccountId != null) {
        await _disconnectAccount(_activeAccountId!);
      }

      // Set as active account
      _activeAccountId = accountId;
      await _saveActiveAccount();

      // Save to storage
      await _saveAccounts();

      print('✅ [MultiAccountManager] Added new account: ${newAccount.displayName}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ [MultiAccountManager] Error adding account: $e');
      return false;
    }
  }

  /// Remove an account
  Future<bool> removeAccount(String accountId) async {
    try {
      final account = _accounts[accountId];
      if (account == null) return false;

      print('🗑️ [MultiAccountManager] Removing account: ${account.displayName}');

      // Stop and dispose SipService
      final sipService = _sipServices[accountId];
      if (sipService != null) {
        await sipService.unregister();
        sipService.dispose();
        _sipServices.remove(accountId);
      }

      // Remove from accounts
      _accounts.remove(accountId);

      // Update active account if necessary
      if (_activeAccountId == accountId) {
        _activeAccountId = _accounts.isNotEmpty ? _accounts.keys.first : null;
        await _saveActiveAccount();
        
        // UPDATED: Connect to new active account if exists
        if (_activeAccountId != null) {
          await _connectAccount(_activeAccountId!);
        }
      }

      // Save to storage
      await _saveAccounts();

      print('✅ [MultiAccountManager] Removed account: ${account.displayName}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ [MultiAccountManager] Error removing account: $e');
      return false;
    }
  }

  /// UPDATED: Switch active account with single-account logic
  Future<void> setActiveAccount(String accountId) async {
    if (!_accounts.containsKey(accountId)) {
      print('❌ [MultiAccountManager] Account not found: $accountId');
      return;
    }

    if (_activeAccountId == accountId) {
      print('ℹ️ [MultiAccountManager] Account already active: $accountId');
      return;
    }

    print('🔄 [MultiAccountManager] Switching account...');

    // STEP 1: Disconnect current active account
    if (_activeAccountId != null) {
      print('📤 [MultiAccountManager] Disconnecting current account: ${_accounts[_activeAccountId]?.displayName}');
      await _disconnectAccount(_activeAccountId!);
    }

    // STEP 2: Set new active account
    final oldAccountId = _activeAccountId;
    _activeAccountId = accountId;
    await _saveActiveAccount();

    // STEP 3: Connect new active account
    print('📥 [MultiAccountManager] Connecting new active account: ${_accounts[accountId]?.displayName}');
    await _connectAccount(accountId);

    final newAccount = _accounts[accountId]!;
    print('✅ [MultiAccountManager] Successfully switched to account: ${newAccount.displayName}');
    
    notifyListeners();
  }

  /// UPDATED: Connect only the active account
  Future<void> connectAllAccounts() async {
    print('🌐 [MultiAccountManager] Connecting active account...');
    
    if (_activeAccountId != null) {
      await _connectAccount(_activeAccountId!);
    } else {
      print('⚠️ [MultiAccountManager] No active account to connect');
    }
    
    notifyListeners();
  }

  /// NEW: Connect a specific account
  Future<void> _connectAccount(String accountId) async {
    final sipService = _sipServices[accountId];
    final account = _accounts[accountId];
    
    if (sipService != null && account != null) {
      try {
        print('🔌 [MultiAccountManager] Connecting ${account.displayName}...');
        await sipService.register();
        
        await Future.delayed(const Duration(milliseconds: 100));
        notifyListeners();
        
        print('✅ [MultiAccountManager] Connected ${account.displayName}');
      } catch (e) {
        print('❌ [MultiAccountManager] Failed to connect ${account.displayName}: $e');
      }
    }
  }

  /// NEW: Disconnect a specific account
  Future<void> _disconnectAccount(String accountId) async {
    final sipService = _sipServices[accountId];
    final account = _accounts[accountId];
    
    if (sipService != null && account != null) {
      try {
        print('📤 [MultiAccountManager] Disconnecting ${account.displayName}...');
        await sipService.unregister();
        
        await Future.delayed(const Duration(milliseconds: 100));
        notifyListeners();
        
        print('✅ [MultiAccountManager] Disconnected ${account.displayName}');
      } catch (e) {
        print('❌ [MultiAccountManager] Failed to disconnect ${account.displayName}: $e');
      }
    }
  }

  /// UPDATED: Disconnect all accounts
  Future<void> disconnectAllAccounts() async {
    print('🔌 [MultiAccountManager] Disconnecting all accounts...');
    
    for (final entry in _sipServices.entries) {
      await _disconnectAccount(entry.key);
    }
    
    notifyListeners();
  }

  /// Get account connection status summary
  Map<String, SipConnectionStatus> getConnectionStatuses() {
    final statuses = <String, SipConnectionStatus>{};
    for (final entry in _sipServices.entries) {
      statuses[entry.key] = entry.value.status;
    }
    return statuses;
  }

  /// Check if an account identifier already exists
  bool accountExists(String username, String sipServer) {
    final identifier = '$username@$sipServer';
    return _accounts.values.any((account) => account.identifier == identifier);
  }

  /// Force refresh UI
  void forceNotifyListeners() {
    notifyListeners();
  }

  @override
  void dispose() {
    print('🗑️ [MultiAccountManager] Disposing...');
    
    _statusUpdateTimer?.cancel();
    
    // Dispose all SipServices
    for (final sipService in _sipServices.values) {
      sipService.dispose();
    }
    _sipServices.clear();
    _accounts.clear();
    
    super.dispose();
  }
}