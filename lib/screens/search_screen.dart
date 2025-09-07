import 'package:flutter/material.dart';
import '../models/ai_recipe.dart';
import '../services/ai_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final AiService _ai = AiService();

  AiRecipe? _result;
  bool _loading = false;
  String? _error;

  bool _compact = false; // setelah search → header compact

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _compact = true;
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
  final r = await _ai.getRecipeIdea(q);
  setState(() => _result = r);

  // INFO sumber (Gemini / Mock)
  if (mounted) {
    final src = _ai.lastProvider.toUpperCase();
    final msg = _ai.lastError.isEmpty ? 'Sumber: $src' : 'Sumber: $src • ${_ai.lastError}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }
} catch (e) {
  setState(() => _error = 'Gagal memuat resep. ${e.toString()}');
} finally {
  setState(() => _loading = false);
}

  }

  // ================= HEADER =================

  Widget _headerIdle(BuildContext context) {
    const double maxFieldWidth = 520;

    return LayoutBuilder(builder: (context, c) {
      final width =
          c.maxWidth > maxFieldWidth ? maxFieldWidth : c.maxWidth * .92;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/rasai_logo.png',
            height: 140,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.restaurant, size: 96, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            "Mau masak apa hari ini?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black26),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _searchBar(width),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _loading
                ? const _CookingLoader(key: ValueKey('loader'))
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }

  Widget _headerCompact(BuildContext context) {
    const double maxFieldWidth = 520;

    return LayoutBuilder(builder: (context, c) {
      final width =
          c.maxWidth > maxFieldWidth ? maxFieldWidth : c.maxWidth * .92;

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Mau masak apa hari ini?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black26),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _searchBar(width),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _loading
                  ? const _CookingLoader(key: ValueKey('loader'))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }

  Widget _searchBar(double width) {
    return Center(
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Cari resep ',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: const StadiumBorder(),
                  backgroundColor: const Color(0xFF0F766E),
                ),
                onPressed: _loading ? null : _search,
                child: const Text('Cari'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HASIL =================

  Widget _resultCard(AiRecipe r) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF0EA5A4),
                      child: const Text('🍳', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Estimasi: ${r.estMinutes} menit',
                              style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),

                const SizedBox(height: 12),
                const Text('Bahan',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: r.ingredients
                      .map((e) => Chip(
                            label: Text(e),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: const Color(0xFFE8F7F6),
                            side: BorderSide(
                              color: const Color(0xFF0EA5A4).withOpacity(.25),
                            ),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 16),
                const Text('Langkah',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: r.steps.asMap().entries.map((e) {
                    final idx = e.key + 1;
                    final text = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF0EA5A4),
                            child: Text(
                              '$idx',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(text)),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur bagikan (demo)')),
                        );
                      },
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Bagikan'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Disimpan ke Favorit: ${r.title}')),
                        );
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg_hommie.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.06)),
          ),

          // FOREGROUND (safe area)
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _compact
                  ? Column(
                      key: const ValueKey('compact'),
                      children: [
                        _headerCompact(context),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _loading
                                ? const SizedBox.shrink()
                                : (_error != null
                                    ? Align(
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(_error!,
                                              style: const TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      )
                                    : (_result != null
                                        ? ListView(
                                            padding: const EdgeInsets.only(
                                                bottom: 24),
                                            children: [_resultCard(_result!)],
                                          )
                                        : const SizedBox.shrink())),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('idle'),
                      children: [
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(child: _headerIdle(context)),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loader custom: ikon piring berputar + teks
class _CookingLoader extends StatefulWidget {
  const _CookingLoader({super.key});

  @override
  State<_CookingLoader> createState() => _CookingLoaderState();
}

class _CookingLoaderState extends State<_CookingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          turns: _c,
          child: const Icon(Icons.restaurant_menu),
        ),
        const SizedBox(width: 8),
        const Text('Menyiapkan resep...'),
      ],
    );
  }
}
