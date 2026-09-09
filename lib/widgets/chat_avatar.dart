import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AvatarLevel { org, repo, branch }

/// Chat avatar with a 3-level hierarchy:
///
///   - [AvatarLevel.org]   → a SOLID circle tinted by the org name (no
///                           pattern). Same org ⇒ same same color.
///   - [AvatarLevel.repo]  → the org background + a FIXED honeycomb pattern
///                           shared by every repo (foreground hue from repo).
///   - [AvatarLevel.branch]→ the org background + a UNIQUE honeycomb pattern
///                           per branch (foreground hue from the repo).
///
/// Pattern is a regular-hexagon (honeycomb) tiling, all hexes strictly inside
/// the circle. Hexagon circumradius ≈ 1/2 the old 5×5 square side, so the
/// honeycomb is finer than the previous pixel grid. The pattern seed is the
/// *branch name*, so every occurrence of e.g. "main" renders identically
/// regardless of org/repo (colors still vary by org/repo). Rendering is
/// circle-native: hexes whose circumcircle would leave the disc are dropped.
class ChatAvatar extends StatelessWidget {
  final String org;
  final String repo;
  final String branch;
  final double radius;
  final AvatarLevel level;

  const ChatAvatar({
    super.key,
    required this.org,
    required this.repo,
    required this.branch,
    this.radius = 22,
    this.level = AvatarLevel.branch,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor();
    final fg = _fgColor(bg);
    final hexes = _hexes();
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: CustomPaint(
          painter: _IdenticonPainter(bg: bg, fg: fg, hexes: hexes),
          size: Size.infinite,
        ),
      ),
    );
  }

  // ---- hierarchy seeds ----

  String get _bgSeed =>
      org.isNotEmpty ? org : (repo.isNotEmpty ? repo : branch);

  /// Foreground comes from the repo (or, at org level, the org itself) so a
  /// single org's repos keep distinct hues on the same background.
  String get _fgSeed =>
      repo.isNotEmpty ? repo : (org.isNotEmpty ? org : branch);

  /// Pattern seed: the branch name (so "main" always matches), falling back
  /// to the full path only when a branch is absent. Repos share one fixed
  /// pattern; orgs are solid (empty pattern).
  String get _patternSeed {
    switch (level) {
      case AvatarLevel.org:
        return '';
      case AvatarLevel.repo:
        return '!repo';
      case AvatarLevel.branch:
        return branch.isNotEmpty ? branch : '$org/$repo/$branch';
    }
  }

  // ---- honeycomb cells by level ----

  List<HexCell> _hexes() {
    switch (level) {
      case AvatarLevel.org:
        // Solid: no pattern.
        return const [];
      case AvatarLevel.repo:
        // A fixed, symmetric hexagonal wreath shared by every repo.
        return honeycombWreath();
      case AvatarLevel.branch:
        // Branch-seeded honeycomb, forced to be mirror-symmetric about the
        // vertical axis (same semantic as the old square identicon).
        return honeycombCells(_patternSeed, mirror: true);
    }
  }

  // ---- colors ----

  /// Vivid mid-tone background from the ORG hash.
  Color _bgColor() =>
      HSLColor.fromAHSL(1, _hue(_bgSeed), 0.60, 0.48).toColor();

  /// Foreground keeps the repo hue, with lightness laddered for strong WCAG
  /// contrast against the background (>= 3.5:1 where reachable).
  Color _fgColor(Color bg) {
    const darkRungs = [0.34, 0.28, 0.22, 0.17, 0.12];
    const lightRungs = [0.66, 0.72, 0.78, 0.84, 0.90];
    final hue = _hue(_fgSeed);

    Color best = Colors.white;
    var bestRatio = -1.0;
    for (final l in [...darkRungs, ...lightRungs]) {
      final c = HSLColor.fromAHSL(1, hue, 0.62, l).toColor();
      final r = _contrastRatio(c, bg);
      if (r > bestRatio) {
        bestRatio = r;
        best = c;
      }
      if (bestRatio >= 3.5) break;
    }
    if (bestRatio < 3.0) {
      return _luminance(bg) > 0.35 ? const Color(0xFF17181C) : Colors.white;
    }
    return best;
  }

  // ---- hashing / geometry ----

  static int _fnv(String s) {
    var hash = 0x811c9dc5;
    for (final cu in s.codeUnits) {
      hash ^= cu;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static double _hue(String source) => _fnv(source) % 360.toDouble();

  /// Cell size as a fraction of the avatar diameter: the hexagon
  /// circumradius is 1/2 of the old 5×5 square side, so the honeycomb reads
  /// finer. (Old square side = D/5 → hex circumradius = D/(5*2) = D/10.)
  static double get _hexSize => 0.10;

  /// The fixed, radially-symmetric hexagonal wreath used for every repo. The
  /// honeycomb lattice is symmetric about both axes, so taking an annulus
  /// (radial band) yields a symmetric ring of hexes — a recognizable "wreath"
  /// without relying on the seed. All hexes stay inside the disc.
  static List<HexCell> honeycombWreath() {
    final R = _hexSize;
    final stepX = sqrt(3) * R;
    final stepY = 1.5 * R;
    final out = <HexCell>[];
    for (var row = -8; row <= 8; row++) {
      final y = row * stepY;
      final xOff = row.isOdd ? stepX / 2 : 0.0;
      for (var col = -8; col <= 8; col++) {
        final x = col * stepX + xOff;
        final d = sqrt(x * x + y * y);
        // Keep only hexes in a mid-radius annulus (a ring near the rim), and
        // inside the disc (center + R <= 0.5).
        if (d < 0.26 || d > 0.40) continue;
        if (d > 0.5 - R) continue;
        out.add(HexCell(x, y, R, true));
      }
    }
    return out;
  }

  /// A branch-seeded honeycomb. When [mirror] is true the pattern is forced
  /// to mirror-symmetric about the vertical axis (x → -x), matching the old
  /// identicon's symmetry. Only hexes whose circumcircle lies fully inside the
  /// disc are kept so no tile pokes outside the circle. The seed is the
  /// branch name (stable): every identical branch renders identically.
  static List<HexCell> honeycombCells(String seed, {bool mirror = false}) {
    final R = _hexSize;

    // Pointy-top hexagon lattice: horizontal spacing = sqrt(3)*R, vertical
    // spacing = 1.5*R, every other row offset by half a step. The lattice is
    // symmetric about both axes (even rows symmetric about x=0; adjacent odd
    // rows are the same set mirrored), so mirroring is lossless.
    final stepX = sqrt(3) * R;
    final stepY = 1.5 * R;
    final cells = <HexCell>[];
    for (var row = -8; row <= 8; row++) {
      final y = row * stepY;
      final xOff = row.isOdd ? stepX / 2 : 0.0;
      for (var col = -8; col <= 8; col++) {
        final x = col * stepX + xOff;
        if (sqrt(x * x + y * y) > 0.5 - R) continue;
        cells.add(HexCell(x, y, R, true));
      }
    }

    if (!mirror) {
      // Direct deterministic on/off from the seed.
      return [
        for (var i = 0; i < cells.length; i++)
          HexCell(cells[i].x, cells[i].y, R, _bitAt(seed, i)),
      ];
    }

    // Mirror-symmetric: index cells by rounded coordinates so each cell can
    // find its x → -x mirror, then set a pair on/off from a single shared bit.
    final byCoord = <String, int>{};
    for (var i = 0; i < cells.length; i++) {
      byCoord['${_k(cells[i].x)}|${_k(cells[i].y)}'] = i;
    }
    final on = List<bool>.filled(cells.length, false);
    for (var i = 0; i < cells.length; i++) {
      if (on[i]) continue;
      final key = '${_k(-cells[i].x)}|${_k(cells[i].y)}';
      final mi = byCoord[key] ?? i;
      final bit = _bitAt(seed, i < mi ? i : mi);
      on[i] = bit;
      if (mi != i) on[mi] = bit;
    }
    return [
      for (var i = 0; i < cells.length; i++)
        HexCell(cells[i].x, cells[i].y, R, on[i]),
    ];
  }

  /// Round a normalized coordinate to a stable key (avoids float drift).
  static String _k(double v) => v.toStringAsFixed(6);

  /// Deterministic on/off for hexagon [i]. Hashing the *whole* seed + index
  /// fresh per cell (not a single base hash reused with a weak xorshift) keeps
  /// distinct seeds (e.g. "main" vs "master") from colliding into identical
  /// patterns, while the same seed always renders the same.
  static bool _bitAt(String seed, int i) {
    if (seed.isEmpty) return (i & 1) == 0;
    return (_mix(_fnv('$seed#$i')) & 1) == 1;
  }

  /// A strong finalizer so adjacent / near-identical inputs diverge (FNV alone
  /// is too weak: "main" and "master" were mapping to the same bit pattern).
  static int _mix(int x) {
    x = (x ^ (x >> 16)) * 0x7feb352d & 0xffffffff;
    x = (x ^ (x >> 15)) * 0x846ca68b & 0xffffffff;
    return (x ^ (x >> 16)) & 0xffffffff;
  }

  // ---- WCAG contrast math ----

  static double _luminance(Color c) {
    double channel(double v) =>
        v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  static double _contrastRatio(Color a, Color b) {
    final la = _luminance(a);
    final lb = _luminance(b);
    final hi = max(la, lb);
    final lo = min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }
}

/// A single honeycomb cell: a regular hexagon at normalized center (x,y),
/// with circumradius [r] (fraction of diameter) and a fill flag.
class HexCell {
  final double x;
  final double y;
  final double r;
  final bool on;
  const HexCell(this.x, this.y, this.r, this.on);
}

/// Paints the identicon natively in the circle: background fills the whole
/// circle; on-hexes are drawn through a circular clip so rim hexes finish in a
/// smooth arc. Hexes whose circumcircle would leave the disc were dropped when
/// generated, so nothing pokes outside the circle.
class _IdenticonPainter extends CustomPainter {
  final Color bg;
  final Color fg;
  final List<HexCell> hexes;
  _IdenticonPainter(
      {required this.bg, required this.fg, required this.hexes});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..color = bg);
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    final d = size.shortestSide; // diameter
    final center = rect.center;
    final paint = Paint()..color = fg;
    for (final h in hexes) {
      if (!h.on) continue;
      final cx = center.dx + h.x * d;
      final cy = center.dy + h.y * d;
      final r = h.r * d;
      // Pointy-top hexagon vertices.
      final path = Path();
      for (var k = 0; k < 6; k++) {
        final a = pi / 6 + k * pi / 3; // 30° offset ⇒ flat sides left/right
        final px = cx + r * cos(a);
        final py = cy + r * sin(a);
        if (k == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IdenticonPainter old) =>
      old.bg != bg ||
      old.fg != fg ||
      !listEquals(old.hexes.map((e) => e.on).toList(),
          hexes.map((e) => e.on).toList());
}
