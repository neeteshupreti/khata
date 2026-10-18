import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import 'settings.dart';

class Fmt {

  static final NumberFormat _nf = NumberFormat.decimalPattern('en_IN')
    ..maximumFractionDigits = 2;

  static const List<String> _nepaliDigits = [
    '०', '१', '२', '३', '४', '५', '६', '७', '८', '९'
  ];

  static String digits(String s) {
    if (Settings.lang.value != 'ne') return s;
    return s.replaceAllMapped(
        RegExp(r'[0-9]'), (m) => _nepaliDigits[int.parse(m[0]!)]);
  }

  static String number(double v) => digits(_nf.format(v));

  static String integer(int v) => digits(v.toString());

  static String money(double v) => '${tr('currency')} ${number(v)}';
}
