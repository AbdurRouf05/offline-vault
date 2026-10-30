import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offline_vault/core/crypto/cipher_service.dart';
import 'package:offline_vault/core/theme/app_theme.dart';

class PasswordGeneratorDialog extends StatefulWidget {
  final ValueChanged<String>? onSelect;

  const PasswordGeneratorDialog({super.key, this.onSelect});

  @override
  State<PasswordGeneratorDialog> createState() =>
      _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  final CipherService _cipher = CipherService();

  int _length = 16;
  bool _includeUpper = true;
  bool _includeLower = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  String _generated = '';

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    setState(() {
      _generated = _cipher.generatePassword(
        length: _length,
        includeUppercase: _includeUpper,
        includeLowercase: _includeLower,
        includeNumbers: _includeNumbers,
        includeSymbols: _includeSymbols,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Generator Password',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _generated,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _regenerate,
                    tooltip: 'Buat Ulang',
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generated));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password tersalin ke clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Salin',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Panjang Karakter: $_length',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _length.toDouble(),
              min: 8,
              max: 32,
              divisions: 24,
              activeColor: AppColors.lightAccent,
              onChanged: (val) {
                setState(() => _length = val.round());
                _regenerate();
              },
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Huruf Besar (A-Z)'),
              value: _includeUpper,
              activeColor: AppColors.lightAccent,
              onChanged: (val) {
                if (val == null) return;
                setState(() => _includeUpper = val);
                _regenerate();
              },
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Huruf Kecil (a-z)'),
              value: _includeLower,
              activeColor: AppColors.lightAccent,
              onChanged: (val) {
                if (val == null) return;
                setState(() => _includeLower = val);
                _regenerate();
              },
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Angka (0-9)'),
              value: _includeNumbers,
              activeColor: AppColors.lightAccent,
              onChanged: (val) {
                if (val == null) return;
                setState(() => _includeNumbers = val);
                _regenerate();
              },
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Simbol (!@#\$)'),
              value: _includeSymbols,
              activeColor: AppColors.lightAccent,
              onChanged: (val) {
                if (val == null) return;
                setState(() => _includeSymbols = val);
                _regenerate();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 42)),
          onPressed: () {
            widget.onSelect?.call(_generated);
            Navigator.pop(context, _generated);
          },
          child: const Text('Gunakan'),
        ),
      ],
    );
  }
}
