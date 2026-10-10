import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../main.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import 'custom_cached_image.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String universityName;
  final String universityLogo;
  final String? badgeText;
  final Color? badgeColor;

  const PostCard({
    super.key,
    required this.post,
    required this.universityName,
    required this.universityLogo,
    this.badgeText,
    this.badgeColor,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLiked = false;
  late String _postKey;

  @override
  void initState() {
    super.initState();
    _postKey =
        '${widget.universityName}_${widget.post.title}_${widget.post.date}';
    _checkInitialLike();
  }

  void _checkInitialLike() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _firestoreService.getUserData(uid).listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final likedList = List<String>.from(data['likedPosts'] ?? []);
        setState(() {
          _isLiked = likedList.contains(_postKey);
        });
      }
    });
  }

  Future<void> _toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isAr(context)
                ? 'يرجى تسجيل الدخول للإعجاب بالمنشور'
                : 'Please log in to like this post',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.isDark(context)
              ? const Color(0xFF1E293B)
              : AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final previousState = _isLiked;
    setState(() => _isLiked = !previousState);

    try {
      await _firestoreService.toggleLikePost(uid, _postKey, previousState);
    } catch (_) {
      if (mounted) {
        setState(() => _isLiked = previousState);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppStrings.isAr(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المنشور (Header)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CustomCachedImage(
                  imageUrl: widget.universityLogo,
                  width: 38,
                  height: 38,
                  borderRadius: BorderRadius.circular(19),
                  placeholderIcon: Icons.account_balance,
                  iconSize: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.universityName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textMain(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.post.date,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (widget.badgeColor ?? const Color(0xFF0284C7))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.badgeText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.badgeColor ?? const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  icon: Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isLiked ? Colors.red : AppColors.textMuted(context),
                    size: 22,
                  ),
                  onPressed: _toggleLike,
                  tooltip: _isLiked
                      ? (isAr ? 'إلغاء الإعجاب' : 'Unlike')
                      : (isAr ? 'إعجاب' : 'Like'),
                ),
              ],
            ),
          ),

          // عنوان المنشور
          if (widget.post.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.post.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textMain(context),
                ),
              ),
            ),

          // نص المنشور
          if (widget.post.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Text(
                widget.post.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textMain(context),
                ),
              ),
            ),

          // الصورة الكبيرة
          if (widget.post.imageUrl.isNotEmpty)
            CustomCachedImage(
              imageUrl: widget.post.imageUrl,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              placeholderIcon: Icons.image_rounded,
              iconSize: 36,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
