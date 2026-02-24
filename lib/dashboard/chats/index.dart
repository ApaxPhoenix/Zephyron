import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:zephyron/enums.dart';
import 'package:zephyron/components/artifact.dart';
import 'package:zephyron/utils/formats.dart';
import 'package:zephyron/dashboard/chats/discussion.dart';
import 'package:zephyron/main.dart';
import 'package:zephyron/theme.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => ChatsPageState();
}

class ChatsPageState extends State<ChatsPage> {
  Filters filter = Filters.all;
  final TextEditingController discover = TextEditingController();

  @override
  void dispose() {
    discover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = Artifact.of(context);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
          stream: () async* {
            final user = await account.get();
            final rows = await tables.listRows(
              databaseId: '69951d1f002692e40827',
              tableId: '69965edb0019ed7a133f',
              queries: [Query.equal('email', user.email)],
            );
            final result = await tables.listRows(
              databaseId: '69951d1f002692e40827',
              tableId: '699cc9550038b09d24ae',
            );
            final avatar = rows.rows.isNotEmpty
                ? rows.rows.first.data['avatar'] as String?
                : null;
            yield (avatar, result.rows);
            yield* realtime
                .subscribe([
              'databases.69951d1f002692e40827.collections.699cc9550038b09d24ae.documents',
            ])
                .stream
                .asyncMap((_) async {
              final updated = await tables.listRows(
                databaseId: '69951d1f002692e40827',
                tableId: '699cc9550038b09d24ae',
              );
              return (avatar, updated.rows);
            });
          }(),
          builder: (context, snapshot) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: snapshot.data?.$1 != null
                            ? Image.network(
                          snapshot.data!.$1!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.neutral100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.user,
                            size: 20,
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ),
                      Text(
                        'Chats',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: discover,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Discover',
                      prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
                      filled: true,
                      suffixIcon: discover.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(PhosphorIconsRegular.x),
                        onPressed: () {
                          discover.clear();
                          setState(() {});
                        },
                      )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 40),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: Filters.values.map((filterType) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filterType.label),
                          selected: filter == filterType,
                          onSelected: (selected) {
                            setState(() => filter = filterType);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: switch (snapshot.connectionState) {
                    ConnectionState.waiting => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    ConnectionState.active when snapshot.hasError => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIconsRegular.warning, size: 48, color: AppTheme.neutral300),
                          const SizedBox(height: 12),
                          Text(
                            snapshot.error is AppwriteException
                                ? (snapshot.error as AppwriteException).message ?? 'Something went wrong'
                                : 'Something went wrong',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.neutral500),
                          ),
                        ],
                      ),
                    ),
                    _ when snapshot.hasData => () {
                      final rows = snapshot.data!.$2.where((row) {
                        final status = row.data['status'] as String?;
                        final name = (row.data['name'] ?? '') as String;
                        final matchesFilter = switch (filter) {
                          Filters.unread => status != 'received',
                          Filters.read => status == 'received',
                          _ => true,
                        };
                        final matchesSearch = discover.text.trim().isEmpty ||
                            name.toLowerCase().contains(discover.text.trim().toLowerCase());
                        return matchesFilter && matchesSearch;
                      }).toList();

                      if (rows.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsRegular.chatsCircle, size: 72, color: AppTheme.neutral300),
                              const SizedBox(height: 16),
                              Text(
                                'No conversations yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.neutral500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a new chat to get the conversation going',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.neutral500),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DiscussionScreen()),
                          ),
                          onLongPress: () {},
                          child: Row(
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppTheme.neutral100,
                                      backgroundImage: (rows[index].data['avatar'] ?? '').isNotEmpty
                                          ? NetworkImage(rows[index].data['avatar'])
                                          : null,
                                      child: (rows[index].data['avatar'] ?? '').isEmpty
                                          ? const Icon(PhosphorIconsRegular.user, size: 20, color: AppTheme.neutral500)
                                          : null,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: style.onlineIndicatorColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: style.badgeBackgroundColor!, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rows[index].data['name'] ?? 'Unnamed', style: style.titleStyle),
                                    Text(
                                      rows[index].data['message'] ?? '',
                                      style: style.subtitleStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(time(DateTime.parse(rows[index].$createdAt)), style: style.trailingStyle),
                                  const SizedBox(height: 4),
                                  Icon(
                                    switch (rows[index].data['status'] as String?) {
                                      'sent' => PhosphorIconsRegular.check,
                                      'delivered' => PhosphorIconsRegular.checks,
                                      'received' => PhosphorIconsFill.checks,
                                      _ => PhosphorIconsRegular.clock,
                                    },
                                    size: 16,
                                    color: rows[index].data['status'] == 'received'
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }(),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}