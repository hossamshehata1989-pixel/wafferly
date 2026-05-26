import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/members_controller.dart';
import '../models/member_model.dart';
import 'add_member_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07131D),

      appBar: AppBar(
        backgroundColor: const Color(0xFF07131D),
        elevation: 0,
        title: const Text("Members"),
      ),

      body: Consumer<MembersController>(
        builder: (_, controller, __) {
          final members = controller.members;

          if (members.isEmpty) {
            return const Center(
              child: Text(
                "No members yet",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),

            children: [
              _summaryCard(members.length),

              const SizedBox(height: 20),

              const Text(
                "All Members",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              ...members.map((member) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),

                  child: _memberCard(context, member, controller),
                );
              }),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),

        onPressed: () async {
          final member = await Navigator.push(
            context,

            MaterialPageRoute(builder: (_) => AddMemberScreen()),
          );

          if (member != null) {
            context.read<MembersController>().addMember(member);
          }
        },
      ),
    );
  }

  Widget _summaryCard(int totalMembers) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFF101C2B),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,

            backgroundColor: Color(0xFF16253A),

            child: Icon(Icons.people, color: Colors.blue),
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Members Summary",

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Overview of your members",

                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),

          Text(
            totalMembers.toString(),

            style: const TextStyle(
              color: Colors.blue,

              fontSize: 35,

              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(
    BuildContext context,
    MemberModel member,
    MembersController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFF101C2B),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,

                child: Text(member.name[0].toUpperCase()),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      member.name,

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 22,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      member.relationshipId,

                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {
                  controller.removeMember(member.id);
                },

                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(color: Colors.white12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              _stat(
                "Transactions",
                member.transactionsCount.toString(),
                Colors.blue,
              ),

              _stat("Spent", "${member.monthlySpent} EGP", Colors.green),

              _stat("Goals", member.goalsCount.toString(), Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54)),

        const SizedBox(height: 8),

        Text(
          value,

          style: TextStyle(
            color: color,

            fontSize: 18,

            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
