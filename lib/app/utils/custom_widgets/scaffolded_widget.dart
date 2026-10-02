import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../config/app_assets.dart';
import '../../config/app_fontweights.dart';
import '../../config/app_size_config.dart';
import '../utils.dart';
import 'common_text.dart';
import 'custom_appbar.dart';

class ScafoldedWidget extends StatelessWidget {
  final bool? showAppBar;
  final bool? isBottomVisible;
  final Widget body;
  final Widget? bottomWidget;
  final Color? bgColor;
  // final Gradient? gradient;
  final Function()? onScaffoldTap;
  final PreferredSizeWidget? appBar;
  final String? title;
  final Function()? onLeadingTap;
  final double? bottomWidPadding;
  final bool? resizeToAvoidBottomInset;
  final GlobalKey? scaffoldKey;
  final bool? showDrawer;
  final bool? extendBodyBehindAppBar;
  final Function()? onWillPop;
  final bool? isBodyScrollable;
  final bool? showHeaderLogo;
  final bool? showBGImg;
  final Widget? leadingIcon;
  final double? bodyHorizontalPadding;
  final bool? isPadingBeforeBody;
  const ScafoldedWidget({
    super.key,
    required this.body,
    this.onScaffoldTap,
    // this.gradient
    this.bgColor,
    this.showAppBar = true,
    this.isBottomVisible = false,
    this.bottomWidget,
    this.appBar,
    this.title,
    this.onWillPop,
    this.onLeadingTap,
    this.bottomWidPadding = 20,
    this.resizeToAvoidBottomInset = true,
    this.scaffoldKey,
    this.showDrawer = false,
    this.extendBodyBehindAppBar = true,
    this.leadingIcon,
    this.showHeaderLogo = true,
    this.showBGImg = true,
    this.isBodyScrollable = true,
    this.bodyHorizontalPadding = 15,
    this.isPadingBeforeBody = true,
  });

  @override
  Widget build(BuildContext context) {
    HeightWidth(context);
    var theme = context.theme.colorScheme;
    return WillPopScope(
      onWillPop: onWillPop == null
          ? () async {
              Get.back();
              return true;
            }
          : () async {
              onWillPop!();
              return true;
            },
      child: AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: bgColor ?? theme.surface,
          key: scaffoldKey,
          drawer: null, // showDrawer! ? const DrawerView() : null,
          appBar: showAppBar! == false
              ? appBar ??
                  AppBar(
                    systemOverlayStyle: const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark, statusBarColor: Colors.transparent),
                    scrolledUnderElevation: 0.0,
                    elevation: 0.0,
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                  )
              : ScafoldedAppBar(
                  isAction: true,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: GestureDetector(
                      onTap: onLeadingTap ?? () => Get.back(),
                      child: leadingIcon ?? Icon(Icons.menu, color: theme.surfaceContainer, size: 30),
                    ),
                  ),
                  title: CommonText(
                    text: title ?? '',
                    color: theme.surfaceTint,
                    fontSize: 18,
                    weight: AppFontWeights.appTextFontWeightMedium,
                  ),
                  // action: // LOGO ----------------------------------------
                  /*   GestureDetector(
                    onTap: () {
                      Get.toNamed(PagesNames.memberPointsScreen);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Image.asset(
                        Utils.getImagePath('ClientLogo'), // 'assets/images/ClientLogo.png',
                      ),
                    ),
                  ),
                  */
                ),
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          extendBody: true,
          extendBodyBehindAppBar: extendBodyBehindAppBar!,
          persistentFooterAlignment: AlignmentDirectional.bottomCenter,
          body: GestureDetector(
            onTap: onScaffoldTap ?? () => Get.focusScope!.unfocus(),
            child: SizedBox(
              height: h,
              width: w,
              // decoration: BoxDecoration(color: bgColor ?? theme.surface.withValues(alpha: 0.6)
              // gradient: gradient ?? Utils.gradeBlue(),
              // ),
              child: Stack(
                children: [
                  /*Visibility(
                    visible: (showBGImg!
                        // && (AppConfigStore.to.appTheme['BackgroundImageUrl'] != null && AppConfigStore.to.appTheme['BackgroundImageUrl'].isNotEmpty) == true
                        ) ==
                        true,
                    child: Positioned.fill(
                        child: Image.network(
                      // Utils.getImagePath(AppAssets.bg),
                      '${UrlsStore.to.apiUrl}/${bgImagePath}',
                      // ${AppConfigStore.to.appTheme['BackgroundImageUrl']}',
                      fit: BoxFit.cover,
                      width: Get.width,
                      height: Get.height,
                    )),
                  ),*/
                  SingleChildScrollView(
                    physics: isBodyScrollable! ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Visibility(
                          visible: showHeaderLogo!,
                          child: Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints.tightFor(height: 110),
                              child: Image.asset(Utils.getImagePath(AppAssets.images.tFavIcon)),
                            ).marginOnly(top: 30).animateToBottom(),
                          ),
                        ),

                        // Login Forms --------------------
                      isPadingBeforeBody == true ?  0.015.ph : const SizedBox.shrink(),

                        body
                      ],
                    ).paddingSymmetric(horizontal: bodyHorizontalPadding!),
                  ),
                ],
              ),

              // body,
            ),
          ),
          bottomNavigationBar: isBottomVisible!
              ? Padding(
                  padding: EdgeInsets.only(bottom: bottomWidPadding!),
                  child: bottomWidget,
                )
              : null,
        ),
      ),
    );
  }
}
