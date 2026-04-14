import 'package:url_launcher/url_launcher.dart';
import '../models/client.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class SmsService {
  /// Master method to open the SMS app with any message
  static Future<bool> sendCustomSms({
    required String contact,
    required String message,
  }) async {
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$contact?body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  /// Specific method for Due Date reminders
  static Future<bool> sendReminder({
    required Client client,
    required CreditTransaction transaction,
  }) async {
    final message = buildReminderMessage(client, transaction);
    // Reuse the master method
    return await sendCustomSms(contact: client.contactNumber, message: message);
  }

  /// Builds the text string for reminders
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