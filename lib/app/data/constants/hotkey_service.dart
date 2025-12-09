import 'dart:io';
import 'package:account_book/app/screens/home/reports/balance_sheet.dart';
import 'package:account_book/app/screens/home/reports/item_ledger.dart';
import 'package:account_book/app/screens/home/reports/profit_loss.dart';
import 'package:account_book/app/screens/transactions/purchase/create_purchase.dart';
import 'package:account_book/app/screens/transactions/sales/create_sale.dart';
import 'package:account_book/app/screens/yarima_wallet/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyManagerService {
  // Singleton instance
  static final HotkeyManagerService _instance =
      HotkeyManagerService._internal();

  // Factory constructor to return the singleton instance
  factory HotkeyManagerService() {
    return _instance;
  }

  // Private constructor for singleton
  HotkeyManagerService._internal();

  // Class properties
  BuildContext? _context;
  List<HotKey> _registeredHotkeys = [];
  bool _hotkeysActive = false;

  // Getter for hotkey status
  bool get hotkeysActive => _hotkeysActive;

  void updateContext(BuildContext context) {
    if (context.mounted) {
      _context = context;
    } else {
      debugPrint('Invalid context provided');
    }
  }

  Future<void> activateHotkeys(BuildContext context) async {
    if (_hotkeysActive) return;

    try {
      updateContext(context);
      await _setupHotkeys();
      _hotkeysActive = true;
      debugPrint('Hotkeys activated');
    } catch (e) {
      debugPrint('Error activating hotkeys: $e');
    }
  }

  Future<void> deactivateHotkeys() async {
    if (!_hotkeysActive) return;

    try {
      await _unregisterHotkeys();
      _hotkeysActive = false;
      debugPrint('Hotkeys deactivated');
    } catch (e) {
      debugPrint('Error deactivating hotkeys: $e');
    }
  }

  // Check if currently focused on a text field
  bool _isTextFieldFocused() {
    if (!_hasValidContext) return false;

    final currentFocus = FocusScope.of(_context!);
    if (currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      // Check if the focused widget is a text field
      if (currentFocus.focusedChild!.context != null) {
        final widget = currentFocus.focusedChild!.context!.widget;
        if (widget is EditableText ||
            widget is TextField ||
            widget is TextFormField) {
          return true;
        }
      }
    }

    // Check if any text field has focus
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus.context != null) {
      Element? element = primaryFocus.context as Element?;
      if (element != null) {
        bool isTextField = false;

        element.visitAncestorElements((element) {
          final widget = element.widget;
          if (widget is EditableText ||
              widget is TextField ||
              widget is TextFormField) {
            isTextField = true;
            return false;
          }
          return true;
        });

        return isTextField;
      }
    }

    return false;
  }

  // Custom handler that checks for text field focus before executing the actual handler
  HotKeyHandler _wrapHandler(VoidCallback handler) {
    return (HotKey hotKey) {
      // Skip if focused on a text field, except for Escape key
      if (_isTextFieldFocused() && hotKey.key != LogicalKeyboardKey.escape) {
        return;
      }
      handler();
    };
  }

  // Set up and register all hotkeys with their handlers
  Future<void> _setupHotkeys() async {
    // Use appropriate scope based on platform
    final hotkeyScope =
        Platform.isWindows ? HotKeyScope.inapp : HotKeyScope.system;

    try {
      // Create purchase hotkeys
      final cpHotkey = HotKey(
        key: LogicalKeyboardKey.keyC,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: hotkeyScope,
      );

      final f9Hotkey = HotKey(
        key: LogicalKeyboardKey.f9,
        scope: hotkeyScope,
      );

      // Create sale hotkeys
      final csHotkey = HotKey(
        key: LogicalKeyboardKey.keyS,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: hotkeyScope,
      );

      final f8Hotkey = HotKey(
        key: LogicalKeyboardKey.f8,
        scope: hotkeyScope,
      );

      // Navigation hotkeys
      final pHotkey = HotKey(
        key: LogicalKeyboardKey.keyP,
        scope: hotkeyScope,
      );

      final bHotkey = HotKey(
        key: LogicalKeyboardKey.keyB,
        scope: hotkeyScope,
      );

      final iHotkey = HotKey(
        key: LogicalKeyboardKey.keyI,
        scope: hotkeyScope,
      );

      final f6Hotkey = HotKey(
        key: LogicalKeyboardKey.f6,
        scope: hotkeyScope,
      );

      // Ensure ESC works globally on Windows with system scope
      final escapeKey = HotKey(
        key: LogicalKeyboardKey.escape,
        scope: Platform.isWindows ? HotKeyScope.system : hotkeyScope,
      );

      // Dashboard hotkey
      final homeKey = HotKey(
        key: LogicalKeyboardKey.keyH,
        scope: hotkeyScope,
      );

      // Register all hotkeys with wrapped handlers that check for text field focus
      await hotKeyManager.register(cpHotkey,
          keyDownHandler: _wrapHandler(_createPurchase));
      await hotKeyManager.register(f9Hotkey,
          keyDownHandler: _wrapHandler(_createPurchase));

      await hotKeyManager.register(csHotkey,
          keyDownHandler: _wrapHandler(_createSale));
      await hotKeyManager.register(f8Hotkey,
          keyDownHandler: _wrapHandler(_createSale));

      await hotKeyManager.register(pHotkey,
          keyDownHandler: _wrapHandler(_navigateToProfitLoss));
      await hotKeyManager.register(bHotkey,
          keyDownHandler: _wrapHandler(_navigateToBalanceSheet));
      await hotKeyManager.register(iHotkey,
          keyDownHandler: _wrapHandler(_navigateToInventory));
      await hotKeyManager.register(f6Hotkey,
          keyDownHandler: _wrapHandler(_navigateToHome));
      await hotKeyManager.register(homeKey,
          keyDownHandler: _wrapHandler(_navigateToDashboard));

      // The escape key should work even in text fields, so we don't wrap it with the text field check
      await hotKeyManager.register(escapeKey,
          keyDownHandler: (hotKey) => _handleBackNavigation());

      // Store registered hotkeys for later unregistration
      _registeredHotkeys = [
        cpHotkey,
        f9Hotkey,
        csHotkey,
        f8Hotkey,
        pHotkey,
        bHotkey,
        iHotkey,
        f6Hotkey,
        homeKey,
        escapeKey,
      ];

      debugPrint(
          'Registered ${_registeredHotkeys.length} hotkeys successfully');
    } catch (e) {
      debugPrint('Error registering hotkeys: $e');
      // Attempt to clean up any partially registered hotkeys
      await _unregisterHotkeys();
    }
  }

  // Unregister all hotkeys
  Future<void> _unregisterHotkeys() async {
    try {
      for (final hotkey in _registeredHotkeys) {
        await hotKeyManager.unregister(hotkey);
      }
      _registeredHotkeys.clear();
      debugPrint('Unregistered all hotkeys');
    } catch (e) {
      debugPrint('Error unregistering hotkeys: $e');
    }
  }

  // Safe context checker
  bool get _hasValidContext => _context != null && _context!.mounted;

  // Navigation methods with context safety checks
  void _createPurchase() {
    if (!_hasValidContext) return;
    Navigator.push(
      _context!,
      MaterialPageRoute(builder: (context) => const CreatePurchase()),
    );
  }

  void _createSale() {
    if (!_hasValidContext) return;
    Navigator.push(
      _context!,
      MaterialPageRoute(builder: (context) => const CreateSale()),
    );
  }

  void _navigateToProfitLoss() {
    if (!_hasValidContext) return;
    Navigator.push(
      _context!,
      MaterialPageRoute(builder: (context) =>  ProfitAndLossScreen()),
    );
  }

  void _navigateToBalanceSheet() {
    if (!_hasValidContext) return;
    Navigator.push(
      _context!,
      MaterialPageRoute(builder: (context) => BalanceSheetScreen()),
    );
  }

  void _navigateToInventory() {
    if (!_hasValidContext) return;
    Navigator.push(
      _context!,
      MaterialPageRoute(builder: (context) => const ItemLedgerScreen()),
    );
  }

  void _navigateToHome() {
    if (!_hasValidContext) return;
    Navigator.push(
      _context!,
      MaterialPageRoute(builder: (context) => const YarimaWalletHome()),
    );
  }

  void _navigateToDashboard() {
    if (!_hasValidContext) return;
    // Navigate to the dashboard screen - replace with your actual dashboard navigation
    // For example, you might want to pop to root and then navigate
    Navigator.popUntil(_context!, (route) => route.isFirst);
    // If needed, you can push the dashboard specifically after popping
  }

  void _handleBackNavigation() {
    if (!_hasValidContext) return;

    // First, check if we need to unfocus from a text field
    final currentFocus = FocusScope.of(_context!);
    if (currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
      return;
    }

    // If not in a text field, handle normal back navigation
    if (Navigator.canPop(_context!)) {
      Navigator.pop(_context!);
    }
  }

  // Refresh method to be called when the app's theme or locale changes
  void refreshHotkeys(BuildContext context) async {
    if (_hotkeysActive) {
      await deactivateHotkeys();
      await activateHotkeys(context);
    }
  }
}
