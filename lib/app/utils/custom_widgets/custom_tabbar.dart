import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_fontweights.dart';
import '../../config/app_paddings.dart';
import '../../config/app_size_config.dart';

// Pill style TabBar with optional count badges per tab.
// tabsNotificationList[i] is shown as a badge on tab i (tab 0 never shows a badge).
class CustomTabBar extends StatelessWidget {
  final List<int>? tabsNotificationList;
  final List<String> tabsList;
  final TabController tabController;
  final bool isLoading;
  const CustomTabBar({super.key, this.tabsNotificationList, required this.tabsList, required this.tabController, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    HeightWidth(context);
    final counts = tabsNotificationList ?? [];

    return Container(
      height: 35,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TabBar(
          onTap: (index) {
            Get.focusScope!.unfocus();
          },
          dividerColor: Colors.transparent,
          padding: EdgeInsets.zero,
          unselectedLabelColor: Colors.grey[800],
          labelColor: theme.onSecondary,
          indicator: BoxDecoration(color: theme.secondary, borderRadius: BorderRadius.circular(10.0)),
          indicatorPadding: EdgeInsets.zero,
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          controller: tabController,
          tabs: List.generate(tabsList.length, (i) {
            return counts.length > i
                ? Tab(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        i == 0 || isLoading
                            ? const SizedBox.shrink()
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                height: 25.0,
                                decoration: BoxDecoration(
                                  color: theme.onPrimary,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Center(
                                  child: Text(
                                    '${counts[i]}',
                                    style: TextStyle(
                                      color: theme.primary,
                                      fontWeight: AppFontWeights.appTextFontWeightLight,
                                    ),
                                  ),
                                ),
                              ),
                        Padding(
                          padding: const EdgeInsets.only(left: AppPaddings.appMainPaddingExtraSmall),
                          child: Tab(
                            child: Text(
                              tabsList[i],
                              style: TextStyle(
                                color: theme.onSecondary,
                                fontSize: AppFontSizes.appFontSizeh11,
                                fontWeight: AppFontWeights.appTextFontWeightLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Tab(
                    child: Text(
                      tabsList[i],
                      style: TextStyle(
                        color: theme.onSecondary,
                        fontSize: AppFontSizes.appFontSizeh10,
                        fontWeight: AppFontWeights.appTextFontWeightLight,
                      ),
                    ),
                  );
          })),
    );
  }
}
