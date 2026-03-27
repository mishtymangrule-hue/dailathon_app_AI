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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Logs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
        _CallLogList(entries: _applySearch(_allLogs), onRefresh: _loadCallLogs, onDelete: _deleteEntry),
        _CallLogList(
            entries: _filterByType(CallType.missed),
            onRefresh: _loadCallLogs, onDelete: _deleteEntry),
        _CallLogList(
            entries: _filterByType(CallType.incoming),
            onRefresh: _loadCallLogs, onDelete: _deleteEntry),
        _CallLogList(
            entries: _filterByType(CallType.outgoing),
            onRefresh: _loadCallLogs, onDelete: _deleteEntry),
      ],
    );
  }
}

class _CallLogList extends StatelessWidget {
  final List<CallLogEntry> entries;
  final Future<void> Function() onRefresh;
  final void Function(CallLogEntry) onDelete;

  const _CallLogList({required this.entries, required this.onRefresh, required this.onDelete});

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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        itemCount: entries.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final color = _getColor(entry.callType);
          final number = entry.number ?? 'Unknown';
          final name = entry.name?.isNotEmpty == true
              ? entry.name!
              : number;

          return Dismissible(
            key: ValueKey('${entry.timestamp}_${entry.number}_$index'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => onDelete(entry),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(_getIcon(entry.callType), color: color),
              ),
              title: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${_formatTimestamp(entry.timestamp)}  •  '
                '${_formatDuration(entry.duration)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => CallUtils.makeCall(context, number),
              ),
            ),
          );
        },
      ),
    );
  }
}

