/// Formats whole dollars with thousands separators: 10000 -> "$10,000".
///
/// All amounts in this app are whole dollars stored as `int`. Never use
/// `double` for money — binary floating point cannot represent most
/// decimal fractions exactly. If cents are ever needed, store cents as
/// an `int` and format here.
String formatDollars(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer(r'$');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
