import 'package:get/get.dart';

import '../modules/categories/bindings/categories_binding.dart';
import '../modules/categories/views/categories_view.dart';
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
import '../modules/reminders/bindings/reminders_binding.dart';
import '../modules/reminders/views/reminders_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

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
  ];
}
