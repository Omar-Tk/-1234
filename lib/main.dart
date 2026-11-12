import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  bool _isDark = true;

  void _toggleTheme() => setState(() => _isDark = !_isDark);

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7867F5);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'الحاسبة',
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF4F5FA),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101116),
      ),
      home: CalculatorPage(
        isDark: _isDark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({
    required this.isDark,
    required this.onThemeChanged,
    super.key,
  });

  final bool isDark;
  final VoidCallback onThemeChanged;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = '';
  String _answer = '0';
  bool _justCalculated = false;
  final List<CalculationEntry> _history = [];

  bool get _isOperator {
    if (_expression.isEmpty) return false;
    return const ['+', '−', '×', '÷'].contains(_expression[_expression.length - 1]);
  }

  void _press(String value) {
    setState(() {
      switch (value) {
        case 'AC':
          _expression = '';
          _answer = '0';
          _justCalculated = false;
          return;
        case '⌫':
          if (_justCalculated) {
            _expression = '';
            _answer = '0';
            _justCalculated = false;
          } else if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
            _refreshPreview();
          }
          return;
        case '=':
          _calculate();
          return;
        case '+/−':
          _toggleSign();
          _refreshPreview();
          return;
        case '%':
          if (_expression.isNotEmpty && !_isOperator && !_expression.endsWith('%')) {
            _expression += '%';
            _justCalculated = false;
            _refreshPreview();
          }
          return;
        case '+':
        case '−':
        case '×':
        case '÷':
          _addOperator(value);
          return;
        case '.':
          _addDecimalPoint();
          _refreshPreview();
          return;
        default:
          if (value.length == 1 && value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57) {
            _addDigit(value);
            _refreshPreview();
          }
      }
    });
  }

  void _addDigit(String digit) {
    if (_justCalculated) {
      _expression = '';
      _answer = '0';
      _justCalculated = false;
    }
    if (_expression.endsWith('%')) {
      _expression += '×$digit';
    } else {
      _expression += digit;
    }
  }

  void _addOperator(String operator) {
    if (_justCalculated) {
      _expression = _answer == 'خطأ' ? '' : _answer;
      _justCalculated = false;
    }
    if (_expression.isEmpty) {
      if (operator == '−') _expression = '−';
      return;
    }
    if (_isOperator) {
      _expression = _expression.substring(0, _expression.length - 1) + operator;
    } else if (!_expression.endsWith('.')) {
      _expression += operator;
    }
    _refreshPreview();
  }

  void _addDecimalPoint() {
    if (_justCalculated) {
      _expression = '';
      _answer = '0';
      _justCalculated = false;
    }
    if (_expression.endsWith('%')) {
      _expression += '×0.';
      return;
    }
    final currentNumber = RegExp(r'\d+\.\d*$').firstMatch(_expression);
    if (currentNumber != null) return;
    if (_expression.isEmpty || _isOperator) {
      _expression += '0.';
    } else {
      _expression += '.';
    }
  }

  void _toggleSign() {
    if (_justCalculated) {
      if (_answer != '0' && _answer != 'خطأ') {
        _expression = _answer.startsWith('-')
            ? _answer.substring(1)
            : '-$_answer';
      }
      _justCalculated = false;
      return;
    }
    if (_expression.isEmpty) {
      _expression = '−';
      return;
    }

    final match = RegExp(r'\d+(?:\.\d*)?$').firstMatch(_expression);
    if (match != null) {
      final start = match.start;
      final before = _expression.substring(0, start);
      final number = match.group(0)!;
      if (before.endsWith('−') &&
          (before.length == 1 || const ['+', '−', '×', '÷'].contains(before[before.length - 2]))) {
        _expression = before.substring(0, before.length - 1) + number;
      } else {
        _expression = '$before−$number';
      }
    } else if (_isOperator) {
      _expression += '−';
    } else if (_expression == '−') {
      _expression = '';
    }
  }

  void _refreshPreview() {
    if (_expression.isEmpty || _isOperator || _expression.endsWith('.')) {
      _answer = '0';
      return;
    }
    try {
      final value = ExpressionParser(_expression).parse();
      _answer = _formatNumber(value);
    } catch (_) {
      if (_expression.isEmpty) _answer = '0';
    }
  }

  void _calculate() {
    if (_expression.isEmpty || _isOperator || _expression.endsWith('.')) return;
    try {
      final original = _expression;
      final value = ExpressionParser(original).parse();
      final formatted = _formatNumber(value);
      _history.insert(0, CalculationEntry(original, formatted));
      if (_history.length > 30) _history.removeLast();
      _answer = formatted;
      _justCalculated = true;
    } catch (_) {
      _answer = 'خطأ';
      _justCalculated = true;
    }
  }

  String _formatNumber(double value) {
    if (!value.isFinite) return 'خطأ';
    if (value.abs() < 1e-10) value = 0;
    final rounded = value.toStringAsFixed(10);
    final cleaned = rounded.replaceFirst(RegExp(r'\.0+$'), '').replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1');
    return cleaned == '-0' ? '0' : cleaned;
  }

  void _openHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.55,
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'سجل العمليات',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_history.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(_history.clear);
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('مسح السجل'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _history.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_rounded,
                                    size: 44,
                                    color: Theme.of(sheetContext).colorScheme.outline),
                                const SizedBox(height: 10),
                                Text(
                                  'لا توجد عمليات سابقة',
                                  style: TextStyle(color: Theme.of(sheetContext).colorScheme.outline),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _history.length,
                            separatorBuilder: (_, __) => const Divider(height: 18),
                            itemBuilder: (context, index) {
                              final entry = _history[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  entry.expression,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                ),
                                subtitle: Text(
                                  entry.result,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                                ),
                                onTap: () {
                                  setState(() {
                                    _expression = entry.result;
                                    _answer = entry.result;
                                    _justCalculated = true;
                                  });
                                  Navigator.pop(sheetContext);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = <List<String>>[
      ['AC', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['+/−', '0', '.', '='],
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.calculate_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الحاسبة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('حاسبة بسيطة وأنيقة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'سجل العمليات',
                    onPressed: _openHistory,
                    icon: const Icon(Icons.history_rounded),
                  ),
                  IconButton(
                    tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                    onPressed: widget.onThemeChanged,
                    icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF191A22) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.035),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.14 : 0.045),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _expression.isEmpty ? 'ابدأ الحساب' : _expression,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        textAlign: TextAlign.end,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 22,
                          color: scheme.onSurface.withOpacity(0.48),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _answer,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 54,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.4,
                            color: _answer == 'خطأ' ? scheme.error : scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    for (final row in rows)
                      Expanded(
                        child: Row(
                          children: [
                            for (final label in row)
                              _buildKey(label, scheme, isDark),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'صُممت لتجربة حساب مريحة',
                style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.35)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label, ColorScheme scheme, bool isDark) {
    final isEqual = label == '=';
    final isOperator = const ['÷', '×', '−', '+'].contains(label);
    final isUtility = const ['AC', '⌫', '%', '+/−'].contains(label);

    Color background;
    Color foreground;
    if (isEqual) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else if (isOperator) {
      background = scheme.primary.withOpacity(isDark ? 0.22 : 0.12);
      foreground = scheme.primary;
    } else if (isUtility) {
      background = isDark ? const Color(0xFF262832) : const Color(0xFFE8E9F0);
      foreground = scheme.onSurface;
    } else {
      background = isDark ? const Color(0xFF1B1D25) : Colors.white;
      foreground = scheme.onSurface;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _press(label),
            child: Center(
              child: label == '⌫'
                  ? Icon(Icons.backspace_outlined, color: foreground, size: 23)
                  : Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: isEqual ? 29 : (label.length > 2 ? 17 : 25),
                        fontWeight: isEqual || isOperator || isUtility
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class CalculationEntry {
  const CalculationEntry(this.expression, this.result);

  final String expression;
  final String result;
}

class ExpressionParser {
  ExpressionParser(String expression) : _tokens = _tokenize(expression);

  final List<String> _tokens;
  int _position = 0;

  double parse() {
    if (_tokens.isEmpty) throw const FormatException('Empty expression');
    final result = _parseExpression();
    if (_position != _tokens.length) throw const FormatException('Unexpected token');
    if (!result.isFinite) throw const FormatException('Invalid result');
    return result;
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    var i = 0;
    while (i < input.length) {
      final char = input[i];
      if (char.trim().isEmpty) {
        i++;
        continue;
      }
      if ('0123456789.'.contains(char)) {
        final start = i;
        var dots = 0;
        while (i < input.length && '0123456789.'.contains(input[i])) {
          if (input[i] == '.') dots++;
          i++;
        }
        if (dots > 1 || input.substring(start, i) == '.') {
          throw const FormatException('Invalid number');
        }
        tokens.add(input.substring(start, i));
        continue;
      }
      switch (char) {
        case '+':
        case '−':
        case '-':
          tokens.add(char == '−' ? '-' : char);
          break;
        case '×':
        case '*':
          tokens.add('*');
          break;
        case '÷':
        case '/':
          tokens.add('/');
          break;
        case '%':
        case '(':
        case ')':
          tokens.add(char);
          break;
        default:
          throw const FormatException('Unsupported character');
      }
      i++;
    }
    return tokens;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (_match('+') || _match('-')) {
      final operator = _previous();
      final right = _parseTerm();
      value = operator == '+' ? value + right : value - right;
    }
    return value;
  }

  double _parseTerm() {
    var value = _parseUnary();
    while (_match('*') || _match('/')) {
      final operator = _previous();
      final right = _parseUnary();
      if (operator == '/' && right == 0) {
        throw const FormatException('Division by zero');
      }
      value = operator == '*' ? value * right : value / right;
    }
    return value;
  }

  double _parseUnary() {
    if (_match('+')) return _parseUnary();
    if (_match('-')) return -_parseUnary();
    return _parsePostfix();
  }

  double _parsePostfix() {
    var value = _parsePrimary();
    while (_match('%')) {
      value /= 100;
    }
    return value;
  }

  double _parsePrimary() {
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) throw const FormatException('Missing closing parenthesis');
      return value;
    }
    if (_position >= _tokens.length) throw const FormatException('Expected number');
    final token = _tokens[_position++];
    final number = double.tryParse(token);
    if (number == null) throw const FormatException('Expected number');
    return number;
  }

  bool _match(String token) {
    if (_position >= _tokens.length || _tokens[_position] != token) return false;
    _position++;
    return true;
  }

  String _previous() => _tokens[_position - 1];
}
