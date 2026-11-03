import 'package:budget_book_2026/app/core/theme/app_colors.dart';
import 'package:budget_book_2026/app/modules/home/widgets/home_widget.dart';
import 'package:budget_book_2026/app/modules/income_expense/controllers/post_income_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PostIncomeView extends GetView<PostIncomeController> {
  const PostIncomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeStyle.background,
      appBar: AppBar(
        backgroundColor: HomeStyle.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: HomeStyle.ink,
            size: 21.sp,
          ),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INCOME', style: _eyebrowStyle()),
            Text(
              'Add income',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 19.sp,
                fontWeight: FontWeight.w700,
                color: HomeStyle.ink,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add income category',
            onPressed: _showAddCategoryDialog,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primaryTeal,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 5.w),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 18.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntro(),
                      SizedBox(height: 22.h),
                      _sectionHeading(
                        'Income category',
                        'Choose where this money comes from',
                        trailing: TextButton.icon(
                          onPressed: _showAddCategoryDialog,
                          icon: Icon(Icons.add_rounded, size: 17.sp),
                          label: const Text('Add new'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryTeal,
                            textStyle: TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 5.w),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildCategories(),
                      SizedBox(height: 22.h),
                      _sectionHeading(
                        'Income details',
                        'Enter the account and transaction information',
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailsCard(),
                      SizedBox(height: 14.h),
                      _buildDescriptionCard(),
                      SizedBox(height: 14.h),
                      _buildFooterNote(),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: HomeStyle.tealLight,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.85),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.south_west_rounded,
              color: AppColors.primaryTeal,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record money received',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: HomeStyle.ink,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Track your income and keep your account balance up to date.',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 11.5.sp,
                    height: 1.35,
                    color: HomeStyle.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: HomeStyle.ink,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 11.5.sp,
                  color: HomeStyle.muted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildCategories() {
    if (controller.isLoadingCategories.value) {
      return SizedBox(
        height: 112.h,
        child: Center(
          child: SizedBox(
            width: 22.w,
            height: 22.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryTeal,
            ),
          ),
        ),
      );
    }

    if (controller.categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(Icons.category_outlined, color: HomeStyle.muted, size: 21.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'No income categories yet. Add one to continue.',
                style: _bodyStyle(),
              ),
            ),
            TextButton(
              onPressed: _showAddCategoryDialog,
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 116.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          final categoryName =
              (category['category_name'] ??
                      category['categoryName'] ??
                      category['name'])
                  ?.toString() ??
              '';
          final imagePath =
              (category['category_image'] ??
                      category['categoryImg'] ??
                      category['image'])
                  ?.toString() ??
              '';
          final iconName = category['icon']?.toString() ?? '';

          return Obx(() {
            final selected = controller.selectedIndex.value == index;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.selectCategory(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 82.w,
                padding: EdgeInsets.fromLTRB(5.w, 7.h, 5.w, 6.h),
                decoration: BoxDecoration(
                  color: selected ? HomeStyle.tealLight : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryTeal.withOpacity(.55)
                        : HomeStyle.border,
                    width: selected ? 1.3 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.5.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryTeal
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24.r,
                        backgroundColor: HomeStyle.tealLight,
                        backgroundImage: imagePath.isNotEmpty
                            ? NetworkImage('https://budgetbook.in/$imagePath')
                            : null,
                        child: imagePath.isEmpty
                            ? Icon(
                                _iconForCategory(iconName),
                                color: AppColors.primaryTeal,
                                size: 21.sp,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontSize: 10.5.sp,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? AppColors.primaryTeal : HomeStyle.ink,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13.sp,
                        color: AppColors.primaryTeal,
                      )
                    else
                      SizedBox(height: 13.sp),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Destination account'),
          SizedBox(height: 7.h),
          Obx(() {
            if (controller.isLoadingAccounts.value) {
              return Container(
                height: 48.h,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: _fieldBoxDecoration(),
                child: Row(
                  children: [
                    SizedBox(
                      width: 17.w,
                      height: 17.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    SizedBox(width: 9.w),
                    Text('Loading accounts...', style: _bodyStyle()),
                  ],
                ),
              );
            }
            if (controller.accounts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: _fieldBoxDecoration(),
                child: Text(
                  'No bank accounts available. Add an account first.',
                  style: _bodyStyle(),
                ),
              );
            }
            return DropdownButtonFormField<String>(
              initialValue: controller.selectedDestinationAccountUuid.value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: HomeStyle.muted,
                size: 22.sp,
              ),
              decoration: _inputDecoration(
                hint: 'Select destination account',
                prefix: Icons.account_balance_outlined,
              ),
              style: _inputTextStyle(),
              items: controller.accounts.map((account) {
                final uuid = (account['uuid'] ?? account['account_uuid'])
                    .toString();
                final name =
                    (account['account_name'] ??
                            account['accountName'] ??
                            account['name'])
                        ?.toString() ??
                    'Bank account';
                return DropdownMenuItem<String>(
                  value: uuid,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                controller.selectedDestinationAccountUuid.value = value;
              },
            );
          }),
          SizedBox(height: 16.h),
          _fieldLabel('Transaction date'),
          SizedBox(height: 7.h),
          InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: controller.pickDate,
            child: Container(
              height: 49.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: _fieldBoxDecoration(),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.primaryTeal,
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Obx(
                      () => Text(
                        controller.selectedDate.value,
                        style: _inputTextStyle(),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit_calendar_outlined,
                    color: HomeStyle.muted,
                    size: 18.sp,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _fieldLabel('Amount'),
          SizedBox(height: 7.h),
          Container(
            height: 58.h,
            padding: EdgeInsets.symmetric(horizontal: 13.w),
            decoration: BoxDecoration(
              color: HomeStyle.tealLight.withOpacity(.55),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primaryTeal.withOpacity(.18)),
            ),
            child: Row(
              children: [
                Text(
                  '₹',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: controller.amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: HomeStyle.ink,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontSize: 18.sp,
                        color: HomeStyle.muted.withOpacity(.7),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          _fieldLabel('Counterparty'),
          SizedBox(height: 7.h),
          TextField(
            controller: controller.counterpartyController,
            textCapitalization: TextCapitalization.words,
            style: _inputTextStyle(),
            decoration: _inputDecoration(
              hint: 'e.g. Employer or client',
              prefix: Icons.person_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Description'),
          SizedBox(height: 7.h),
          TextField(
            controller: controller.noteController,
            maxLines: 3,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: _inputTextStyle(),
            decoration:
                _inputDecoration(
                  hint: 'Add a note about this income (optional)',
                ).copyWith(
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 15.sp, color: HomeStyle.muted),
        SizedBox(width: 7.w),
        Expanded(
          child: Text(
            'The income will be added to the selected account and category.',
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontSize: 10.5.sp,
              height: 1.35,
              color: HomeStyle.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 11.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: HomeStyle.background,
        border: Border(top: BorderSide(color: HomeStyle.border)),
      ),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: controller.isSavingIncome.value
                ? null
                : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    controller.saveIncome();
                  },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primaryTeal,
              disabledBackgroundColor: AppColors.primaryTeal.withOpacity(.55),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13.r),
              ),
            ),
            child: controller.isSavingIncome.value
                ? SizedBox(
                    width: 21.w,
                    height: 21.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 20.sp),
                      SizedBox(width: 7.w),
                      Text(
                        'Save income',
                        style: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
    label,
    style: TextStyle(
      fontFamily: 'HankenGrotesk',
      fontSize: 11.5.sp,
      fontWeight: FontWeight.w600,
      color: HomeStyle.muted,
    ),
  );

  TextStyle _bodyStyle() => TextStyle(
    fontFamily: 'HankenGrotesk',
    fontSize: 12.sp,
    color: HomeStyle.muted,
  );

  TextStyle _inputTextStyle() => TextStyle(
    fontFamily: 'HankenGrotesk',
    fontSize: 12.5.sp,
    fontWeight: FontWeight.w600,
    color: HomeStyle.ink,
  );

  InputDecoration _inputDecoration({String? hint, IconData? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'HankenGrotesk',
        fontSize: 12.sp,
        color: HomeStyle.muted.withOpacity(.8),
      ),
      prefixIcon: prefix == null
          ? null
          : Icon(prefix, size: 18.sp, color: HomeStyle.muted),
      filled: true,
      fillColor: const Color(0xFFFAFCFB),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: BorderSide(color: HomeStyle.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: BorderSide(
          color: AppColors.primaryTeal.withOpacity(.75),
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16.r),
    border: Border.all(color: HomeStyle.border),
    boxShadow: [
      BoxShadow(
        color: HomeStyle.ink.withOpacity(.025),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  BoxDecoration _fieldBoxDecoration() => BoxDecoration(
    color: const Color(0xFFFAFCFB),
    borderRadius: BorderRadius.circular(11.r),
    border: Border.all(color: HomeStyle.border),
  );

  TextStyle _eyebrowStyle() => TextStyle(
    fontFamily: 'HankenGrotesk',
    fontSize: 9.sp,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    color: AppColors.primaryTeal,
  );

  IconData _iconForCategory(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'salary':
      case 'work':
        return Icons.payments_outlined;
      case 'gift':
      case 'bonus':
        return Icons.redeem_outlined;
      case 'interest':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'rent':
        return Icons.home_work_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedIcon = 'salary';

    try {
      await Get.dialog<void>(
        StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
              side: BorderSide(color: HomeStyle.border),
            ),
            titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 5.h),
            contentPadding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 8.h),
            actionsPadding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 14.h),
            title: Text(
              'Add income category',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: HomeStyle.ink,
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 13.sp,
                      color: HomeStyle.ink,
                    ),
                    decoration: _dialogInputDecoration(
                      label: 'Category name',
                      hint: 'e.g. Freelance',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a category name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 13.h),
                  DropdownButtonFormField<String>(
                    initialValue: selectedIcon,
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 13.sp,
                      color: HomeStyle.ink,
                    ),
                    decoration: _dialogInputDecoration(label: 'Category icon'),
                    items: const [
                      DropdownMenuItem(value: 'salary', child: Text('Salary')),
                      DropdownMenuItem(value: 'work', child: Text('Work')),
                      DropdownMenuItem(value: 'gift', child: Text('Gift')),
                      DropdownMenuItem(
                        value: 'investment',
                        child: Text('Investment'),
                      ),
                      DropdownMenuItem(value: 'rent', child: Text('Rent')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedIcon = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  foregroundColor: HomeStyle.muted,
                  textStyle: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isCreatingCategory.value
                      ? null
                      : () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          final category = await controller
                              .createIncomeCategory(
                                name: nameController.text.trim(),
                                icon: selectedIcon,
                              );

                          if (category == null) {
                            Get.snackbar(
                              'Unable to create category',
                              'Please check your connection and try again.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: HomeStyle.ink,
                              colorText: Colors.white,
                              margin: EdgeInsets.all(12.w),
                              borderRadius: 12.r,
                            );
                            return;
                          }

                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          }
                          Get.snackbar(
                            'Category added',
                            category['name']?.toString() ??
                                'Income category created successfully.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primaryTeal,
                            colorText: Colors.white,
                            margin: EdgeInsets.all(12.w),
                            borderRadius: 12.r,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 17.w,
                      vertical: 10.h,
                    ),
                  ),
                  child: controller.isCreatingCategory.value
                      ? SizedBox(
                          width: 17.w,
                          height: 17.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Create category',
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } finally {
      nameController.dispose();
    }
  }

  InputDecoration _dialogInputDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        fontFamily: 'HankenGrotesk',
        fontSize: 12.sp,
        color: HomeStyle.muted,
      ),
      hintStyle: TextStyle(
        fontFamily: 'HankenGrotesk',
        fontSize: 12.sp,
        color: HomeStyle.muted.withOpacity(.75),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFCFB),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: BorderSide(color: HomeStyle.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: BorderSide(color: AppColors.primaryTeal, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
