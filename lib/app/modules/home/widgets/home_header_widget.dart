import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
////////////////////////////////////////////////////////////
/// COMMON WIDGETS
////////////////////////////////////////////////////////////
class SectionTitle extends StatelessWidget {
final String title;
const SectionTitle({super.key, required this.title});
@override
Widget build(BuildContext context) {
return Text(
 title,
style: TextStyle(
fontSize: 17.sp,
color: Color(0xff1B1C1A),
fontWeight: FontWeight.w700,
fontFamily: 'HankenGrotesk',
),
);
}
}
class SectionHeader extends StatelessWidget {
 final String title;
 final String action;
 const SectionHeader({super.key, required this.title, required this.action});
 @override
Widget build(BuildContext context) {
return Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
title,
style: TextStyle(
 fontSize: 18.sp,
fontFamily: 'HankenGrotesk',
fontWeight: FontWeight.w600,
),
 ),
InkWell(
onTap: () {
 Get.toNamed(Routes.CATEGORIES);
 },
child: Text(
 action,
 style: TextStyle(
 color: Colors.teal,
 fontSize: 12.sp,
 fontFamily: 'HankenGrotesk',
),
 ),
 ),
],
);
 }
}
class SectionHeader1 extends StatelessWidget {
 final String title;
 final String action;
 final String route;
 const SectionHeader1({
 super.key,
required this.title,
 this.action = 'View All',
this.route = Routes.CATEGORIES,
 });
 @override
 Widget build(BuildContext context) {
return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(
title,
style: TextStyle(
 fontSize: 18.sp,
 fontFamily: 'HankenGrotesk',
fontWeight: FontWeight.w600,
 ),
 ),
 InkWell(
onTap: () {
 Get.toNamed(Routes.GET_REMINDER);
},
 child: Text(
 action,
 style: TextStyle(
 color: Colors.teal,
 fontSize: 12.sp,
 fontFamily: 'HankenGrotesk',
 ),
 ),
 ),
 ],
);
 }
}
////////////////////////////////////////////////////////////
/// RECENTLY USED
////////////////////////////////////////////////////////////
class RecentlyUsed extends StatelessWidget {
 const RecentlyUsed({super.key});
 @override
 Widget build(BuildContext context) {
 final items = ["Salary", "Grants", "Card", "Awards"];
 final images = [
"assets/images/home salary.png",
 "assets/images/home grants.png",
 "assets/images/home card.png",
 "assets/images/home awards.png",
 ];
 return SizedBox(
 height: 100.h,
 child: ListView.builder(
 scrollDirection: Axis.horizontal,
 itemCount: items.length,
 itemBuilder: (context, index) {
 return Padding(
 padding: const EdgeInsets.all(3.0),
 child: Container(
 height: 92,
 width: 76,
 padding: EdgeInsets.all(15.w),
 decoration: BoxDecoration(
 color: AppColors.cardBgWhite,
 border: BoxBorder.all(color: Color(0xff1EB99A)),
borderRadius: BorderRadius.circular(20.r),
 ),
 child: Column(
 children: [
 Image.asset(images[index], height: 30, width: 30),
 SizedBox(height: 8.h),
 Text(
 items[index],
 style: TextStyle(
 fontSize: 12.sp,
 color: Color(0xff1B1C1A),
 fontWeight: FontWeight(600), 
fontFamily: 'HankenGrotesk',
),
 ),
],
 ),
),
 );
 },
 ),
);
 }
}
////////////////////////////////////////////////////////////
/// CATEGORY ROW
////////////////////////////////////////////////////////////
// class CategoryRow extends StatelessWidget {
//   const CategoryRow({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: items
//           .map(
//             (e) => Column(
//               children: [
//                 Container(
//                   height: 60.w,
//                   width: 60.w,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFF019788), Color(0xFF1BBCAC)],
//                     ),
//                   ),
//                   child: const Icon(Icons.category, color: Colors.white),
//                 ),
//                 SizedBox(height: 6.h),
//                 Text(
//                   e,
//                   style: TextStyle(
//                     fontSize: 11.sp,
//                     fontFamily: 'HankenGrotesk',
//                   ),
//                 ),
//               ],
//             ),
//           )
//           .toList(),
//     );
//   }
// }
////////////////////////////////////////////////////////////
/// INCOME
////////////////////////////////////////////////////////////
class IncomeRow extends StatelessWidget {
const IncomeRow({super.key}); 
@override
Widget build(BuildContext context) {
 final items = ["Lend", "Borrow", "Loans", "Payments"];
final images = [ "assets/images/home lend.png",
"assets/images/home borrow.png",
"assets/images/home loans.png",
 "assets/images/home payments.png",
];
 return SizedBox(
 height: 80.h,
child: ListView.builder(
 scrollDirection: Axis.horizontal,
 itemCount: items.length,
 itemBuilder: (context, index) {
 return Padding(
 padding: const EdgeInsets.all(2.0),
 child: InkWell(
 onTap: () {
 switch (index) {
 case 0:
 Get.toNamed(Routes.LEND_AND_BORROW, arguments: 'lend');
 break;
 case 1:
Get.toNamed(Routes.BorrowView, arguments: 'borrow');
 break;
 case 2:
Get.toNamed(Routes.LoansView, arguments: 'loans');
 break;
 case 3:
 Get.toNamed(Routes.LOAN_CHITFUND, arguments: 'chitfunds');
 break;
 }
 },
child: Container(
 height: 63,
 width: 78,
 padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8.5),
 decoration: BoxDecoration(
 color: AppColors.cardBgWhite,
 border: BoxBorder.all(color: Color(0xff87CFCD)),
borderRadius: BorderRadius.circular(18.r),
 ),
 child: Column(
 children: [
 Image.asset(images[index], height: 30, width: 30),
 SizedBox(height: 3.h),
Text(
items[index],
style: TextStyle(
 fontSize: 12.sp,
 color: Color(0xff1B1C1A),
 fontWeight: FontWeight(600),
 fontFamily: 'HankenGrotesk',
),
),
],
 ),
 ),
 ),
);
 },
 ),
 );
 }
}
////////////////////////////////////////////////////////////
/// EXPENSE
////////////////////////////////////////////////////////////
class ExpenseRow extends StatelessWidget {
 const ExpenseRow({super.key});
 @override
 Widget build(BuildContext context) {
 final items = ["Budget", "Card", "Emi", "Invest"];
 final images = [
 "assets/images/home budget.png",
 "assets/images/home cardex.png",
 "assets/images/home emi.png",
 "assets/images/home invest.png",
 ];
 return SizedBox(
 height: 80.h,
 child: ListView.builder(
 scrollDirection: Axis.horizontal,
 itemCount: items.length,
 itemBuilder: (context, index) {
 return Padding(
 padding: const EdgeInsets.all(2.0),
 child: Container(
 height: 63,
 width: 78,
 padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8.5),
 decoration: BoxDecoration(
 color: AppColors.cardBgWhite,
 border: BoxBorder.all(color: Color(0xff87CFCD)),
 borderRadius: BorderRadius.circular(18.r),
),
child: Column(
children: [
 Image.asset(images[index], height: 30, width: 30),
 SizedBox(height: 3.h),
 Text(
 items[index],
 style: TextStyle(
 fontSize: 12.sp,
 color: Color(0xff1B1C1A),
 fontWeight: FontWeight(600),
 fontFamily: 'HankenGrotesk',
 ),
 ),
 ],
),
 ),
);
 },
),
 );
 }
}
////////////////////////////////////////////////////////////
/// GRID CARDS
////////////////////////////////////////////////////////////
// class ActionGrid extends StatelessWidget {
//   const ActionGrid({super.key});
//   @override
//   Widget build(BuildContext context) {
//     final items = [
//       {
//         "title": "Lend",
//         "icon": Icons.volunteer_activism,
//         "bg": const Color(0xFFF3F3E5),
//         "iconColor": const Color(0xFF0B6B57),
//       },
//       {
//         "title": "Borrow",
//         "icon": Icons.handshake,
//         "bg": const Color(0xFFE6EBFC),
//         "iconColor": const Color(0xFF9E3A2F),
//       },
//       {
//         "title": "Chit Funds",
//         "icon": Icons.trending_up,
//         "bg": const Color(0xFFE2EEFD),
//         "iconColor": const Color(0xFF1C8C6B),
//       },
//       {
//         "title": "Loan",
//         "icon": Icons.volunteer_activism,
//         "bg": const Color(0xFFF5ECE6),
//         "iconColor": const Color(0xFF0B6B57),
//       },
//     ];
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: items.length,
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         mainAxisSpacing: 14.h,
//         crossAxisSpacing: 14.w,
//         childAspectRatio: 2.2,
//       ),
//       itemBuilder: (_, i) {
//         final item = items[i];
//         return InkWell(
//           onTap: () {
//             // if (item['title'].toString() == 'Chit Funds') {
//             //   Get.toNamed(Routes.LOAN_CHITFUND);
//             // }
//             switch (item['title']) {
//               case 'Chit Funds':
//                 Get.toNamed(Routes.LOAN_CHITFUND);
//                 break;
//               case 'Lend':
//                 Get.toNamed(Routes.LEND_AND_BORROW);
//                 break;
//               case 'Borrow':
//                 Get.toNamed(Routes.BorrowView);
//                 break;
//               case 'Loan':
//                 Get.toNamed(Routes.LoansView);
//                 break;
//             }
//           },
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 14.w),
//             decoration: BoxDecoration(
//               color: item["bg"] as Color,
//               borderRadius: BorderRadius.circular(18.r),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.iconLightTeal.withValues(
//                     alpha: 0.5,
//                   ), // teal glow
//                   blurRadius: 1,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   item["icon"] as IconData,
//                   color: item["iconColor"] as Color,
//                   size: 22.sp,
//                 ),
//                 SizedBox(width: 12.w),
//                 Text(
//                   item["title"] as String,
//                   style: TextStyle(
//                     fontSize: 15.sp,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                     fontFamily: 'HankenGrotesk',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
////////////////////////////////////////////////////////////
/// REMINDER
////////////////////////////////////////////////////////////
class ReminderCard extends StatelessWidget {
 final String title;
 final String subtitle;
 final String amount;
 final String date;
 const ReminderCard({
 super.key,
 required this.title,
 required this.subtitle,
 required this.amount,
 required this.date,
});
 @override
 Widget build(BuildContext context) {
return Container(
 margin: EdgeInsets.only(bottom: 14.h),
 padding: EdgeInsets.all(14.w),
 decoration: BoxDecoration(
 color: const Color(0xFFF1F3F4),
 borderRadius: BorderRadius.circular(18.r),
 boxShadow: [
 BoxShadow(
 color: const Color(0x331BBCAC),
 blurRadius: 8,
 offset: const Offset(0, 6),
 ),
 ],
 ),
 child: Row(
 children: [
 /// ICON
 Container(
 height: 50.w,
 width: 50.w,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: const Color(0xFFB8D0CC),
 ),
 child: const Icon(
 Icons.account_balance_wallet,
 color: Color(0xFF1C6F66),
 ),
 ),
 SizedBox(width: 12.w),
 /// TEXT
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 title,
 style: TextStyle(
 fontSize: 15.sp,
 fontWeight: FontWeight.w600,
 fontFamily: 'HankenGrotesk',
 ),
 ),
 SizedBox(height: 2.h),
 Text(
 subtitle,
 style: TextStyle(
 fontSize: 12.sp,
 color: Colors.grey[600],
 fontFamily: 'HankenGrotesk',
 ),
 ),
 ],
 ),
 const Spacer(),
 /// RIGHT SIDE
Column(
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 Text(
amount,
 style: TextStyle(
 color: const Color(0xFFF57C3D),
fontWeight: FontWeight.w600,
 fontSize: 14.sp,
fontFamily: 'HankenGrotesk',
 ),
 ),
 SizedBox(height: 2.h),
 Text(
 date,
 style: TextStyle(
 color: const Color(0xFFB23A2A),
 fontSize: 12.sp,
 fontFamily: 'HankenGrotesk',
 ),
 ),
 ],
 ),
 ],
 ),
);
 }
}