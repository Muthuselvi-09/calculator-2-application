// main.dart
// Modern, creative calculator UI with glassmorphism and animated gradient background.
// Single-file Flutter app. Drop into lib/main.dart of a new Flutter project.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Creative Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with SingleTickerProviderStateMixin {
  String _expression = '';
  String _result = '';

  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void numClick(String text) {
    setState(() {
      // Avoid leading zeros like '00'
      if (_expression == '0' && text == '0') return;
      _expression += text;
    });
  }

  void allClear() {
    setState(() {
      _expression = '';
      _result = '';
    });
  }

  void delete() {
    setState(() {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    });
  }

  void addOperator(String op) {
    setState(() {
      if (_expression.isEmpty) return;
      final last = _expression.characters.last;
      if ('+-×*/.'.contains(last)) {
        // replace last operator
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else {
        _expression += op;
      }
    });
  }

  void evaluateExpression() {
    try {
      final r = _evaluate(_expression.replaceAll('×', '*'));
      setState(() {
        _result = r.toString();
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
      });
    }
  }

  // Simple infix -> postfix (shunting-yard), then evaluate postfix.
  double _evaluate(String expr) {
    if (expr.isEmpty) return 0.0;

    final tokens = _tokenize(expr);
    final postfix = _toPostfix(tokens);
    return _evalPostfix(postfix);
  }

  List<String> _tokenize(String s) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if ('0123456789.'.contains(c)) {
        buffer.write(c);
      } else if ('+-*/()'.contains(c)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(c);
      } else {
        // ignore other chars
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }

  int _prec(String op) {
    if (op == '+' || op == '-') return 1;
    if (op == '*' || op == '/') return 2;
    return 0;
  }

  List<String> _toPostfix(List<String> tokens) {
    final out = <String>[];
    final ops = <String>[];
    for (final t in tokens) {
      if (double.tryParse(t) != null) {
        out.add(t);
      } else if ('+-*/'.contains(t)) {
        while (ops.isNotEmpty && _prec(ops.last) >= _prec(t)) {
          out.add(ops.removeLast());
        }
        ops.add(t);
      } else if (t == '(') {
        ops.add(t);
      } else if (t == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          out.add(ops.removeLast());
        }
        if (ops.isNotEmpty && ops.last == '(') ops.removeLast();
      }
    }
    while (ops.isNotEmpty) out.add(ops.removeLast());
    return out;
  }

  double _evalPostfix(List<String> tokens) {
    final stack = <double>[];
    for (final t in tokens) {
      final n = double.tryParse(t);
      if (n != null) {
        stack.add(n);
      } else {
        if (stack.length < 2) throw Exception('Invalid expression');
        final b = stack.removeLast();
        final a = stack.removeLast();
        double res;
        switch (t) {
          case '+':
            res = a + b;
            break;
          case '-':
            res = a - b;
            break;
          case '*':
            res = a * b;
            break;
          case '/':
            res = a / b;
            break;
          default:
            throw Exception('Unknown op');
        }
        stack.add(res);
      }
    }
    if (stack.isEmpty) return 0.0;
    return stack.last;
  }

  Widget buildButton(
    String label, {
    double flex = 1,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      flex: flex.toInt(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuint,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // subtle glass look
              color: Colors.white.withOpacity(0.03),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // animated gradient background
          AnimatedBuilder(
            animation: _anim,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + _anim.value, -1),
                    end: Alignment(1 - _anim.value, 1),
                    colors: const [
                      Color(0xFF4A00E0),
                      Color(0xFF8E2DE2),
                      Color(0xFFFF6A00),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),

          // soft moving blobs for style
          Positioned(
            left: -80,
            top: -120,
            child: Transform.rotate(
              angle: 0.6,
              child: Opacity(
                opacity: 0.12,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Creative Calc',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Modern UI • Glassmorphism',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          // toggle theme or do something
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Glass display card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // expression
                            Container(
                              height: media.size.height * 0.12,
                              alignment: Alignment.centerRight,
                              child: SingleChildScrollView(
                                reverse: true,
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  _expression.isEmpty ? '0' : _expression,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            // result
                            Container(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _result,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // small hint
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tap numbers • swipe to delete',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Supports + - × ÷',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // keypad
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              buildButton(
                                'C',
                                onTap: allClear,
                                textColor: Colors.orangeAccent,
                              ),
                              buildButton(
                                '⌫',
                                onTap: delete,
                                textColor: Colors.orangeAccent,
                              ),
                              buildButton(
                                '%',
                                onTap: () => addOperator('%'),
                                textColor: Colors.orangeAccent,
                              ),
                              buildButton(
                                '÷',
                                onTap: () => addOperator('/'),
                                textColor: Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              buildButton('7', onTap: () => numClick('7')),
                              buildButton('8', onTap: () => numClick('8')),
                              buildButton('9', onTap: () => numClick('9')),
                              buildButton(
                                '×',
                                onTap: () => addOperator('*'),
                                textColor: Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              buildButton('4', onTap: () => numClick('4')),
                              buildButton('5', onTap: () => numClick('5')),
                              buildButton('6', onTap: () => numClick('6')),
                              buildButton(
                                '-',
                                onTap: () => addOperator('-'),
                                textColor: Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              buildButton('1', onTap: () => numClick('1')),
                              buildButton('2', onTap: () => numClick('2')),
                              buildButton('3', onTap: () => numClick('3')),
                              buildButton(
                                '+',
                                onTap: () => addOperator('+'),
                                textColor: Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              buildButton(
                                '+/-',
                                onTap: () {
                                  setState(() {
                                    if (_expression.isEmpty) return;
                                    // toggle sign on last number
                                    // naive approach: find last number and flip sign
                                    final reg = RegExp(r'(-?\d*\.?\d+)\$');
                                    final m = reg.firstMatch(_expression);
                                    if (m != null) {
                                      final val = m.group(0)!;
                                      final start = m.start;
                                      if (val.startsWith('-')) {
                                        _expression = _expression.replaceRange(
                                          start,
                                          _expression.length,
                                          val.substring(1),
                                        );
                                      } else {
                                        _expression = _expression.replaceRange(
                                          start,
                                          _expression.length,
                                          '-$val',
                                        );
                                      }
                                    }
                                  });
                                },
                              ),
                              buildButton(
                                '0',
                                flex: 2,
                                onTap: () => numClick('0'),
                              ),
                              buildButton('.', onTap: () => numClick('.')),
                              buildButton(
                                '=',
                                onTap: evaluateExpression,
                                textColor: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
