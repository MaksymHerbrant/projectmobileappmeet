import 'dart:math' as math;

import 'package:dating_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

import '../l10n/interest_labels.dart';
import '../models/event.dart';
import '../models/user_profile.dart';
import '../service/matches_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_kit.dart';
import 'event_detail_screen.dart';
import 'user_profile_view_screen.dart';

/// Карта «хто поруч» за `design/Map.dc.html`.
///
/// Карта тут навмисно умовна, а не справжня вулична. Сервер віддає лише
/// відстань у кілометрах — координат він не повертає взагалі, і це не
/// недогляд, а обіцянка з екрана дозволу: «показуємо лише відстань, не
/// адресу». Справжня мапа з людьми на вулицях цю обіцянку б і порушила:
/// маючи три точки, чужу домівку обчислює будь-хто.
///
/// Тому відстань до кола малюється справжня, а напрямок береться з
/// незмінного хешу ідентифікатора — стабільний між відкриттями, але нічого
/// не розкриває. Підпис під картою це прямо проговорює.
class MapScreen extends StatefulWidget {
  final int radiusKm;

  const MapScreen({super.key, this.radiusKm = 25});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum _MapFilter { all, people, events }

class _MapScreenState extends State<MapScreen> {
  final _service = MatchesService();

  List<UserProfile> _people = [];
  List<Event> _events = [];
  bool _loading = true;
  _MapFilter _filter = _MapFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Обидва списки паралельно: чекати один на одного немає причини.
      final results = await Future.wait([
        _service.getFeed(radiusKm: widget.radiusKm, limit: 30),
        _service.getEventFeed(radiusKm: widget.radiusKm, limit: 30),
      ]);
      if (!mounted) return;
      setState(() {
        _people = (results[0] as List<UserProfile>)
            .where((u) => u.distanceKm != null)
            .toList();
        _events = (results[1] as List<Event>)
            .where((e) => e.distanceKm != null)
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _showPeople => _filter != _MapFilter.events;
  bool get _showEvents => _filter != _MapFilter.people;

  List<UserProfile> get _visiblePeople => _showPeople ? _people : const [];
  List<Event> get _visibleEvents => _showEvents ? _events : const [];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: Ds.background(context),
        child: Stack(
          children: [
            // Полотно карти займає весь екран; аркуш і шапка лежать поверх.
            Positioned.fill(
              child: _MapCanvas(
                radiusKm: widget.radiusKm,
                people: _visiblePeople,
                events: _visibleEvents,
                onPerson: _openPerson,
                onEvent: _openEvent,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            elevation: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: Ds.shadow(context),
                              ),
                              child: DsSearchField(hint: t.map_search_hint),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DsIconButton(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.of(context).pop(),
                          semanticLabel: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        for (final f in _MapFilter.values) ...[
                          if (f != _MapFilter.values.first)
                            const SizedBox(width: 8),
                          DsChip(
                            label: switch (f) {
                              _MapFilter.all => t.map_filter_all,
                              _MapFilter.people => t.map_filter_people,
                              _MapFilter.events => t.map_filter_events,
                            },
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              _buildSheet(t, scheme),
          ],
        ),
      ),
    );
  }

  /// Нижній аркуш зі списком. Тягнеться вгору, як у макеті.
  Widget _buildSheet(AppLocalizations t, ColorScheme scheme) {
    final people = _visiblePeople;
    final events = _visibleEvents;
    final empty = people.isEmpty && events.isEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.34,
      maxChildSize: 0.82,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundGradient(context).last,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: const [
              BoxShadow(color: Color(0x29000000), blurRadius: 30, offset: Offset(0, -8)),
            ],
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(t.map_within(widget.radiusKm), style: Ds.h2(context)),
                  ),
                  Text(
                    t.map_counts(people.length, events.length),
                    style: Ds.tiny(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (empty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    t.map_empty,
                    textAlign: TextAlign.center,
                    style: Ds.sub(context),
                  ),
                )
              else ...[
                for (var i = 0; i < people.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                  _personRow(people[i], scheme),
                ],
                if (people.isNotEmpty && events.isNotEmpty)
                  Divider(height: 1, color: scheme.outlineVariant),
                for (var i = 0; i < events.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                  _eventRow(events[i], t, scheme),
                ],
              ],
              const SizedBox(height: 18),
              DsNote(text: t.map_direction_note, icon: Icons.shield_outlined),
            ],
          ),
        );
      },
    );
  }

  Widget _personRow(UserProfile user, ColorScheme scheme) {
    final interests =
        user.hobbies.take(2).map((h) => InterestLabels.of(context, h)).join(' · ');

    return InkWell(
      onTap: () => _openPerson(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            DsAvatar(
              initial: user.name,
              photoUrl: user.photos.isEmpty ? null : user.photos.first,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.age > 0 ? '${user.name}, ${user.age}' : user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ds.body(context),
                  ),
                  if (interests.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(interests,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Ds.tiny(context)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            DsChip(
              label: _km(user.distanceKm!),
              small: true,
              icon: Icons.place_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventRow(Event event, AppLocalizations t, ColorScheme scheme) {
    return InkWell(
      onTap: () => _openEvent(event),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: 48,
                height: 48,
                child: DsPhotoBlock(radius: 0, fontSize: 17, initial: event.title),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Ds.body(context)),
                  const SizedBox(height: 3),
                  Text(
                    '${event.dateTime.day}.${event.dateTime.month.toString().padLeft(2, '0')} · '
                    '${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                    style: Ds.tiny(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            DsChip(
              label: _km(event.distanceKm!),
              small: true,
              icon: Icons.place_outlined,
            ),
          ],
        ),
      ),
    );
  }

  String _km(double km) {
    final s = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return '${s.replaceAll('.', ',')} км';
  }

  void _openPerson(UserProfile user) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UserProfileViewScreen(user: user)),
      );

  void _openEvent(Event event) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      );
}

