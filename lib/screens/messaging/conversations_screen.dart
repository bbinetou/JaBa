import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/common.dart';
import 'chat_screen.dart';

/// Liste des conversations, classées par activité la plus récente, avec
/// indicateur de messages non lus — section 5.6 du cahier des charges.
///
/// Chaque ligne affiche la photo réelle de l'annonce concernée : on retrouve
/// d'un coup d'œil de quel article on parlait.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final conversations = state.conversations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          if (state.unreadCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${state.unreadCount} non lu${state.unreadCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: conversations.isEmpty
          ? const EmptyState(
              icon: Icons.forum_outlined,
              title: 'Aucune conversation',
              message: 'Contactez un vendeur depuis une annonce pour démarrer '
                  'une discussion.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 6, bottom: 100),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 78,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 40 * index),
                  offset: 12,
                  child: _ConversationTile(
                    conversation: conversation,
                    listing: state.listingById(conversation.listingId),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(conversationId: conversation.id),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.listing,
    required this.onTap,
  });

  final Conversation conversation;
  final Listing? listing;
  final VoidCallback onTap;

  /// Horodatage relatif de la dernière activité.
  String get _timeLabel {
    final last = conversation.lastMessage;
    if (last == null) return '';
    final diff = DateTime.now().difference(last.timestamp);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return '${diff.inDays} j';
    return '${diff.inDays ~/ 7} sem.';
  }

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;

    return Material(
      color: unread
          ? AppColors.primary.withValues(alpha: 0.04)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vignette de l'annonce + pastille avatar de l'interlocuteur.
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: ListingPhoto(path: listing?.coverPhoto),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                        child: InitialsAvatar(
                          initials: conversation.otherUser.initials,
                          seed: conversation.otherUser.id,
                          radius: 11,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherUser.publicName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: unread ? AppColors.accent : AppColors.textSecondary,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (listing != null)
                      Text(
                        listing!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (conversation.lastMessage?.type == MessageType.offre) ...[
                          const Icon(Icons.local_offer,
                              size: 12, color: AppColors.accent),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            conversation.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: unread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            constraints: const BoxConstraints(minWidth: 20),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
