import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../call_log/bloc/call_log_bloc.dart';

/// RecentsScreen displays call history with filtering options.
class RecentsScreen extends StatefulWidget {
  const RecentsScreen({Key? key}) : super(key: key);

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final filterType = _getFilterType(_tabController.index);
    context.read<CallLogBloc>().add(FilterChanged(filter: filterType));
  }

  String _getFilterType(int index) {
    switch (index) {
      case 1:
        return 'missed';
      case 2:
        return 'outgoing';
      case 3:
        return 'incoming';
      default:
        return 'all';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Missed'),
            Tab(text: 'Outgoing'),
            Tab(text: 'Incoming'),
          ],
        ),
      ),
      body: BlocBuilder<CallLogBloc, CallLogState>(
        builder: (context, state) {
          if (state is CallLogLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CallLogLoaded) {
            final callLog = state.callLog;

            if (callLog.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No call history',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: callLog.length,
              itemBuilder: (context, index) {
                final entry = callLog[index];
                return _CallLogTile(
                  entry: entry,
                  onDelete: () {
                    context.read<CallLogBloc>().add(
                          EntryDeleted(id: entry.id),
                        );
                  },
                  onBlock: () {
                    // TODO: Implement block
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Block feature coming soon')),
                    );
                  },
                );
              },
            );
          }

          return const Center(child: Text('Error loading call log'));
        },
      ),
    );
}

/// Call log entry tile.
class _CallLogTile extends StatelessWidget {

  const _CallLogTile({
    required this.entry,
    required this.onDelete,
    required this.onBlock,
  });
  final dynamic entry;
  final VoidCallback onDelete;
  final VoidCallback onBlock;

  IconData _getCallTypeIcon(int type) {
    switch (type) {
      case 1: // Incoming
        return Icons.call_received;
      case 2: // Outgoing
        return Icons.call_made;
      case 3: // Missed
        return Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  Color _getCallTypeColor(int type) {
    switch (type) {
      case 1: // Incoming
        return Colors.green;
      case 2: // Outgoing
        return Colors.blue;
      case 3: // Missed
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) => Material(
      child: InkWell(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.content_copy),
                  title: const Text('Copy Number'),
                  onTap: () {
                    Navigator.pop(ctx);
                    // TODO: Copy to clipboard
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Block Number'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onBlock();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                ),
              ],
            ),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getCallTypeColor(entry.type).withOpacity(0.2),
            child: Icon(
              _getCallTypeIcon(entry.type),
              color: _getCallTypeColor(entry.type),
            ),
          ),
          title: Text(entry.name ?? entry.phoneNumber),
          subtitle: Text(entry.phoneNumber),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(entry.timestamp),
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
              ),
              if (entry.duration > 0)
                Text(
                  '${entry.duration ~/ 60}:${(entry.duration % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
            ],
          ),
        ),
      ),
    );

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
