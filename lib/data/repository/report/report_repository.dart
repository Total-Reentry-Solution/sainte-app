import 'package:reentry/data/model/incidence_dto.dart';
import 'package:reentry/data/repository/report/report_repository_interface.dart';

class ReportRepository extends ReportRepositoryInterface {
  // final incidenceCollection =
  //     FirebaseFirestore.instance.collection("incidence");

  @override
  Future<List<IncidenceResponse>> getIncidenceResponse(String reportId) async {
    // final document = incidenceCollection.doc(reportId).collection("response");
    // final result = await document.get();
    return [];
  }

  @override
  Future<List<IncidenceDto>> getReports() async {
    // final result = await incidenceCollection.get();
    return [];
  }

  @override
  Future<void> reportUser(IncidenceDto report) async {
    // final document = incidenceCollection.doc();
    // await document.set(report.toJson(document.id));
  }

  @override
  Future<IncidenceResponse> submitResponse(
      String reportId, String response) async {
    // final document = incidenceCollection.doc(reportId).collection("response");
    // var documentSnapshot = incidenceCollection.doc(reportId);
    // final reportDataSnapshot = await documentSnapshot.get();
    // final reportJson = reportDataSnapshot.data();
    // var report = IncidenceDto.fromJson(reportJson!);
    // report = report.copyWith(responseCount: report.responseCount + 1);
    // await documentSnapshot.set(report.toJson(report.id));
    // final newDoc = document.doc();
    // final responseData = IncidenceResponse(text: response,id: newDoc.id,date: DateTime.now());
    // await newDoc.set(responseData.toJson());
    return IncidenceResponse(text: response,id: "",date: DateTime.now());
  }
}
