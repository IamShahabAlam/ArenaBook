// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:arenabook/app/utils/utils.dart';

import '../../config/app_assets.dart';

class PlaceholderNetworkImg extends StatelessWidget {
  PlaceholderNetworkImg({super.key, required this.networkImg, this.assetImg = 'placeholder.png', this.fit = BoxFit.fill, this.picHeight = 100, this.picWidth});

  final String networkImg, assetImg;
  final BoxFit? fit;

  final dynamic picHeight;
  double? picWidth;
  @override
  Widget build(BuildContext context) {
    return FadeInImage(
      fit: fit,
      placeholder: AssetImage('assets/images/$assetImg'), // 'assets/images/placehold.png'.animate().shimmer(), // TODO : TRY SHIMMER
      image: NetworkImage(networkImg), //{promoItem['Image']['Medium']}
      imageErrorBuilder: (context, error, stackTrace) =>
          Image.asset(Utils.getImagePath(AppAssets.images.placeHolder), fit: fit, height: picHeight.toDouble(), width: picWidth ?? double.maxFinite),
      fadeInDuration: const Duration(milliseconds: 500),
      height: picHeight.toDouble(),
      width: picWidth ?? double.maxFinite,
    );
  }
}
