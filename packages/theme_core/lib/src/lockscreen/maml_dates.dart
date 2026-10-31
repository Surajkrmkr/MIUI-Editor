/// MAML expressions for calendar maths; MAML months are 0-based and
/// `#day_of_week` runs 1 (Sunday) to 7.
abstract final class MamlDates {
  static const leap = '(eq(#year%4,0)*ne(#year%100,0)+eq(#year%400,0))';

  static const monthDays =
      '(ifelse(eq(#month,1),28+$leap,eq(#month,3)+eq(#month,5)+eq(#month,8)+eq(#month,10),30,31))';

  static const yearDays = '(365+$leap)';

  static const _monthStarts = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

  static final String dayOfYear = () {
    final b = StringBuffer('(#date+gt(#month,1)*$leap+ifelse(');
    for (var m = 1; m < 12; m++) {
      b.write('eq(#month,$m),${_monthStarts[m]},');
    }
    b.write('0))');
    return b.toString();
  }();

  /// Days after today until the end of a Monday-first week, 0–6.
  static const weekDaysLeft = '(7-((#day_of_week+5)%7+1))';
}
