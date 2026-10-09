import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/spiral_themes.dart';
import '../widgets/spiral_widgets.dart';

/// Pro screen: Free-vs-Pro comparison table, Pro unlock, tip jar,
/// restore purchases. Graceful when the store isn't configured yet.
class ProScreen extends StatefulWidget {
  final SpiralAudio audio;
  final SpiralSettings settings;
  final StoreService store;
  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  StoreService get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _store.init();
    _store.proPurchased.addListener(_onPro);
  }

  void _onPro() async {
    if (_store.proPurchased.value) {
      await widget.settings.setPro(true);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_onPro);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = s.theme;
    return SpiralThemeHolder(
      theme: t,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Text('←', style: TextStyle(fontSize: 26, color: t.textOn)),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text(s.isPro ? 'Spiral Drop PRO ⭐' : 'Go PRO ⭐',
              style: SpiralLook.title(22, t)),
        ),
        body: WoodBackdrop(
          theme: t,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _comparisonTable(t),
              const SizedBox(height: 18),
              if (!s.isPro) _buySection(t) else _proThanks(t),
              const SizedBox(height: 18),
              _tipJar(t),
              const SizedBox(height: 18),
              _restoreRow(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comparisonTable(SpiralThemeDef t) {
    const rows = [
      ('All 12 tower themes', false, true),
      ('All 8 ball styles', false, true),
      ('My Workshop custom designer', false, true),
      ('Inferno difficulty 🔥', false, true),
      ('Full game, no ads', true, true),
      ('Free forever', true, true),
    ];
    return Container(
      decoration: SpiralLook.panel(t),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('FREE vs PRO', style: SpiralLook.label(13, t)),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  Center(
                      child: Text('FREE',
                          style: SpiralLook.title(14, t))),
                  Center(
                      child: Text('PRO',
                          style: SpiralLook.title(14, t)
                              .copyWith(color: t.accent))),
                ],
              ),
              for (final (label, free, pro) in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 7),
                      child: Text(label,
                          style: SpiralLook.body(13.5, t)),
                    ),
                    Center(
                        child: Text(free ? '✅' : '—',
                            style: const TextStyle(
                                fontSize: 17))),
                    Center(
                        child: Text(pro ? '✅' : '—',
                            style: const TextStyle(
                                fontSize: 17))),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buySection(SpiralThemeDef t) {
    final pro = _store.proProduct;
    return Container(
      decoration: SpiralLook.panel(t),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text('Unlock everything, forever.',
              style: SpiralLook.title(19, t),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'One-time purchase. No subscription, no tricks.',
            style: SpiralLook.body(13, t),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (!_store.storeReady)
            Text(
              '🛠 Pro unlock appears here once the store listing is set up.',
              style: SpiralLook.body(14, t),
              textAlign: TextAlign.center,
            )
          else if (pro != null)
            Column(
              children: [
                SpiralButton(
                  label: 'Get PRO — ${pro.price}',
                  emoji: '⭐',
                  primary: true,
                  onTap: () {
                    widget.audio.click();
                    _store.buyPro();
                  },
                ),
                if (_store.purchaseInProgress.value)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ValueListenableBuilder<String?>(
            valueListenable: _store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(err,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _proThanks(SpiralThemeDef t) {
    return Container(
      decoration: SpiralLook.panel(t),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 44)),
          Text('You are PRO!',
              style: SpiralLook.title(22, t)),
          const SizedBox(height: 6),
          Text(
            'Every theme, ball and difficulty is unlocked. Enjoy the spiral!',
            style: SpiralLook.body(14, t),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tipJar(SpiralThemeDef t) {
    return Container(
      decoration: SpiralLook.panel(t),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text('☕ Tip the maker',
              style: SpiralLook.title(19, t)),
          const SizedBox(height: 6),
          Text(
            'Spiral Drop is made by one indie dev. A tiny tip keeps the towers spinning!',
            style: SpiralLook.body(13, t),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (!_store.storeReady)
            Text(
              '🛠 Tips appear here once the store listing is set up.',
              style: SpiralLook.body(14, t),
              textAlign: TextAlign.center,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (_store.coffeeProduct != null)
                  _tipBtn(t, _store.coffeeProduct!, '☕'),
                if (_store.chocolateProduct != null)
                  _tipBtn(t, _store.chocolateProduct!, '🍫'),
              ],
            ),
          ValueListenableBuilder<String?>(
            valueListenable: _store.lastThanks,
            builder: (_, msg, _) => msg == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(msg,
                        style: TextStyle(
                            color: t.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tipBtn(
      SpiralThemeDef t, ProductDetails p, String emoji) {
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        _store.buyTip(p);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [t.woodLight, t.woodMid]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.accent, width: 2),
        ),
        child: Text('$emoji ${p.price}',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: t.textOn)),
      ),
    );
  }

  Widget _restoreRow(SpiralThemeDef t) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          widget.audio.click();
          await _store.restore();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checking your purchases…'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Text('Restore purchases',
            style: TextStyle(
                color: t.accent,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                decoration: TextDecoration.underline)),
      ),
    );
  }
}
