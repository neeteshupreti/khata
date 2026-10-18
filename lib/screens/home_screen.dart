import 'package:flutter/material.dart';

import '../db/local_database.dart';
import '../l10n/app_strings.dart';
import '../models/record.dart';
import '../models/sort_option.dart';
import '../services/app_colors.dart';
import '../services/settings.dart';
import '../widgets/calendar_toggle.dart';
import '../widgets/record_tile.dart';
import '../widgets/language_menu.dart';
import '../widgets/sort_dialog.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';
import 'people_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _RecordsTab(),
          PeopleScreen(),
          SummaryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: tr('recordsTab')),
          NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people),
              label: tr('peopleTab')),
          NavigationDestination(
              icon: const Icon(Icons.analytics_outlined),
              selectedIcon: const Icon(Icons.analytics),
              label: tr('summaryTab')),
        ],
      ),
    );
  }
}

class _RecordsTab extends StatefulWidget {
  const _RecordsTab();

  @override
  State<_RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<_RecordsTab>
    with SettingsListener<_RecordsTab>, DataListener<_RecordsTab> {

  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  SortOption _sortOption = SortOption.dateNewest;
  late Future<List<Record>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = LocalDatabase.instance.getAllRecords();
  }

  @override
  void onDataChanged() {
    setState(() => _recordsFuture = LocalDatabase.instance.getAllRecords());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Record> _filterAndSort(Iterable<Record> all) {
    var records = all.where(_matchesSearch).toList();

    switch (_sortOption.field) {
      case SortField.name:
        records.sort((a, b) => _sortOption.direction == SortDirection.desc
            ? b.name.toLowerCase().compareTo(a.name.toLowerCase())
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SortField.date:
        records.sort((a, b) => _sortOption.direction == SortDirection.desc
            ? b.date.compareTo(a.date)
            : a.date.compareTo(b.date));
      case SortField.amount:
        records.sort((a, b) => _sortOption.direction == SortDirection.desc
            ? b.principal.compareTo(a.principal)
            : a.principal.compareTo(b.principal));
    }
    return records;
  }

  bool _matchesSearch(Record r) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return r.name.toLowerCase().contains(q) || r.phone.contains(q);
  }

  void _openSort() async {
    final result = await SortDialog.show(context, _sortOption);
    if (!mounted) return;
    if (result != null && result != _sortOption) {
      setState(() => _sortOption = result);
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

  Future<void> _openAdd() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddEditScreen()));
    if (mounted) onDataChanged();
  }

  Future<void> _openDetail(Record r) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => DetailScreen(recordId: r.id)));
    if (mounted) onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.large(
        onPressed: _openAdd,
        tooltip: tr('addRecord'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        heroTag: 'addRecord',
        child: const Icon(Icons.add, size: 32),
      ),
      body: Column(
        children: [

          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Expanded(
                        child: Text(tr('appName'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            )),
                      ),
                      const LanguageMenu(),

                      IconButton(
                        icon: Icon(
                          _showSearch ? Icons.close : Icons.search,
                          size: 24,
                          color: AppColors.onSurface,
                        ),
                        tooltip: tr('searchHint'),
                        onPressed: _toggleSearch,
                      ),
                      const SizedBox(width: 4),

                      IconButton(
                        icon: const Icon(Icons.sort,
                            size: 24, color: AppColors.onSurface),
                        tooltip: tr('sort'),
                        onPressed: _openSort,
                      ),
                    ],
                  ),

                  if (_showSearch)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: tr('searchHint'),
                            hintStyle: const TextStyle(
                                color: AppColors.onSurfaceVariant),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            prefixIconConstraints:
                                const BoxConstraints(minWidth: 40),
                            suffixIcon: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: _clearSearch,
                                    tooltip: tr('clearSearch'),
                                  ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            border: const OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 16),
                          onSubmitted: (_) => _openSort(),
                        ),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: CalendarToggle(),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),
          Expanded(
            child: FutureBuilder<List<Record>>(
              future: _recordsFuture,
              builder: (context, snap) {
                if (!snap.hasData) {
                  if (snap.hasError) {
                    return Center(child: Text(tr('error')));
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                final records = _filterAndSort(snap.data!);
                if (records.isEmpty) {
                  return _emptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => RecordTile(
                    record: records[i],
                    onTap: () => _openDetail(records[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final showingSearch = _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'logo.jpg',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(showingSearch ? tr('noResults') : tr('emptyTitle'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(tr('emptyHint'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
