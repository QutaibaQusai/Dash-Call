// widgets/dialer_pad.dart
import 'package:flutter/material.dart';

class DialerPad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;

  const DialerPad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          _buildRow(['4', '5', '6']),
          _buildRow(['7', '8', '9']),
          _buildRow(['*', '0', '#']),
          const SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              Expanded(
                child: IconButton(
                  onPressed: onDeletePressed,
                  icon: const Icon(Icons.backspace, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Expanded(
      child: Row(
        children: numbers.map((number) => _buildDialButton(number)).toList(),
      ),
    );
  }

  Widget _buildDialButton(String number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => onNumberPressed(number),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            shape: const CircleBorder(),
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue.shade700,
          ),
          child: Text(
            number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}