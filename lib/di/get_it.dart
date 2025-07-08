import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/shared/share_preference.dart';
import '../data/repository/auth/auth_repository.dart';
import '../data/repository/auth/auth_repository_interface.dart';
import '../data/repository/user/user_repository.dart';
import '../data/repository/user/user_repository_interface.dart';
import '../data/repository/clients/client_repository.dart';
import '../data/repository/clients/client_repository_interface.dart';
import '../data/repository/blog/blog_repository.dart';
import '../data/repository/blog/blog_repository_interface.dart';
import '../data/repository/appointment/appointment_repository.dart';
import '../data/repository/appointment/appointment_repository_interface.dart';
import '../data/repository/admin/admin_repository.dart';
import '../data/repository/admin/admin_repository_interface.dart';
import '../data/repository/util/util_repository.dart';
import '../data/repository/util/util_repository_interface.dart';
import '../data/repository/report/report_repository.dart';
import '../data/repository/report/report_repository_interface.dart';
import '../data/repository/messaging/messaging_repository.dart';
import '../data/repository/messaging/messaging_repository_interface.dart';
import '../data/repository/mentor/mentor_repository.dart';
import '../data/repository/mentor/mentor_repository_interface.dart';
import '../core/config/app_config.dart';

GetIt locator = GetIt.instance;

void setupDi(){
  locator.registerLazySingletonAsync<PersistentStorage>(()async{
    final result = await SharedPreferences.getInstance();
    return PersistentStorage(preferences: result);
  });
  locator.registerLazySingleton<AuthRepositoryInterface>(() => AuthRepository());
  locator.registerLazySingleton<UserRepositoryInterface>(() => UserRepository());
  locator.registerLazySingleton<ClientRepositoryInterface>(() => ClientRepository());
  locator.registerLazySingleton<BlogRepositoryInterface>(() => BlogRepository());
  locator.registerLazySingleton<AppointmentRepositoryInterface>(() => AppointmentRepository());
  locator.registerLazySingleton<AdminRepositoryInterface>(() => AdminRepository());
  locator.registerLazySingleton<UtilityRepositoryInterface>(() => UtilRepository());
  locator.registerLazySingleton<ReportRepositoryInterface>(() => ReportRepository());
  locator.registerLazySingleton<MessagingRepositoryInterface>(() => MessageRepository());
  locator.registerLazySingleton<MentorRepositoryInterface>(() => MentorRepository());
}