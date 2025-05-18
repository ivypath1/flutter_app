import 'package:flutter/material.dart';

class CalculatorDialog extends StatefulWidget {
  final TextEditingController controller;
  
  const CalculatorDialog({super.key, required this.controller});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _currentInput = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldClearInput = false;

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        // Clear everything
        _currentInput = '';
        _firstOperand = null;
        _operator = null;
      } else if (buttonText == '⌫') {
        // Backspace
        if (_currentInput.isNotEmpty) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        }
      } else if (buttonText == '=') {
        // Perform calculation
        if (_operator != null && _currentInput.isNotEmpty) {
          final secondOperand = double.tryParse(_currentInput);
          if (secondOperand != null) {
            double result;
            switch (_operator) {
              case '+':
                result = _firstOperand! + secondOperand;
                break;
              case '-':
                result = _firstOperand! - secondOperand;
                break;
              case '×':
                result = _firstOperand! * secondOperand;
                break;
              case '÷':
                result = _firstOperand! / secondOperand;
                break;
              default:
                result = 0;
            }
            _currentInput = result.toString();
            if (_currentInput.endsWith('.0')) {
              _currentInput = _currentInput.substring(0, _currentInput.length - 2);
            }
            _firstOperand = null;
            _operator = null;
            _shouldClearInput = true;
          }
        }
      } else if (['+', '-', '×', '÷'].contains(buttonText)) {
        // Operator pressed
        if (_currentInput.isNotEmpty) {
          _firstOperand = double.tryParse(_currentInput);
          _operator = buttonText;
          _shouldClearInput = true;
        }
      } else {
        // Number or decimal point pressed
        if (_shouldClearInput) {
          _currentInput = '';
          _shouldClearInput = false;
        }
        if (buttonText == '.' && _currentInput.contains('.')) {
          return; // Prevent multiple decimal points
        }
        _currentInput += buttonText;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentInput.isEmpty ? '0' : _currentInput,
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  if (_operator != null)
                    Text(
                      ' $_operator',
                      style: const TextStyle(fontSize: 24),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Calculator buttons
            Table(
              children: [
                TableRow(
                  children: ['C', '⌫', '÷'].map((text) => _buildButton(text)).toList(),
                ),
                TableRow(
                  children: ['7', '8', '9'].map((text) => _buildButton(text)).toList(),
                ),
                TableRow(
                  children: ['4', '5', '6'].map((text) => _buildButton(text)).toList(),
                ),
                TableRow(
                  children: ['1', '2', '3'].map((text) => _buildButton(text)).toList(),
                ),
                TableRow(
                  children: ['.', '0', '='].map((text) => _buildButton(text)).toList(),
                ),
                TableRow(
                  children: ['+', '-', '×'].map((text) => _buildButton(text)).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.controller.text = _currentInput;
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => _onButtonPressed(text),
        child: Text(
          text,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

