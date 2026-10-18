import 'package:nepali_utils/nepali_utils.dart';

import 'format_service.dart';
import 'settings.dart';

class DateService {

  static const int minBsYear = 2000;
  static const int maxBsYear = 2098;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static NepaliDateTime toBs(DateTime d) => dateOnly(d).toNepaliDateTime();

  static DateTime fromBs(int year, int month, int day) =>
      NepaliDateTime(year, month, day).toDateTime();

  static int bsDaysInMonth(int year, int month) {
    final start = fromBs(year, month, 1);
    final next = month == 12 ? fromBs(year + 1, 1, 1) : fromBs(year, month + 1, 1);
    return (next.difference(start).inHours / 24).round();
  }

  static const List<String> _bsMonthsEn = [
    'Baisakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin',
    'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
  ];
  static const List<String> _bsMonthsNe = [
    'बैशाख', 'जेठ', 'असार', 'साउन', 'भदौ', 'असोज',
    'कात्तिक', 'मंसिर', 'पुष', 'माघ', 'फागुन', 'चैत'
  ];
  static const List<String> _adMonthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const List<String> _adMonthsNe = [
    'जनवरी', 'फेब्रुअरी', 'मार्च', 'अप्रिल', 'मे', 'जुन',
    'जुलाई', 'अगस्ट', 'सेप्टेम्बर', 'अक्टोबर', 'नोभेम्बर', 'डिसेम्बर'
  ];

  static String bsMonthName(int month) =>
      (Settings.lang.value == 'ne' ? _bsMonthsNe : _bsMonthsEn)[month - 1];

  static String format(DateTime d) {
    if (Settings.useBs.value) {
      final n = toBs(d);
      return Fmt.digits('${n.day} ${bsMonthName(n.month)} ${n.year}');
    }
    final months = Settings.lang.value == 'ne' ? _adMonthsNe : _adMonthsEn;
    return Fmt.digits('${d.day} ${months[d.month - 1]} ${d.year}');
  }
}
