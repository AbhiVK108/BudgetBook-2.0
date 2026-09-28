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
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
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
            // color: Colors.teal,
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

////////////////////////////////////////////////////////////
/// RECENTLY USED
////////////////////////////////////////////////////////////

class RecentlyUsed extends StatelessWidget {
  const RecentlyUsed({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ["Salary", "Card", "Grants", "Awards"];

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map(
              (e) => Column(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: AssetImage('assets/images/categories.jpg'),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    e,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontFamily: 'HankenGrotesk',
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// CATEGORY ROW
////////////////////////////////////////////////////////////

class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ["Lend", "Borrow", "Loans", "Chit Fund"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map(
            (e) => Column(
              children: [
                Container(
                  height: 60.w,
                  width: 60.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF019788), Color(0xFF1BBCAC)],
                    ),
                  ),
                  child: const Icon(Icons.category, color: Colors.white),
                ),
                SizedBox(height: 6.h),
                Text(
                  e,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

////////////////////////////////////////////////////////////
/// INCOME
////////////////////////////////////////////////////////////

class IncomeRow extends StatelessWidget {
  const IncomeRow({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "title": "Lend",
        "icon": Icons.volunteer_activism,
        "bg": const Color(0xFFE8F5E9),
        "color": AppColors.primaryTeal,
      },
      {
        "title": "Borrow",
        "icon": Icons.handshake,
        "bg": const Color(0xFFFFEBEE),
        "color": AppColors.iconRed,
      },
      {
        "title": "Loans",
        "icon": Icons.account_balance,
        "bg": const Color(0xFFE3F2FD),
        "color": Colors.blue,
      },
      {
        "title": "Chit Fund",
        "icon": Icons.groups,
        "bg": const Color(0xFFF3E5F5),
        "color": Colors.purple,
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        return Column(
          children: [
            InkWell(
              onTap: () {
                Get.toNamed(Routes.IndivPostIncomeView);
              },
              child: Container(
                height: 52.w,
                width: 52.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item["bg"] as Color,
                ),
                child: Icon(
                  item["icon"] as IconData,
                  color: item["color"] as Color,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              item["title"] as String,
              style: TextStyle(fontSize: 11.sp, fontFamily: 'HankenGrotesk'),
            ),
          ],
        );
      }).toList(),
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
    final items = [
      {
        "title": "Budget",
        "icon": Icons.calculate,
        "bg": const Color(0xFFFFF3E0),
        "color": Colors.orange,
      },
      {
        "title": "Card",
        "icon": Icons.credit_card,
        "bg": const Color(0xFFEDE7F6),
        "color": Colors.deepPurple,
      },
      {
        "title": "EMI",
        "icon": Icons.history,
        "bg": const Color(0xFFFFEBEE),
        "color": Colors.red,
      },
      {
        "title": "More",
        "icon": Icons.trending_up,
        "bg": const Color(0xFFE0F2F1),
        "color": Colors.teal,
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        return Column(
          children: [
            Container(
              height: 52.w,
              width: 52.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item["bg"] as Color,
              ),
              child: Icon(
                item["icon"] as IconData,
                color: item["color"] as Color,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              item["title"] as String,
              style: TextStyle(fontSize: 11.sp, fontFamily: 'HankenGrotesk'),
            ),
          ],
        );
      }).toList(),
    );
  }
}

////////////////////////////////////////////////////////////
/// GRID CARDS
////////////////////////////////////////////////////////////

class ActionGrid extends StatelessWidget {
  const ActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "title": "Lend",
        "icon": Icons.volunteer_activism,
        "bg": const Color(0xFFF3F3E5),
        "iconColor": const Color(0xFF0B6B57),
      },
      {
        "title": "Borrow",
        "icon": Icons.handshake,
        "bg": const Color(0xFFE6EBFC),
        "iconColor": const Color(0xFF9E3A2F),
      },
      {
        "title": "Chit Funds",
        "icon": Icons.trending_up,
        "bg": const Color(0xFFE2EEFD),
        "iconColor": const Color(0xFF1C8C6B),
      },
      {
        "title": "Loan",
        "icon": Icons.volunteer_activism,
        "bg": const Color(0xFFF5ECE6),
        "iconColor": const Color(0xFF0B6B57),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 14.w,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (_, i) {
        final item = items[i];

        return InkWell(
          onTap: () {
            // if (item['title'].toString() == 'Chit Funds') {
            //   Get.toNamed(Routes.LOAN_CHITFUND);
            // }

            switch (item['title']) {
              case 'Chit Funds':
                Get.toNamed(Routes.LOAN_CHITFUND);
                break;

              case 'Lend':
                Get.toNamed(Routes.LEND_AND_BORROW);
                break;

              case 'Borrow':
                Get.toNamed(Routes.BorrowView);
                break;

              case 'Loan':
                Get.toNamed(Routes.LoansView);
                break;
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: item["bg"] as Color,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.iconLightTeal.withOpacity(0.5), // teal glow
                  blurRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  item["icon"] as IconData,
                  color: item["iconColor"] as Color,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  item["title"] as String,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'HankenGrotesk',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
