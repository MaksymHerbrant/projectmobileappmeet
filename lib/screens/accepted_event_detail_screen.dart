import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
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
      backgroundColor: Colors.white,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black54,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black54,
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
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ви йдете на цю подію! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  daysUntilEvent > 0 
                      ? 'Залишилось $daysUntilEvent днів'
                      : daysUntilEvent == 0 
                          ? 'Подія сьогодні!'
                          : 'Подія завершена',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Прийнято ${_formatDate(widget.acceptedAt)}',
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
      title: 'Про подію',
      icon: Icons.info_outline,
      children: [
        Text(
          widget.event.description,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 12),
              Text(
                'Учасників: ${_participants.length}/${widget.event.participantsCount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(((_participants.length / widget.event.participantsCount) * 100).toInt())}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
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
      title: 'Дата та час',
      icon: Icons.schedule,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.purple.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Дата',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd MMMM yyyy', 'uk').format(widget.event.dateTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE', 'uk').format(widget.event.dateTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Час',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('HH:mm').format(widget.event.dateTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _getTimeUntilEvent(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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
      title: 'Організатор',
      icon: Icons.person_outline,
      children: [
        GestureDetector(
          onTap: () => _viewOrganizerProfile(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.organizer.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            widget.organizer.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.blue.shade600,
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
      title: 'Повідомлення від організатора',
      icon: Icons.message_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
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
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.invitationMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
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
      title: 'Приватна інформація',
      icon: Icons.lock_outline,
      color: Colors.purple.shade50,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.purple.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ця інформація доступна тільки учасникам події',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade700,
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
            title: 'Точна адреса',
            content: widget.event.privateLocation!,
            color: Colors.red,
          ),
        if (widget.event.meetingPoint?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _buildPrivateInfoItem(
            icon: Icons.meeting_room,
            title: 'Місце зустрічі',
            content: widget.event.meetingPoint!,
            color: Colors.blue,
          ),
        ],
        if (widget.event.additionalInfo?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          _buildPrivateInfoItem(
            icon: Icons.info,
            title: 'Додаткова інформація',
            content: widget.event.additionalInfo!,
            color: Colors.green,
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
        color: Colors.white,
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
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(AppLocalizations t) {
    return _buildSection(
      title: 'Учасники (${_participants.length})',
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            participant.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
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
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade600,
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
      title: 'Теги',
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
                  colors: [Colors.blue.shade100, Colors.blue.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: Colors.blue.shade700,
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
                label: 'Чат події',
                color: Colors.blue,
                onTap: _openEventChat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.directions,
                label: 'Маршрут',
                color: Colors.green,
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
              label: 'Нагадати за годину до події',
              color: Colors.orange,
              onTap: _setReminder,
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: Icons.rate_review,
              label: 'Залишити відгук',
              color: Colors.purple,
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
        color: color ?? Colors.white,
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
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.purple.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
    if (diff == 0) return 'сьогодні';
    if (diff == 1) return 'вчора';
    if (diff < 7) return '$diff днів тому';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _getTimeUntilEvent() {
    final now = DateTime.now();
    final diff = widget.event.dateTime.difference(now);
    
    if (diff.isNegative) return 'Завершено';
    if (diff.inDays > 0) return 'Через ${diff.inDays} дн.';
    if (diff.inHours > 0) return 'Через ${diff.inHours} год.';
    if (diff.inMinutes > 0) return 'Через ${diff.inMinutes} хв.';
    return 'Зараз!';
  }

  // Action methods
  void _shareEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Поділитись "${widget.event.title}"'),
        backgroundColor: Colors.blue.shade600,
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
        content: Text('Відкриваємо чат події "${widget.event.title}"'),
        backgroundColor: Colors.blue.shade600,
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
        content: Text('Відкриваємо маршрут до "${widget.event.location}"'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _setReminder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Нагадування встановлено за годину до події 🔔'),
        backgroundColor: Colors.orange.shade600,
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
          title: const Text('Залишити відгук'),
          content: const Text('Як вам сподобалась подія?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Дякуємо за відгук! ⭐'),
                    backgroundColor: Colors.purple.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: const Text('Залишити відгук'),
            ),
          ],
        );
      },
    );
  }
}
