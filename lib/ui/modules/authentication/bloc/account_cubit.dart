import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/model/user.dart';

// Clean AccountCubit using new AppUser model
class AccountCubit extends Cubit<AppUser?> {
  AccountCubit() : super(null);

  void setAccount(AppUser user) {
    emit(user);
  }

  void clearAccount() {
    emit(null);
  }

  void updateAccount(AppUser user) {
    emit(user);
  }
}