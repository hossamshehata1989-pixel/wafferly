/// Performs deterministic, locale-aware character normalization for financial
/// input text. It does not parse a transaction, infer event status, or save data.
///
/// The caller should keep both the input text and normalized result in memory
/// only for the duration of processing; this class never persists or logs them.
final class FinancialTextNormalizer {
  const FinancialTextNormalizer();

  static const Map<int, String> _digitMap = <int, String>{
    0x0660: '0',
    0x0661: '1',
    0x0662: '2',
    0x0663: '3',
    0x0664: '4',
    0x0665: '5',
    0x0666: '6',
    0x0667: '7',
    0x0668: '8',
    0x0669: '9',
    0x06F0: '0',
    0x06F1: '1',
    0x06F2: '2',
    0x06F3: '3',
    0x06F4: '4',
    0x06F5: '5',
    0x06F6: '6',
    0x06F7: '7',
    0x06F8: '8',
    0x06F9: '9',
  };

  String normalize(String input) {
    final output = StringBuffer();

    for (final rune in input.runes) {
      final mappedDigit = _digitMap[rune];
      if (mappedDigit != null) {
        output.write(mappedDigit);
        continue;
      }

      // Arabic tatweel and combining vowel/recitation marks do not affect the
      // financial meaning and make literal template matching less reliable.
      if (_isArabicMark(rune)) {
        continue;
      }

      switch (rune) {
        case 0x066B: // Arabic decimal separator: ٫
          output.write('.');
          break;
        case 0x066C: // Arabic thousands separator: ٬
          output.write(',');
          break;
        case 0x060C: // Arabic comma: ،
          output.write(',');
          break;
        case 0x061B: // Arabic semicolon: ؛
          output.write(';');
          break;
        case 0x061F: // Arabic question mark: ؟
          output.write('?');
          break;
        case 0x00A0: // No-break space
        case 0x202F: // Narrow no-break space
          output.write(' ');
          break;
        default:
          output.writeCharCode(rune);
          break;
      }
    }

    return output
        .toString()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isArabicMark(int rune) {
    return rune == 0x0640 ||
        (rune >= 0x064B && rune <= 0x065F) ||
        rune == 0x0670 ||
        (rune >= 0x06D6 && rune <= 0x06ED);
  }
}
