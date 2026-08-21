import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/app_state.dart';
import '../../data/whatsapp_link.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../listing/listing_detail_screen.dart';

/// Conversation rattachée à une annonce, avec négociation intégrée sous forme
/// d'offre structurée (accepter / refuser / contre-offre).
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.openOfferSheet = false,
  });

  final String conversationId;
  final bool openOfferSheet;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _random = Random();
  Timer? _replyTimer;
  bool _otherIsTyping = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final state = AppScope.read(context);
    state.markConversationRead(widget.conversationId);
    if (widget.openOfferSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openOfferSheet();
      });
    }
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      // La liste est inversée : le bas correspond à l'offset 0.
      _scrollController.animateTo(
        0,
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
      );
    });
  }

  void _send(AppState state, Conversation conversation) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    state.sendMessage(conversation.id, text);
    _controller.clear();
    _scrollToBottom();
    _simulateReply(state, conversation);
  }

  /// Démonstration : le vendeur « répond » après quelques secondes, précédé
  /// d'un indicateur de saisie. Sans backend, c'est ce qui donne à la
  /// messagerie son impression de conversation vivante.
  void _simulateReply(AppState state, Conversation conversation) {
    const replies = [
      'Oui bien sûr, quand souhaitez-vous passer ?',
      'C\'est encore disponible 🙂',
      'Merci pour votre message, je vous réponds dès que possible.',
      'On peut se retrouver en fin de journée si ça vous va.',
      'Merci, je regarde ça et je reviens vers vous.',
    ];

    _replyTimer?.cancel();
    setState(() => _otherIsTyping = true);
    _replyTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _otherIsTyping = false);
      state.receiveMessage(
        conversation.id,
        conversation.otherUser.id,
        replies[_random.nextInt(replies.length)],
      );
      _scrollToBottom();
    });
  }

  void _openOfferSheet() {
    final state = AppScope.read(context);
    final conversation = state.conversationById(widget.conversationId);
    if (conversation == null) return;
    final listing = state.listingById(conversation.listingId);
    final offerController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final amount = int.tryParse(offerController.text) ?? 0;
            final price = listing?.price ?? 0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Faire une offre',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  listing == null
                      ? 'Proposez votre prix'
                      : 'Prix affiché : ${listing.formattedPrice}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: offerController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Votre offre',
                    suffixText: 'FCFA',
                    prefixIcon: Icon(Icons.local_offer_outlined, size: 18),
                  ),
                ),
                if (price > 0) ...[
                  const SizedBox(height: 12),
                  // Suggestions de montants : -10 %, -20 %, -30 % du prix.
                  Wrap(
                    spacing: 8,
                    children: [0.9, 0.8, 0.7].map((ratio) {
                      final suggestion = ((price * ratio) / 500).round() * 500;
                      return ActionChip(
                        label: Text('${formatAmount(suggestion)} F'),
                        onPressed: () {
                          offerController.text = '$suggestion';
                          setSheetState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: amount <= 0
                        ? null
                        : () {
                            state.sendOffer(conversation.id, amount);
                            Navigator.pop(sheetContext);
                            _scrollToBottom();
                          },
                    child: const Text('Envoyer l\'offre'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ).whenComplete(offerController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final conversation = state.conversationById(widget.conversationId);

    if (conversation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conversation')),
        body: const EmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Conversation introuvable',
          message: 'Cette discussion n\'existe plus.',
        ),
      );
    }

    final listing = state.listingById(conversation.listingId);
    final messages = conversation.messages.reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            InitialsAvatar(
              initials: conversation.otherUser.initials,
              seed: conversation.otherUser.id,
              radius: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conversation.otherUser.publicName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Text(
                      _otherIsTyping ? 'en train d\'écrire…' : 'en ligne',
                      key: ValueKey(_otherIsTyping),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.background.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if ((conversation.otherUser.phone ?? '').isNotEmpty)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
              tooltip: 'Continuer sur WhatsApp',
              onPressed: () => openWhatsApp(
                conversation.otherUser.phone!,
                message: listing == null
                    ? 'Bonjour, je vous contacte depuis JaBa.'
                    : 'Bonjour, je vous contacte depuis JaBa au sujet de '
                        '« ${listing.title} ».',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (listing != null) _buildListingBanner(listing),
          Expanded(
            child: messages.isEmpty && !_otherIsTyping
                ? EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Démarrez la conversation',
                    message: listing == null
                        ? 'Envoyez un premier message.'
                        : 'Demandez si « ${listing.title} » est toujours disponible.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    itemCount: messages.length + (_otherIsTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_otherIsTyping && i == 0) return const _TypingBubble();
                      final message = messages[i - (_otherIsTyping ? 1 : 0)];
                      return _MessageBubble(
                        message: message,
                        onRespond: (status) => state.respondToOffer(
                          conversation.id,
                          message.id,
                          status,
                        ),
                        onCounterOffer: _openOfferSheet,
                      );
                    },
                  ),
          ),
          _buildComposer(state, conversation),
        ],
      ),
    );
  }

  Widget _buildListingBanner(Listing listing) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ListingDetailScreen(
              listingId: listing.id,
              heroPrefix: 'chat',
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: ListingPhoto(path: listing.coverPhoto),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${listing.formattedPrice} · ${listing.zone}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(AppState state, Conversation conversation) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.local_offer_outlined, color: AppColors.accent),
                onPressed: _openOfferSheet,
                tooltip: 'Faire une offre',
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _send(state, conversation),
                  decoration: InputDecoration(
                    hintText: 'Écrire un message…',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Le bouton d'envoi ne s'active que s'il y a quelque chose à envoyer.
              AnimatedScale(
                duration: AppMotion.fast,
                scale: _controller.text.trim().isEmpty ? 0.85 : 1,
                child: Material(
                  color: _controller.text.trim().isEmpty
                      ? AppColors.border
                      : AppColors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _send(state, conversation),
                    child: const Padding(
                      padding: EdgeInsets.all(11),
                      child: Icon(Icons.send, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bulle « en train d'écrire » : trois points qui pulsent.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(3),
          ),
          boxShadow: AppShadows.card,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_controller.value - i * 0.2) % 1.0;
              final scale = 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onRespond,
    required this.onCounterOffer,
  });

  final ChatMessage message;
  final ValueChanged<OfferStatus> onRespond;
  final VoidCallback onCounterOffer;

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == 'me';

    if (message.type == MessageType.systeme) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            message.content ?? '',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (message.type == MessageType.offre) {
      return _OfferBubble(
        message: message,
        isMe: isMe,
        onRespond: onRespond,
        onCounterOffer: onCounterOffer,
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 3),
            bottomRight: Radius.circular(isMe ? 3 : 14),
          ),
          boxShadow: isMe ? null : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content ?? '',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isMe ? AppColors.background : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.timeLabel,
              style: TextStyle(
                fontSize: 9.5,
                color: isMe
                    ? AppColors.background.withValues(alpha: 0.6)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offre structurée : montant mis en avant, statut, et actions de réponse
/// quand elle vient de l'interlocuteur.
class _OfferBubble extends StatelessWidget {
  const _OfferBubble({
    required this.message,
    required this.isMe,
    required this.onRespond,
    required this.onCounterOffer,
  });

  final ChatMessage message;
  final bool isMe;
  final ValueChanged<OfferStatus> onRespond;
  final VoidCallback onCounterOffer;

  @override
  Widget build(BuildContext context) {
    final status = message.offerStatus ?? OfferStatus.enAttente;
    final settled = status != OfferStatus.enAttente;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(13),
        constraints: const BoxConstraints(maxWidth: 264),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          border: Border.all(color: AppColors.accent),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, size: 13, color: Color(0xFF993C1D)),
                const SizedBox(width: 5),
                Text(
                  isMe ? 'VOTRE OFFRE' : 'OFFRE REÇUE',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF993C1D),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatAmount(message.offerAmount ?? 0)} F',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A1B0C),
              ),
            ),
            const SizedBox(height: 6),
            if (settled)
              Row(
                children: [
                  Icon(
                    status == OfferStatus.acceptee
                        ? Icons.check_circle
                        : (status == OfferStatus.refusee
                            ? Icons.cancel
                            : Icons.swap_horiz),
                    size: 13,
                    color: status == OfferStatus.acceptee
                        ? AppColors.success
                        : (status == OfferStatus.refusee
                            ? AppColors.danger
                            : AppColors.warning),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: status == OfferStatus.acceptee
                          ? AppColors.success
                          : (status == OfferStatus.refusee
                              ? AppColors.danger
                              : AppColors.warning),
                    ),
                  ),
                ],
              )
            else if (isMe)
              Text(
                status.label,
                style: TextStyle(fontSize: 10.5, color: Colors.brown.shade400),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: AppColors.success,
                      ),
                      onPressed: () => onRespond(OfferStatus.acceptee),
                      child: const Text('Accepter', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => onRespond(OfferStatus.refusee),
                      child: const Text('Refuser', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onCounterOffer,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Proposer une contre-offre',
                      style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
