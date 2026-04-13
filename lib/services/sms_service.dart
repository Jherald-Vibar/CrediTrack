import 'package:url_launcher/url_launcher.dart';
import '../models/client.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class SmsService {
  static Future<bool> sendReminder({
    required Client client,
    required CreditTransaction transaction,
  }) async {
    final fmt = NumberFormat('#,##0.00', 'en_PH');
    final dateFmt = DateFormat('MMM dd, yyyy');
    final body = Uri.encodeComponent(
      'Hi ${client.name}, this is a reminder that your credit payment of '
      '₱${fmt.format(transaction.remainingBalance)} is due on '
      '${dateFmt.format(transaction.dueDate)}. '
      'Please settle at your earliest convenience. - CrediTrack',
    );
    final uri = Uri.parse('sms:${client.contactNumber}?body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  static String buildReminderMessage(
      Client client, CreditTransaction transaction) {
    final fmt = NumberFormat('#,##0.00', 'en_PH');
    final dateFmt = DateFormat('MMM dd, yyyy');
    return 'Hi ${client.name}, this is a reminder that your credit payment of '
        '₱${fmt.format(transaction.remainingBalance)} is due on '
        '${dateFmt.format(transaction.dueDate)}. '
        'Please settle at your earliest convenience. - CrediTrack';
  }
}