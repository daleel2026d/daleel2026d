import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';

import '../services/content_sanitizer.dart';

class CustomCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final double iconSize;

  const CustomCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.account_balance_rounded,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = ContentSanitizer.sanitizeImageUrl(imageUrl);
    if (cleanUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    final widget = CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      // Optimize memory usage by caching decoded image at sensible dimensions
      memCacheWidth: width != null && width != double.infinity ? (width! * 2).toInt() : 800,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => _buildPlaceholder(context, isLoading: true),
      errorWidget: (context, url, error) => _buildPlaceholder(context),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: widget,
      );
    }

    return widget;
  }

  Widget _buildPlaceholder(BuildContext context, {bool isLoading = false}) {
    final container = Container(
      width: width,
      height: height,
      color: AppColors.lavenderCard(context),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.isDark(context)
                      ? const Color(0xFF38BDF8)
                      : AppColors.primaryDark,
                ),
              )
            : Icon(
                placeholderIcon,
                size: iconSize,
                color: AppColors.textMuted(context).withValues(alpha: 0.5),
              ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: container,
      );
    }
    return container;
  }
}
