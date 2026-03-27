import 'package:dailathon_dialer/features/in_call/screens/active_call_screen.dart' show ActiveCallScreen;
import 'package:dailathon_dialer/features/in_call/screens/screens.dart' show ActiveCallScreen;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/call_sync_models.dart';
import '../bloc/call_sync_bloc.dart';

/// Bottom sheet for syncing an unknown caller's call data to the CRM.
///
/// Presents cascading dropdowns: Degree → Program → Response → Sub-Response.
/// Launched from [ActiveCallScreen] when the caller has no CRM record.
class CallSyncFormSheet extends StatelessWidget {
  const CallSyncFormSheet({Key? key}) : super(key: key);

  /// Show the sheet. [callId] and [phoneNumber] are required;
  /// [contactId] is optional (pre-known contact).
  static Future<void> show(
    BuildContext context, {
    required String callId,
    required String phoneNumber,
    String? contactId,
  }) {
    context.read<CallSyncBloc>().add(CallSyncFormRequested(
          callId: callId,
          phoneNumber: phoneNumber,
          contactId: contactId,
        ));
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<CallSyncBloc>(),
        child: const CallSyncFormSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => BlocConsumer<CallSyncBloc, CallSyncState>(
          listener: (context, state) {
            if (state is CallSyncSuccess) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call synced to CRM')),
              );
            }
            if (state is CallSyncError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sync failed: ${state.message}')),
              );
            }
          },
          builder: (context, state) {
            if (state is CallSyncFormLoading || state is CallSyncIdle) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CallSyncSubmitting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CallSyncError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: ${state.message}'),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
            if (state is CallSyncFormReady) {
              return _FormBody(
                state: state,
                scrollController: scrollController,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
}

class _FormBody extends StatelessWidget {
  const _FormBody({required this.state, required this.scrollController});

  final CallSyncFormReady state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CallSyncBloc>();
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Sync Call — ${state.phoneNumber}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),

          // Degree dropdown
          _SyncDropdown<DegreeOption>(
            label: 'Degree',
            items: state.degrees,
            selected: state.selectedDegree,
            itemLabel: (d) => d.name,
            onChanged: (d) => bloc.add(SyncDegreeSelected(d)),
          ),
          const SizedBox(height: 16),

          // Program dropdown (populated after degree selected)
          _SyncDropdown<ProgramOption>(
            label: 'Program',
            items: state.availablePrograms,
            selected: state.selectedProgram,
            itemLabel: (p) => p.name,
            enabled: state.selectedDegree != null,
            onChanged: (p) => bloc.add(SyncProgramSelected(p)),
          ),
          const SizedBox(height: 16),

          // Response dropdown
          _SyncDropdown<ResponseOption>(
            label: 'Call Response',
            items: state.responses,
            selected: state.selectedResponse,
            itemLabel: (r) => r.label,
            onChanged: (r) => bloc.add(SyncResponseSelected(r)),
          ),
          const SizedBox(height: 16),

          // Sub-response (optional)
          if (state.availableSubResponses.isNotEmpty) ...[
            _SyncDropdown<SubResponseOption>(
              label: 'Sub-Response',
              items: state.availableSubResponses,
              selected: state.selectedSubResponse,
              itemLabel: (s) => s.label,
              onChanged: (s) => bloc.add(SyncSubResponseSelected(s)),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmittable
                  ? () => bloc.add(const CallSyncSubmitted())
                  : null,
              child: const Text('Submit'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncDropdown<T> extends StatelessWidget {
  const _SyncDropdown({
    required this.label,
    required this.items,
    required this.selected,
    required this.itemLabel,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final List<T> items;
  final T? selected;
  final String Function(T) itemLabel;
  final void Function(T) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        initialValue: selected,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.isEmpty
            ? []
            : items
                .map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item)),
                    ))
                .toList(),
        onChanged: enabled && items.isNotEmpty
            ? (val) {
                if (val != null) onChanged(val);
              }
            : null,
        hint: enabled
            ? (items.isEmpty ? const Text('Loading…') : null)
            : const Text('Select degree first'),
      );
}
