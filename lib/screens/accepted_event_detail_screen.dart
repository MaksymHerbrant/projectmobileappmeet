import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../models/user_profile.dart';
import 'chat_screen.dart';
import 'user_profile_view_screen.dart';

class AcceptedEventDetailScreen extends StatefulWidget {
  final Event event;
  final UserProfile organizer;
  final DateTime acceptedAt;
  final String? invitationMessage;

  const AcceptedEventDetailScreen({
    Key? key,
    required this.event,
    required this.organizer,
    required this.acceptedAt,
    this.invitationMessage,
  }) : super(key: key);

  @override
  State<AcceptedEventDetailScreen> createState() => _AcceptedEventDetailScreenState();
}

class _AcceptedEventDetailScreenState extends State<AcceptedEventDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  // Mock participants data
  final List<UserProfile> _participants = [
    UserProfile(
      id: '1',
      name: 'Олександр',
      age: 25,
      description: 'Люблю активний відпочинок',
      photos: ['assets/images/portrait-man-laughing.jpg'],
      location: 'Київ',
      hobbies: ['Спорт', 'Музика'],
    ),
    UserProfile(
      id: '2',
      name: 'Марія',
      age: 23,
      description: 'Фотограф та мандрівниця',
      photos: ['assets/images/uifaces-popular-image-3.jpg'],
      location: 'Київ',
      hobbies: ['Фотографія', 'Подорожі'],
    ),
    UserProfile(
      id: '3',
      name: 'Дмитро',
      age: 28,
      description: 'IT спеціаліст',
      photos: ['assets/images/selfie-portrait-videocall.jpg'],
      location: 'Київ',
      hobbies: ['Програмування', 'Геймінг'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAcceptedBanner(t),
                      const SizedBox(height: 24),
                      _buildEventInfo(t),
                      const SizedBox(height: 24),
                      _buildDateTimeSection(t),
                      const SizedBox(height: 24),
                      _buildOrganizerSection(t),
                      if (widget.invitationMessage?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 24),
                        _buildInvitationMessage(t),
                      ],
                      if (widget.event.isPrivate) ...[
                        const SizedBox(height: 24),
                        _buildPrivateInfo(t),
                      ],
                      const SizedBox(height: 24),
                      _buildParticipantsSection(t),
                      const SizedBox(height: 24),
                      _buildTagsSection(t),
                      const SizedBox(height: 24),
                      _buildActionButtons(t),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            onPressed: _shareEvent,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPhotoIndex = index;
                });
              },
              itemCount: widget.event.photos.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  widget.event.photos[index],
                  fit: BoxFit.cover,
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            if (widget.event.photos.length > 1)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.event.photos.asMap().entries.map((entry) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPhotoIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.event.location,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
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

  Widget _buildAcceptedBanner(AppLocalizations t) {
    final daysUntilEvent = widget.event.dateTime.difference(DateTime.now()).inDays;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).extension<AppSemantics>()!.success, Theme.of(context).extension<AppSemantics>()!.success],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).extension<AppSemantics>()!.success.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.surface,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.ae_going,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  daysUntilEvent > 0 
                      ? AppLocalizations.of(context)!.ae_days_left(daysUntilEvent)
                      : daysUntilEvent == 0 
                          ? AppLocalizations.of(context)!.ae_today
                          : AppLocalizations.of(context)!.ae_event_over,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.ae_accepted_on(_formatDate(widget.acceptedAt)),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(AppLocalizations t) {
    return _buildSection(
      title: AppLocalizations.of(context)!.ae_about,
      icon: Icons.info_outline,
      children: [
        Text(
          widget.event.description,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.ae_participants_of(_participants.length, widget.event.participantsCount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(((_participants.length / widget.event.participantsCount) * 100).toInt())}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(AppLocalizations t) {
    return _buildSection(
      title: AppLocalizations.of(context)!.ev_date_time,
      icon: Icons.schedule,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.ev_date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd MMMM yyyy', 'uk').format(widget.event.dateTime),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE', 'uk').format(widget.event.dateTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).extension<AppSemantics>()!.warning,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).extension<AppSemantics>()!.warning),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Theme.of(context).extension<AppSemantics>()!.warning, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.ev_time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).extension<AppSemantics>()!.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('HH:mm').format(widget.event.dateTime),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _getTimeUntilEvent(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrganizerSection(AppLocalizations t) {
    return _buildSection(
      title: AppLocalizations.of(context)!.ae_organizer,
      icon: Icons.person_outline,
      children: [
        GestureDetector(
          onTap: () => _viewOrganizerProfile(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: AssetImage(widget.organizer.photos.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.organizer.name}, ${widget.organizer.age}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.organizer.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            widget.organizer.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationMessage(AppLocalizations t) {
    return _buildSection(
      title: AppLocalizations.of(context)!.ae_organizer_msg,
      icon: Icons.message_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage(widget.organizer.photos.first),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.organizer.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.invitationMessage!,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateInfo(AppLocalizations t) {
    return _buildSection(
      title: AppLocalizations.of(context)!.ev_private_info,
      icon: Icons.lock_outline,
      color: Theme.of(context).colorScheme.primary,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.ae_members_only,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.event.privateLocation?.isNotEmpty ?? false)
          _buildPrivateInfoItem(
            icon: Icons.home,
            title: AppLocalizations.of(context)!.ev_exact_address,
            content: widget.event.privateLocation!,
            color: Theme.of(context).colorScheme.error,
          ),
        if (widget.event.meetingPoint?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _buildPrivateInfoItem(
            icon: Icons.meeting_room,
            title: AppLocalizations.of(context)!.ev_meeting_point,
            content: widget.event.meetingPoint!,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
        if (widget.event.additionalInfo?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _buildPrivateInfoItem(
            icon: Icons.info,
            title: AppLocalizations.of(context)!.ev_extra_info,
            content: widget.event.additionalInfo!,
            color: Theme.of(context).extension<AppSemantics>()!.success,
          ),
        ],
      ],
    );
  }

  Widget _buildPrivateInfoItem({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(AppLocalizations t) {
    return _buildSection(
      title: AppLocalizations.of(context)!.ae_participants(_participants.length),
      icon: Icons.people_outline,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _participants.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final participant = _participants[index];
            return GestureDetector(
              onTap: () => _viewParticipantProfile(participant),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(participant.photos.first),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${participant.name}, ${participant.age}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            participant.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).extension<AppSemantics>()!.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).extension<AppSemantics>()!.success,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection(AppLocalizations t) {
    return _buildSection(
      title: AppLocalizations.of(context)!.ev_tags,
      icon: Icons.tag,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.event.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations t) {
    final daysUntilEvent = widget.event.dateTime.difference(DateTime.now()).inDays;
    final isEventActive = daysUntilEvent >= 0;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: AppLocalizations.of(context)!.ae_event_chat,
                color: Theme.of(context).colorScheme.primary,
                onTap: _openEventChat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.directions,
                label: AppLocalizations.of(context)!.ae_route,
                color: Theme.of(context).extension<AppSemantics>()!.success,
                onTap: _openDirections,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isEventActive)
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: Icons.notifications_active,
              label: AppLocalizations.of(context)!.ae_remind,
              color: Theme.of(context).extension<AppSemantics>()!.warning,
              onTap: _setReminder,
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: Icons.rate_review,
              label: AppLocalizations.of(context)!.ae_leave_review,
              color: Theme.of(context).colorScheme.primary,
              onTap: _leaveReview,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return AppLocalizations.of(context)!.today_lc;
    if (diff == 1) return AppLocalizations.of(context)!.yesterday;
    if (diff < 7) return AppLocalizations.of(context)!.ae_days_ago(diff);
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _getTimeUntilEvent() {
    final now = DateTime.now();
    final diff = widget.event.dateTime.difference(now);
    
    if (diff.isNegative) return AppLocalizations.of(context)!.ae_finished;
    if (diff.inDays > 0) return AppLocalizations.of(context)!.ae_in_days(diff.inDays);
    if (diff.inHours > 0) return AppLocalizations.of(context)!.ae_in_hours(diff.inHours);
    if (diff.inMinutes > 0) return AppLocalizations.of(context)!.ae_in_minutes(diff.inMinutes);
    return AppLocalizations.of(context)!.ae_now;
  }

  // Action methods
  void _shareEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.ae_sharing(widget.event.title)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _viewOrganizerProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(user: widget.organizer),
      ),
    );
  }

  void _viewParticipantProfile(UserProfile participant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(user: participant),
      ),
    );
  }

  void _openEventChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.ae_opening_chat(widget.event.title)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    
    // TODO: Navigate to event-specific chat
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
      ),
    );
  }

  void _openDirections() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.ae_opening_route(widget.event.location)),
        backgroundColor: Theme.of(context).extension<AppSemantics>()!.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _setReminder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.ae_reminder_set),
        backgroundColor: Theme.of(context).extension<AppSemantics>()!.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _leaveReview() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.ae_leave_review),
          content: Text(AppLocalizations.of(context)!.ae_how_was_it),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.ae_thanks_review),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.ae_leave_review),
            ),
          ],
        );
      },
    );
  }
}
