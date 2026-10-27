import 'package:flutter/material.dart';

/// Widget PIN Pad cho Kid Mode — nút tròn to, dễ bấm cho trẻ em
class KidPinPad extends StatefulWidget {
  const KidPinPad({super.key, required this.onPinComplete, this.pinLength = 4});

  final void Function(String pin) onPinComplete;
  final int pinLength;

  @override
  State<KidPinPad> createState() => _KidPinPadState();
}

class _KidPinPadState extends State<KidPinPad> {
  String _enteredPin = '';

  void _onDigitPress(String digit) {
    if (_enteredPin.length >= widget.pinLength) return;
    setState(() => _enteredPin += digit);
    if (_enteredPin.length == widget.pinLength) {
      widget.onPinComplete(_enteredPin);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(
      () => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1),
    );
  }

  void _onClear() {
    setState(() => _enteredPin = '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.pinLength,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _enteredPin.length
                    ? const Color(0xFFFF6B6B)
                    : Colors.grey.shade300,
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Number pad
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['C', '0', '⌫'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                if (key == 'C') {
                  return _PadButton(
                    label: key,
                    onTap: _onClear,
                    color: Colors.orange.shade200,
                  );
                }
                if (key == '⌫') {
                  return _PadButton(
                    label: key,
                    onTap: _onBackspace,
                    color: Colors.red.shade200,
                  );
                }
                return _PadButton(label: key, onTap: () => _onDigitPress(key));
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: color ?? const Color(0xFFFFF9E6),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
