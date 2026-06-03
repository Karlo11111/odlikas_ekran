import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_ekran/constants/app_colors.dart';
import 'package:odlikas_ekran/services/leaderboard_service.dart';
import 'package:odlikas_ekran/viewmodels/viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LjestvicaPage extends StatefulWidget {
  const LjestvicaPage({super.key});

  @override
  State<LjestvicaPage> createState() => _LjestvicaPageState();
}

class _LjestvicaPageState extends State<LjestvicaPage>
    with SingleTickerProviderStateMixin {
  final _service = LeaderboardService();
  late TabController _tabController;

  // Futures stored as state so a nickname update never triggers a re-fetch.
  Future<List<LeaderboardEntry>>? _classFuture;
  Future<List<LeaderboardEntry>>? _schoolFuture;
  Future<List<LeaderboardEntry>>? _programFuture;

  // Nickname sourced from Firestore pairing document (leaderboardNickname field).
  // A real-time listener keeps it in sync if the user opts in after pairing.
  String? _nickname;
  StreamSubscription<DocumentSnapshot>? _nicknameSubscription;

  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  Future<void> _loadUserData() async {
    final box = await Hive.openBox('user_credentials');
    final token = box.get('token') as String?;

    if (!mounted) return;
    final vm = context.read<HomePageViewModel>();

    // Home page only fetches grades, never the student profile — fetch it here
    // if it hasn't been loaded yet so we have real school/class/program IDs.
    if (vm.studentProfile == null && token != null) {
      try {
        await vm.fetchStudentProfile(token);
      } catch (_) {}
    }

    if (!mounted) return;
    final profile = vm.studentProfile;

    // Use the Hive-cached nickname immediately so the UI doesn't flash.
    final cachedNickname = box.get('leaderboard_nickname') as String?;

    final schoolId = profile?.studentSchool ?? '';
    final classId = profile?.studentGrade ?? '';
    final program = profile?.studentProgram ?? '';

    setState(() {
      _nickname = cachedNickname;
      // Futures created once here — nickname changes later will only update
      // _nickname, never recreate these, so the tab data is never re-fetched.
      _classFuture = _service.getClassLeaderboard(schoolId, classId);
      _schoolFuture = _service.getSchoolLeaderboard(schoolId);
      _programFuture = _service.getProgramLeaderboard(program);
      _profileLoaded = true;
    });

    // Real-time listener: picks up leaderboardNickname the moment the mobile
    // app writes it to the pairing document (on opt-in or re-pair).
    final prefs = await SharedPreferences.getInstance();
    final screenId = prefs.getString('screenId');
    if (screenId == null) return;

    _nicknameSubscription = FirebaseFirestore.instance
        .collection('CreatedScreens')
        .doc(screenId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists || !mounted) return;
      final nickname = doc.data()?['leaderboardNickname'] as String?;
      final hiveBox = await Hive.openBox('user_credentials');
      if (nickname != null) {
        await hiveBox.put('leaderboard_nickname', nickname);
      } else {
        await hiveBox.delete('leaderboard_nickname');
      }
      if (mounted) setState(() => _nickname = nickname);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nicknameSubscription?.cancel();
    super.dispose();
  }

  void _showScoringInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Bodovanje ljestvice',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bodovi se računaju na temelju tvog streaka (dani zaredom) i porasta '
          'prosječne ocjene. Što duži streak i veći rast prosjeka, viši si na ljestvici.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'U redu',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: AppColors.background,
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: sh * 0.07,
        leadingWidth: 35 + 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 35),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 50,
            color: AppColors.accent,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Ljestvica',
          style: GoogleFonts.inter(
            fontSize: sh * 0.03,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, size: sh * 0.03),
            color: AppColors.secondary,
            onPressed: _showScoringInfo,
          ),
        ],
      ),
      body: !_profileLoaded
          ? Center(
              child: Lottie.asset(
                'assets/animations/bird_animation.json',
                width: sh * 0.35,
                height: sh * 0.35,
              ),
            )
          : _buildLeaderboard(sw, sh),
    );
  }

  Widget _buildLeaderboard(double sw, double sh) {
    return Column(
      children: [
        _buildTabBar(sw, sh),
        SizedBox(height: sh * 0.01),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LeaderboardTab(future: _classFuture!, nickname: _nickname),
              _LeaderboardTab(future: _schoolFuture!, nickname: _nickname),
              _LeaderboardTab(future: _programFuture!, nickname: _nickname),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(double sw, double sh) {
    return Center(
      child: Container(
        width: sw * 0.6,
        height: sh * 0.075,
        padding: EdgeInsets.all(sh * 0.006),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) => Row(
            children: [
              _tabPill(0, 'Razred', sh),
              SizedBox(width: sh * 0.012),
              _tabPill(1, 'Škola', sh),
              SizedBox(width: sh * 0.012),
              _tabPill(2, 'Program', sh),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabPill(int index, String label, double sh) {
    final active = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF1485BA).withValues(alpha: 0.74)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active
                ? null
                : Border.all(color: AppColors.primary, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: sh * 0.022,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tab content ──────────────────────────────────────────────────────────────

class _LeaderboardTab extends StatefulWidget {
  final Future<List<LeaderboardEntry>> future;

  // Nullable: tablet doesn't gate on join status. Used only to highlight the
  // current user's row if we happen to know their nickname from Hive.
  final String? nickname;

  const _LeaderboardTab({required this.future, required this.nickname});

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  late Future<List<LeaderboardEntry>> _future;
  String? _nickname;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
    _nickname = widget.nickname;
  }

  @override
  void didUpdateWidget(_LeaderboardTab old) {
    super.didUpdateWidget(old);
    if (old.future != widget.future) _future = widget.future;
    // Nickname arriving from Firestore after the tab is already built —
    // explicit setState so the tab definitely re-renders the builder.
    if (old.nickname != widget.nickname) {
      setState(() => _nickname = widget.nickname);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return FutureBuilder<List<LeaderboardEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Lottie.asset(
              'assets/animations/bird_animation.json',
              width: sh * 0.35,
              height: sh * 0.35,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Greška pri dohvaćanju ljestvice',
              style: GoogleFonts.inter(color: AppColors.tertiary),
            ),
          );
        }

        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'Još nema sudionika',
              style: GoogleFonts.inter(
                fontSize: sh * 0.03,
                color: AppColors.tertiary,
              ),
            ),
          );
        }

        final nick = _nickname;
        final myIndex = (nick != null && nick.isNotEmpty)
            ? entries.indexWhere((e) => e.nickname == nick)
            : -1;
        final myEntry = myIndex >= 0 ? entries[myIndex] : null;
        final myRank = myIndex >= 0 ? myIndex + 1 : null;

        final maxDelta = entries.fold<double>(
          0.001,
          (m, e) => e.gradeDeltaScore > m ? e.gradeDeltaScore : m,
        );

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => setState(() => _future = widget.future),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              sw * 0.08,
              sh * 0.03,
              sw * 0.08,
              sh * 0.03,
            ),
            children: [
              _buildPodium(entries, sw, sh),
              SizedBox(height: sh * 0.025),
              if (myEntry != null) ...[
                _buildMyRankCard(myEntry, myRank!, maxDelta, sw, sh),
                SizedBox(height: sh * 0.025),
              ],
              ...entries.skip(3).toList().asMap().entries.map(
                    (e) => Padding(
                      padding: EdgeInsets.only(bottom: sh * 0.015),
                      child: _buildListRow(e.value, e.key + 4, sw, sh),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  // ── Podium ───────────────────────────────────────────────────────────────────

  Widget _buildPodium(List<LeaderboardEntry> entries, double sw, double sh) {
    if (entries.isEmpty) return const SizedBox();

    final first = entries[0];
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    final cardHeight = sh * 0.33;
    final lift = sh * 0.04;
    final badgeSize = sh * 0.05;
    final badgeOverlap = sh * 0.01;
    final rowHeight = badgeOverlap + cardHeight + lift + sh * 0.02;

    return LayoutBuilder(builder: (_, constraints) {
      final cw = sh * 0.30;
      final cardGap = sh * 0.03; // gap between adjacent cards
      final totalW = 3 * cw + 2 * cardGap;
      final start = (constraints.maxWidth - totalW) / 2; // centre the trio

      // Absolute left edges of each card
      final left2nd = start; // 2nd place (left)
      final left1st = start + cw + cardGap; // 1st place (centre)
      final left3rd = start + 2 * (cw + cardGap); // 3rd place (right)

      return SizedBox(
        height: rowHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1st (centre) — lowest z-order
            Positioned(
              left: left1st,
              top: badgeOverlap,
              width: cw,
              child: _podiumCard(first, sh),
            ),
            // 3rd (right)
            if (third != null)
              Positioned(
                left: left3rd,
                top: lift + badgeOverlap,
                width: cw,
                child: _podiumCard(third, sh),
              ),
            // 2nd (left) — highest card z-order
            if (second != null)
              Positioned(
                left: left2nd,
                top: lift + badgeOverlap,
                width: cw,
                child: _podiumCard(second, sh),
              ),
            // Badges — top-right corner of each card
            Positioned(
              left: left1st + cw + badgeOverlap - badgeSize,
              top: 0,
              child: _rankBadge(1, badgeSize, sh),
            ),
            if (second != null)
              Positioned(
                left: left2nd + cw + badgeOverlap - badgeSize,
                top: lift,
                child: _rankBadge(2, badgeSize, sh),
              ),
            if (third != null)
              Positioned(
                left: left3rd + cw + badgeOverlap - badgeSize,
                top: lift,
                child: _rankBadge(3, badgeSize, sh),
              ),
          ],
        ),
      );
    });
  }

  Widget _podiumCard(LeaderboardEntry entry, double sh) {
    final deltaStr = entry.gradeDeltaScore >= 0
        ? '+${entry.gradeDeltaScore.toStringAsFixed(1)}%'
        : '${entry.gradeDeltaScore.toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1485BA).withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 7.8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: sh * 0.012,
        vertical: sh * 0.016,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: sh * 0.04,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Icon(Icons.person, color: Colors.white, size: sh * 0.042),
          ),
          SizedBox(height: sh * 0.008),
          Text(
            entry.nickname,
            style: GoogleFonts.inter(
              fontSize: sh * 0.022,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: sh * 0.006),
          Text(
            '🔥 ${entry.currentStreak} dana',
            style: GoogleFonts.inter(
              fontSize: sh * 0.022,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'streak dana zaredom',
            style: GoogleFonts.inter(
              fontSize: sh * 0.014,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sh * 0.006),
          Text(
            deltaStr,
            style: GoogleFonts.inter(
              fontSize: sh * 0.022,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'podignut prosjek',
            style: GoogleFonts.inter(
              fontSize: sh * 0.014,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _rankBadge(int rank, double size, double sh) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank.',
        style: GoogleFonts.inter(
          fontSize: sh * 0.025,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── "Tvoj Rang" card ──────────────────────────────────────────────────────────

  Widget _buildMyRankCard(
      LeaderboardEntry entry, int rank, double maxDelta, double sw, double sh) {
    final progress = (entry.gradeDeltaScore / maxDelta).clamp(0.0, 1.0);
    final deltaStr = entry.gradeDeltaScore >= 0
        ? '+${entry.gradeDeltaScore.toStringAsFixed(1)}%'
        : '${entry.gradeDeltaScore.toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: sh * 0.025,
        vertical: sh * 0.018,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tvoj Rang: $rank.',
            style: GoogleFonts.inter(
              fontSize: sh * 0.022,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: sh * 0.012),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: sh * 0.038,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person,
                  color: AppColors.tertiary,
                  size: sh * 0.036,
                ),
              ),
              SizedBox(width: sh * 0.02),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.nickname,
                      style: GoogleFonts.inter(
                        fontSize: sh * 0.02,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Dani streaka',
                      style: GoogleFonts.inter(
                        fontSize: sh * 0.016,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _verticalDivider(sh),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.currentStreak} dana 🔥',
                      style: GoogleFonts.inter(
                        fontSize: sh * 0.02,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      '${entry.combinedScore.toStringAsFixed(1)} bod.',
                      style: GoogleFonts.inter(
                        fontSize: sh * 0.016,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _verticalDivider(sh),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Podignut prosjek',
                      style: GoogleFonts.inter(
                        fontSize: sh * 0.016,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      deltaStr,
                      style: GoogleFonts.inter(
                        fontSize: sh * 0.016,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tertiary,
                      ),
                    ),
                    SizedBox(height: sh * 0.008),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFD9D9D9),
                            color: AppColors.primary,
                            minHeight: sh * 0.022,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: sh * 0.014,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider(double sh) {
    return Container(
      height: sh * 0.07,
      width: 1.5,
      color: AppColors.tertiary.withValues(alpha: 0.3),
      margin: EdgeInsets.symmetric(horizontal: sh * 0.02),
    );
  }

  // ── List row (rank 4+) ────────────────────────────────────────────────────────

  Widget _buildListRow(LeaderboardEntry entry, int rank, double sw, double sh) {
    final nick = _nickname;
    final isMe = nick != null && nick.isNotEmpty && entry.nickname == nick;

    return Container(
      height: sh * 0.075,
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe
              ? AppColors.primary
              : const Color(0xFF1485BA).withValues(alpha: 0.3),
          width: isMe ? 1.5 : 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: sh * 0.025),
      child: Row(
        children: [
          SizedBox(
            width: sh * 0.07,
            child: Text(
              '$rank.',
              style: GoogleFonts.inter(
                fontSize: sh * 0.026,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.nickname + (isMe ? ' (ti)' : ''),
              style: GoogleFonts.inter(
                fontSize: sh * 0.026,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.combinedScore.toStringAsFixed(1)} bod.',
                style: GoogleFonts.inter(
                  fontSize: sh * 0.02,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '🔥 ${entry.currentStreak}d',
                style: GoogleFonts.inter(
                  fontSize: sh * 0.02,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
