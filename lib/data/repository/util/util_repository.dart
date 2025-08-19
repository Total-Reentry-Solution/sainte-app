import 'package:reentry/data/model/report_dto.dart';
import 'package:reentry/data/model/support_ticket.dart';
import 'package:reentry/data/repository/util/util_repository_interface.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:reentry/core/config/supabase_config.dart';

class UtilRepository implements UtilityRepositoryInterface {
  static const String reportsTable = 'reports';
  static const String supportTicketsTable = 'support_tickets';

  @override
  Future<void> reportAnIssue(ReportDto data) async {
    try {
      await SupabaseConfig.client
          .from(reportsTable)
          .insert(data.toJson());
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }

  @override
  Future<void> supportTicket(SupportTicketDto data) async {
    try {
      await SupabaseConfig.client
          .from(supportTicketsTable)
          .insert(data.toJson());
    } catch (e) {
      throw BaseExceptions(e.toString());
    }
  }
}
