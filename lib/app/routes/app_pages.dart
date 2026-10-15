import 'package:get/get.dart';

import '../modules/categories/bindings/categories_binding.dart';
import '../modules/categories/views/categories_view.dart';
import '../modules/get_borrow/bindings/get_borrow_binding.dart';
import '../modules/get_borrow/views/get_borrow_view.dart';
import '../modules/get_chitfunds/bindings/get_chitfunds_binding.dart';
import '../modules/get_chitfunds/views/get_chitfunds_view.dart';
import '../modules/get_lend/bindings/get_lend_binding.dart';
import '../modules/get_lend/views/get_lend_view.dart';
import '../modules/get_loans/bindings/get_loans_binding.dart';
import '../modules/get_loans/views/get_loans_view.dart';
import '../modules/get_reminder/bindings/get_reminder_binding.dart';
import '../modules/get_reminder/views/get_reminder_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/income_expense/bindings/expense_binding.dart';
import '../modules/income_expense/bindings/income_expense_binding.dart';
import '../modules/income_expense/bindings/indiv_post_income_binding.dart';
import '../modules/income_expense/bindings/post_expense_binding.dart';
import '../modules/income_expense/bindings/post_income_binding.dart';
import '../modules/income_expense/views/expense_view.dart';
import '../modules/income_expense/views/income_expense_view.dart';
import '../modules/income_expense/views/indiv_post_income_view.dart';
import '../modules/income_expense/views/post_expense_view.dart';
import '../modules/income_expense/views/post_income_view.dart';
import '../modules/lend_and_borrow/bindings/borrow_binding.dart';
import '../modules/lend_and_borrow/bindings/lend_binding.dart';
import '../modules/lend_and_borrow/views/borrow_view.dart';
import '../modules/lend_and_borrow/views/lend_view.dart';
import '../modules/loan_chitfund/bindings/chitfunds_binding.dart';
import '../modules/loan_chitfund/bindings/loans_binding.dart';
import '../modules/loan_chitfund/views/chitfunds_view.dart';
import '../modules/loan_chitfund/views/loans_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/post_lend/bindings/post_lend_binding.dart';
import '../modules/post_lend/views/post_lend_view.dart';
import '../modules/postborrow/bindings/postborrow_binding.dart';
import '../modules/postborrow/views/postborrow_view.dart';
import '../modules/postchitfund/bindings/postchitfund_binding.dart';
import '../modules/postchitfund/views/postchitfund_view.dart';
import '../modules/postloan/bindings/postloan_binding.dart';
import '../modules/postloan/views/postloan_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/reminders/bindings/reminders_binding.dart';
import '../modules/reminders/views/reminders_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.POSTCHITFUND;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LEND_AND_BORROW,
      page: () => const LendView(),
      binding: LendBinding(),
    ),
    GetPage(
      name: _Paths.BorrowView,
      page: () => BorrowView(),
      binding: BorrowBinding(),
    ),
    GetPage(
      name: _Paths.INCOME_EXPENSE,
      page: () => const IncomeExpenseView(),
      binding: IncomeExpenseBinding(),
    ),
    GetPage(
      name: _Paths.ExpenseView,
      page: () => ExpenseView(),
      binding: ExpenseBinding(),
    ),
    GetPage(
      name: _Paths.CATEGORIES,
      page: () => const CategoriesView(),
      binding: CategoriesBinding(),
    ),
    GetPage(
      name: _Paths.PostIncomeView,
      page: () => const PostIncomeView(),
      binding: PostIncomeBinding(),
    ),
    GetPage(
      name: _Paths.PostExpenseView,
      page: () => PostExpenseView(),
      binding: PostExpenseBinding(),
    ),
    GetPage(
      name: _Paths.IndivPostIncomeView,
      page: () => IndivPostIncomeView(),
      binding: IndivPostIncomeBinding(),
    ),
    GetPage(
      name: _Paths.LOAN_CHITFUND,
      page: () => const ChitfundView(),
      binding: ChitfundBinding(),
    ),
    GetPage(
      name: _Paths.LoansView,
      page: () => LoansView(),
      binding: LoansBinding(),
    ),
    GetPage(
      name: _Paths.REMINDERS,
      page: () => const RemindersView(),
      binding: RemindersBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.GET_REMINDER,
      page: () => const GetReminderView(),
      binding: GetReminderBinding(),
    ),
    GetPage(
      name: _Paths.GET_LEND,
      page: () => const GetLendView(),
      binding: GetLendBinding(),
    ),
    GetPage(
      name: _Paths.GET_BORROW,
      page: () => const GetBorrowView(),
      binding: GetBorrowBinding(),
    ),
    GetPage(
      name: _Paths.GET_LOANS,
      page: () => const GetLoansView(),
      binding: GetLoansBinding(),
    ),
    GetPage(
      name: _Paths.GET_CHITFUNDS,
      page: () => const GetChitfundsView(),
      binding: GetChitfundsBinding(),
    ),
    GetPage(
      name: _Paths.POST_LEND,
      page: () => const PostLendView(),
      binding: PostLendBinding(),
    ),
    GetPage(
      name: _Paths.POSTBORROW,
      page: () => const PostborrowView(),
      binding: PostborrowBinding(),
    ),
    GetPage(
      name: _Paths.POSTLOAN,
      page: () => PostloanView(),
      binding: PostloanBinding(),
    ),
    GetPage(
      name: _Paths.POSTCHITFUND,
      page: () => const PostchitfundView(),
      binding: PostchitfundBinding(),
    ),
  ];
}