/// Полотно карти: сітка кварталів, коло радіуса, своя точка і мітки.
class _MapCanvas extends StatelessWidget {
  final int radiusKm;
  final List<UserProfile> people;
  final List<Event> events;
  final ValueChanged<UserProfile> onPerson;
  final ValueChanged<Event> onEvent;

  const _MapCanvas({
    required this.radiusKm,
    required this.people,
    required this.events,
    required this.onPerson,
    required this.onEvent,
  });

  /// Кут мітки. Береться з ідентифікатора, тож між відкриттями не стрибає,
  /// але з реальним напрямком не пов'язаний — координат ми не знаємо.
  static double _angleFor(String id) =>
      (id.hashCode & 0x7fffffff) % 3600 / 3600 * 2 * math.pi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // Центр трохи вище середини: нижню третину займає аркуш зі списком.
        final center = Offset(size.width / 2, size.height * 0.42);
        final ringRadius = math.min(size.width, size.height) * 0.36;

        Offset place(String id, double distKm) {
          // Лінійно від центру до кола: на межі радіуса мітка сідає на коло.
          final k = (distKm / radiusKm).clamp(0.08, 1.0);
          final a = _angleFor(id);
          return center + Offset(math.cos(a), math.sin(a)) * (ringRadius * k);
        }

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MapPainter(
                  center: center,
                  ringRadius: ringRadius,
                  grid: scheme.outlineVariant.withValues(alpha: 0.5),
                  block: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
                  accent: scheme.primary,
                ),
              ),
            ),

            // Своя точка.
            Positioned(
              left: center.dx - 9,
              top: center.dy - 9,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.3),
                      blurRadius: 0,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),

            for (final user in people)
              _pin(
                context,
                at: place(user.id, user.distanceKm!),
                size: 44,
                circle: true,
                onTap: () => onPerson(user),
                child: DsAvatar(
                  initial: user.name,
                  photoUrl: user.photos.isEmpty ? null : user.photos.first,
                  size: 44,
                ),
              ),

            for (final event in events)
              _pin(
                context,
                at: place(event.id, event.distanceKm!),
                size: 46,
                circle: false,
                onTap: () => onEvent(event),
                child: Container(
                  color: scheme.primary,
                  alignment: Alignment.center,
                  child: Text(
                    event.title.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _pin(
    BuildContext context, {
    required Offset at,
    required double size,
    required bool circle,
    required Widget child,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(circle ? size : 14);

    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.surface, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0x47000000), blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: ClipRRect(borderRadius: radius, child: child),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Offset center;
  final double ringRadius;
  final Color grid;
  final Color block;
  final Color accent;

  const _MapPainter({
    required this.center,
    required this.ringRadius,
    required this.grid,
    required this.block,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Квартали і вулиці — абстракція міста, а не справжня геометрія.
    const step = 78.0;
    const road = 12.0;

    final blockPaint = Paint()..color = block;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + road / 2, y + road / 2, step - road, step - road),
            const Radius.circular(6),
          ),
          blockPaint,
        );
      }
    }

    final roadPaint = Paint()
      ..color = grid
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var y = -step; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (var x = -step; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Коло радіуса з м'якою заливкою всередині.
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.14), accent.withValues(alpha: 0.0)],
          stops: const [0.0, 0.7],
        ).createShader(Rect.fromCircle(center: center, radius: ringRadius)),
    );
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = accent
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.center != center ||
      old.ringRadius != ringRadius ||
      old.grid != grid ||
      old.block != block ||
      old.accent != accent;
}
