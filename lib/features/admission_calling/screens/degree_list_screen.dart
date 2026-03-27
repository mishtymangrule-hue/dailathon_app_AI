import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../admission_calling/bloc/admission_calling_bloc.dart';

/// DegreeListScreen displays all degree programmes.
class DegreeListScreen extends StatelessWidget {
  const DegreeListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Degrees'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<AdmissionCallingBloc, AdmissionCallingState>(
        builder: (context, state) {
          if (state is AdmissionCallingIdle) {
            return const Center(child: CircularProgressIndicator());
          }

          // Mock data for demonstration
          final mockDegrees = [
            {'id': '1', 'name': 'B.Tech', 'totalStudents': 150, 'pending': 28},
            {'id': '2', 'name': 'BCA', 'totalStudents': 120, 'pending': 15},
            {'id': '3', 'name': 'MBA', 'totalStudents': 80, 'pending': 8},
            {'id': '4', 'name': 'B.Sc', 'totalStudents': 200, 'pending': 42},
          ];

          return ListView.builder(
            itemCount: mockDegrees.length,
            itemBuilder: (context, index) {
              final degree = mockDegrees[index];
              return ListTile(
                title: Text(degree['name']! as String),
                subtitle: Text(
                  '${degree['totalStudents']} students',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${degree['pending']} pending',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                onTap: () {
                  context.push(
                    '/admission/${degree['id']}/responses',
                    extra: {'degreeName': degree['name']},
                  );
                },
              );
            },
          );
        },
      ),
    );
}
