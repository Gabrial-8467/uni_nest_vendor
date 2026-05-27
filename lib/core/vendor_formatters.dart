import 'package:intl/intl.dart';

String formatCurrency(num value) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'Rs ',
  decimalDigits: 2,
).format(value);

String formatCompactCurrency(num value) =>
    NumberFormat.compactCurrency(locale: 'en_IN', symbol: 'Rs ').format(value);

String formatCompactDate(DateTime dateTime) =>
    DateFormat('dd MMM, hh:mm a').format(dateTime.toLocal());

String humanizeEnum(String value) {
  if (value.trim().isEmpty) {
    return '-';
  }
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
