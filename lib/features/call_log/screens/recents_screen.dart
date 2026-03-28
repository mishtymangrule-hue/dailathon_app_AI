import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/call_utils.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CallLogEntry> _allLogs = [];
  bool _isLoading = true;
  bool _permissionDenied = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<int> _selectedIndices = {};
  bool get _isSelecting => _selectedIndices.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCallLogs();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCallLogs() async {
    setState(() { _isLoading = true; _permissionDenied = false; });

    final status = await Permission.phone.request();
    if (!status.isGranted) {
      setState(() { _isLoading = false; _permissionDenied = true; });
      return;
    }

    // Read all call logs from device
    final Iterable<CallLogEntry> entries = await CallLog.get();

    if (!mounted) return;
    setState(() {
      _allLogs = entries.toList();
      _isLoading = false;
    });
  }

  List<CallLogEntry> _filterByType(CallType type) =>
      _applySearch(_allLogs.where((e) => e.callType == type).toList());

  List<CallLogEntry> _applySearch(List<CallLogEntry> entries) {
    if (_searchQuery.isEmpty) return entries;
    return entries.where((e) {
      final name = (e.name ?? '').toLowerCase();
      final number = (e.number ?? '').toLowerCase();
      return name.contains(_searchQuery) || number.contains(_searchQuery);
    }).toList();
  }

  void _deleteEntry(CallLogEntry entry) {
    setState(() {
      _allLogs.removeWhere((e) => e.timestamp == entry.timestamp && e.number == entry.number);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call log entry removed'), duration: Duration(seconds: 1)),
    );
  }

  void _deleteSelected(List<CallLogEntry> visibleEntries) {
    final toRemove = _selectedIndices.map((i) => visibleEntries[i]).toList();
    setState(() {
      for (final entry in toRemove) {
        _allLogs.removeWhere((e) => e.timestamp == entry.timestamp && e.number == entry.number);
      }
      _selectedIndices.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${toRemove.length} entries removed'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelecting
            ? Text('${_selectedIndices.length} selected')
            : const Text('Call Logs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isSelecting) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSelected(_applySearch(_allLogs)),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedIndices.clear()),
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search call logs...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Missed'),
                  Tab(text: 'Incoming'),
                  Tab(text: 'Outgoing'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Call log permission denied',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Enable call log access in Settings.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _CallLogList(
          entries: _applySearch(_allLogs),
          onRefresh: _loadCallLogs,
          onDelete: _deleteEntry,
          selectedIndices: _selectedIndices,
          onSelectionChanged: (indices) => setState(() {
            _selectedIndices
              ..clear()
              ..addAll(indices);
          }),
        ),
        _CallLogList(
            entries: _filterByType(CallType.missed),
            onRefresh: _loadCallLogs,
            onDelete: _deleteEntry,
            selectedIndices: _selectedIndices,
            onSelectionChanged: (indices) => setState(() {
              _selectedIndices
                ..clear()
                ..addAll(indices);
            })),
        _CallLogList(
            entries: _filterByType(CallType.incoming),
            onRefresh: _loadCallLogs,
            onDelete: _deleteEntry,
            selectedIndices: _selectedIndices,
            onSelectionChanged: (indices) => setState(() {
              _selectedIndices
                ..clear()
                ..addAll(indices);
            })),
        _CallLogList(
            entries: _filterByType(CallType.outgoing),
            onRefresh: _loadCallLogs,
            onDelete: _deleteEntry,
            selectedIndices: _selectedIndices,
            onSelectionChanged: (indices) => setState(() {
              _selectedIndices
                ..clear()
                ..addAll(indices);
            })),
      ],
    );
  }
}

class _CallLogList extends StatelessWidget {
  final List<CallLogEntry> entries;
  final Future<void> Function() onRefresh;
  final void Function(CallLogEntry) onDelete;
  final Set<int> selectedIndices;
  final ValueChanged<Set<int>> onSelectionChanged;

  const _CallLogList({
    required this.entries,
    required this.onRefresh,
    required this.onDelete,
    required this.selectedIndices,
    required this.onSelectionChanged,
  });

  bool get _isSelecting => selectedIndices.isNotEmpty;

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '0s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  String _formatTimestamp(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _dateGroup(int? ms) {
    if (ms == null) return 'Unknown';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(dt.year, dt.month, dt.day);

    if (entryDay == today) return 'Today';
    if (entryDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(dt).inDays < 7) return 'This Week';
    return 'Older';
  }

  IconData _getIcon(CallType? type) {
    switch (type) {
      case CallType.incoming: return Icons.call_received;
      case CallType.outgoing: return Icons.call_made;
      case CallType.missed:   return Icons.call_missed;
      case CallType.rejected: return Icons.call_end;
      default:                return Icons.call;
    }
  }

  Color _getColor(CallType? type) {
    switch (type) {
      case CallType.incoming: return Colors.green;
      case CallType.outgoing: return Colors.blue;
      case CallType.missed:   return Colors.red;
      case CallType.rejected: return Colors.orange;
      default:                return Colors.grey;
    }
  }

  void _showCallDetail(BuildContext context, CallLogEntry entry) {
    final color = _getColor(entry.callType);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(_getIcon(entry.callType), color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                entry.name?.isNotEmpty == true ? entry.name! : (entry.number ?? 'Unknown'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (entry.name?.isNotEmpty == true)
                Text(entry.number ?? '', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              _detailRow('Type', entry.callType?.name ?? 'unknown'),
              _detailRow('Duration', _formatDuration(entry.duration)),
              _detailRow('Time', _formatTimestamp(entry.timestamp)),
              if (entry.simDisplayName?.isNotEmpty == true)
                _detailRow('SIM', entry.simDisplayName!),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      CallUtils.makeCall(context, entry.number ?? '');
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call_end, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No call logs found',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Build grouped list with date headers
    final List<_ListItem> items = [];
    String? currentGroup;
    for (int i = 0; i < entries.length; i++) {
      final group = _dateGroup(entries[i].timestamp);
      if (group != currentGroup) {
        currentGroup = group;
        items.add(_ListItem.header(group));
      }
      items.add(_ListItem.entry(i, entries[i]));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isHeader) {
            return Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                item.headerTitle!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            );
          }

          final entry = item.entry!;
          final entryIndex = item.entryIndex!;
          final color = _getColor(entry.callType);
          final number = entry.number ?? 'Unknown';
          final name = entry.name?.isNotEmpty == true ? entry.name! : number;
          final isSelected = selectedIndices.contains(entryIndex);

          return Dismissible(
            key: ValueKey('${entry.timestamp}_${entry.number}_$entryIndex'),
            direction: _isSelecting ? DismissDirection.none : DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => onDelete(entry),
            child: ListTile(
              selected: isSelected,
              selectedTileColor: Colors.blue.withValues(alpha: 0.08),
              leading: _isSelecting
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        final updated = Set<int>.from(selectedIndices);
                        isSelected ? updated.remove(entryIndex) : updated.add(entryIndex);
                        onSelectionChanged(updated);
                      },
                    )
                  : CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(_getIcon(entry.callType), color: color),
                    ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${_formatTimestamp(entry.timestamp)}  •  ${_formatDuration(entry.duration)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              trailing: _isSelecting
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () => CallUtils.makeCall(context, number),
                    ),
              onTap: _isSelecting
                  ? () {
                      final updated = Set<int>.from(selectedIndices);
                      isSelected ? updated.remove(entryIndex) : updated.add(entryIndex);
                      onSelectionChanged(updated);
                    }
                  : () => _showCallDetail(context, entry),
              onLongPress: () {
                final updated = Set<int>.from(selectedIndices);
                updated.add(entryIndex);
                onSelectionChanged(updated);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Helper class for building a grouped list with headers and entries.
class _ListItem {
  final bool isHeader;
  final String? headerTitle;
  final int? entryIndex;
  final CallLogEntry? entry;

  _ListItem.header(this.headerTitle)
      : isHeader = true,
        entryIndex = null,
        entry = null;

  _ListItem.entry(this.entryIndex, this.entry)
      : isHeader = false,
        headerTitle = null;
}

