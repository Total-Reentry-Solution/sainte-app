import 'package:reentry/data/model/incidence_dto.dart';
import 'package:reentry/data/repository/report/report_repository_interface.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/config/supabase_config.dart';

class ReportRepository extends ReportRepositoryInterface {
  static const String incidenceTable = 'incidents';
  static const String responsesTable = 'incident_responses';

  @override
  Future<List<IncidenceResponse>> getIncidenceResponse(String reportId) async {
    try {
      final response = await SupabaseConfig.client
          .from(responsesTable)
          .select('*')
          .eq('incidence_id', reportId)
          .order('created_at', ascending: false);
      
      return response.map((json) => IncidenceResponse.fromJson(json)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch incidence responses: ${e.toString()}');
    }
  }

  @override
  Future<List<IncidenceDto>> getReports() async {
    try {
      final response = await SupabaseConfig.client
          .from(incidenceTable)
          .select('*')
          .order('created_at', ascending: false);
      
      return response.map((json) => IncidenceDto.fromJson(json)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch reports: ${e.toString()}');
    }
  }

  @override
  Future<void> reportUser(IncidenceDto report) async {
    try {
      await SupabaseConfig.client
          .from(incidenceTable)
          .insert(report.toJson(report.id))
          .select();
    } catch (e) {
      throw BaseExceptions('Failed to report user: ${e.toString()}');
    }
  }

  @override
  Future<IncidenceResponse> submitResponse(
      String reportId, String response) async {
    try {
      // First, get the current report to update response count
      final reportResponse = await SupabaseConfig.client
          .from(incidenceTable)
          .select('*')
          .eq('id', reportId)
          .single();
      
      final currentReport = IncidenceDto.fromJson(reportResponse);
      final updatedReport = currentReport.copyWith(
        responseCount: currentReport.responseCount + 1
      );
      
      // Update the report with new response count
      await SupabaseConfig.client
          .from(incidenceTable)
          .update(updatedReport.toJson(updatedReport.id))
          .eq('id', reportId)
          .select();
      
      // Create the response
      final responseData = {
        'text': response,
        'date': DateTime.now().toIso8601String(),
        'incidence_id': reportId,
      };
      
      final responseResult = await SupabaseConfig.client
          .from(responsesTable)
          .insert(responseData)
          .select()
          .single();
      
      return IncidenceResponse.fromJson(responseResult);
    } catch (e) {
      throw BaseExceptions('Failed to submit response: ${e.toString()}');
    }
  }
}
