import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../domain/models/opportunity.dart';

class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.isSaved,
    required this.onTap,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImageWidget(context, opportunity.imageUrl, isDarkMode),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      opportunity.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onSaveToggle,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppTheme.darkCard : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? AppTheme.primaryGreen : AppTheme.mediumGray,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opportunity.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          opportunity.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opportunity.timeCommitment,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, String imageUrl, bool isDarkMode) {
    // Check if it's a base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract the base64 part after the comma
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          child: Image.memory(
            bytes,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Error loading base64 image: $error');
              return _buildPlaceholder(context, isDarkMode);
            },
          ),
        );
      } catch (e) {
        print('❌ Error decoding base64 image: $e');
        return _buildPlaceholder(context, isDarkMode);
      }
    }
    
    // It's a network URL
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: isDarkMode ? AppTheme.darkCard : AppTheme.lightGray,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) {
          print('❌ Error loading network image: $error');
          return _buildPlaceholder(context, isDarkMode);
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isDarkMode) {
    return Container(
      height: 200,
      color: isDarkMode ? AppTheme.darkCard : AppTheme.lightGray,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: AppTheme.mediumGray,
        ),
      ),
    );
  }
}