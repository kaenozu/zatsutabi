import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/history_store.dart';
import '../models/poi.dart';
import '../services/location_service.dart';
import '../services/recommendation_engine.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.engine, required this.historyStore});
  final RecommendationEngine engine;
  final HistoryStore historyStore;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  Poi? suggestion;
  TripRange range = TripRange.nearby;
  bool indoorOnly = false;
  bool loading = false;
  String? error;
  bool _locationPermanentlyDenied = false;
  late Future<List<HistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.historyStore.entries();
  }

  Future<void> suggest({TripRange? nextRange, bool? nextIndoor}) async {
    setState(() {
      loading = true;
      error = null;
      _locationPermanentlyDenied = false;
      range = nextRange ?? range;
      indoorOnly = nextIndoor ?? indoorOnly;
    });
    try {
      final result = await widget.engine.suggest(range, indoorOnly: indoorOnly);
      if (mounted) {
        setState(() {
          suggestion = result;
          loading = false;
          _historyFuture = widget.historyStore.entries();
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = _messageFor(exception);
          _locationPermanentlyDenied =
              exception is LocationUnavailable && exception.permanentlyDenied;
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(context), _history(context), _settings(context)];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'ホーム',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: '履歴'),
          NavigationDestination(icon: Icon(Icons.tune), label: '設定'),
        ],
      ),
    );
  }

  Widget _home(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      children: [
        Text(
          '雑旅',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 30),
        Text(
          suggestion == null ? '今日どっか行く？' : '今日は、',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF272421),
          ),
        ),
        if (suggestion != null) ...[
          Text(
            suggestion!.name,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${suggestion!.category}  ·  全国の候補から選びました',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF756F67),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              await widget.engine.commit(suggestion!);
              final opened = await widget.engine.mapsLauncher.open(suggestion!);
              if (mounted) {
                setState(() {
                  _historyFuture = widget.historyStore.entries();
                  if (!opened) error = '地図アプリを開けませんでした。';
                });
              }
            },
            icon: const Icon(Icons.directions_outlined),
            label: const Text('ここにする'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: loading ? null : () => suggest(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('別の'),
          ),
          const SizedBox(height: 20),
          _changeRangeRow(theme),
          const SizedBox(height: 28),
        ] else ...[
          Text(
            '考えすぎず、距離だけ選んでください。',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF756F67),
            ),
          ),
          const SizedBox(height: 28),
          _rangeButton('近場', '現在地から約50kmの気軽なおでかけ', TripRange.nearby),
          _rangeButton('ちょい遠出', '約120km・いつもより少し遠くへ', TripRange.medium),
          _rangeButton('遠出', '約250km・今日はちゃんと出かける', TripRange.far),
        ],
        if (error != null)
          _ErrorBox(
            message: error!,
            onAction: _locationPermanentlyDenied
                ? Geolocator.openAppSettings
                : null,
          ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '現在地を使って候補を選びます',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF756F67),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'データ提供: OpenStreetMap contributors',
          style: TextStyle(fontSize: 11, color: Color(0xFF756F67)),
        ),
      ],
    );
  }

  Widget _changeRangeRow(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '条件を変える',
        style: theme.textTheme.labelMedium?.copyWith(
          color: const Color(0xFF756F67),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          _rangeChip('近場', TripRange.nearby),
          _rangeChip('ちょい遠出', TripRange.medium),
          _rangeChip('遠出', TripRange.far),
        ],
      ),
    ],
  );

  Widget _rangeChip(String title, TripRange value) {
    final selected = range == value;
    return ChoiceChip(
      label: Text(title),
      selected: selected,
      onSelected: selected || loading
          ? null
          : (_) => suggest(nextRange: value),
    );
  }

  Widget _rangeButton(String title, String subtitle, TripRange value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton(
          onPressed: loading ? null : () => suggest(nextRange: value),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF756F67)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      );

  Widget _history(
    BuildContext context,
  ) => FutureBuilder<List<HistoryEntry>>(
    future: _historyFuture,
    builder: (context, snapshot) {
      final items = snapshot.data ?? [];
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          Text(
            '履歴',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('最近、雑に決めた場所', style: TextStyle(color: Color(0xFF756F67))),
          const SizedBox(height: 24),
          if (items.isEmpty)
            const Text('まだ履歴はありません。まずはホームから。')
          else
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(item.name),
                subtitle: Text(
                  '${item.category}  ·  ${_formatDate(item.date.toIso8601String())}',
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _settings(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
    children: [
      Text(
        '設定',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 24),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('屋内施設のみ'),
                subtitle: const Text('天気を使わず、屋内施設だけから選びます'),
        value: indoorOnly,
        onChanged: (value) => setState(() => indoorOnly = value),
      ),
      const Divider(height: 32),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('位置情報'),
        subtitle: Text('候補を選ぶために現在地を使います'),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('OSM attribution'),
        subtitle: Text('© OpenStreetMap contributors'),
      ),
    ],
  );

  String _formatDate(String? value) {
    if (value == null) return '日時不明';
    final date = DateTime.tryParse(value);
    if (date == null) return '日時不明';
    return '${date.month}/${date.day}';
  }

  String _messageFor(Object exception) => switch (exception) {
    LocationUnavailable(permanentlyDenied: true) =>
      '位置情報が許可されていません。設定から許可してください。',
    LocationUnavailable(serviceDisabled: true) =>
      '位置情報サービスがオフです。設定からオンにしてください。',
    LocationUnavailable(denied: true) =>
      '位置情報の利用が拒否されました。もう一度お試しください。',
    LocationUnavailable(timeout: true) =>
      '位置情報の取得に時間がかかりました。もう一度お試しください。',
    LocationUnavailable() => '位置情報を取得できませんでした。設定を確認してもう一度お試しください。',
    NoSuggestion() => '近くに条件に合う候補がありません。距離を広げてお試しください。',
    _ => '候補を取得できませんでした。もう一度お試しください。',
  };
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, this.onAction});
  final String message;
  final Future<bool> Function()? onAction;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9E2),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: Color(0xFF8C3020))),
        if (onAction != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async => await onAction!(),
            child: const Text('設定を開く'),
          ),
        ],
      ],
    ),
  );
}
