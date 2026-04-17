import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:zephyron/enums.dart';
import '_artifact.dart';
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
  Types type = Types.all;
  Filters filter = Filters.all;
  final TextEditingController search = TextEditingController();
  Timer? debounce;
  AsyncSnapshot<List<models.Row>>? users;
  String? me;

  @override
  void initState() {
    super.initState();
    account.get().then((u) => me = u.email);
  }

  @override
  void dispose() {
    search.dispose();
    debounce?.cancel();
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
            final chats = await tables.listRows(
              databaseId: '69951d1f002692e40827',
              tableId: '699cc9550038b09d24ae',
            );
            final avatar = rows.rows.isNotEmpty
                ? rows.rows.first.data['avatar'] as String?
                : null;
            yield (avatar, chats.rows);
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
            final ids =
                snapshot.data?.$2
                    .map((row) => row.data['userId'] as String?)
                    .whereType<String>()
                    .toSet() ??
                {};

            final searching = search.text.trim().isNotEmpty;

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
                    controller: search,
                    onChanged: (query) {
                      debounce?.cancel();
                      if (query.trim().isEmpty) {
                        setState(() => users = null);
                        return;
                      }
                      debounce = Timer(
                        const Duration(milliseconds: 600),
                        () async {
                          setState(() => users = const AsyncSnapshot.waiting());
                          try {
                            final email = me ?? (await account.get()).email;
                            me = email;

                            final clause = switch (type) {
                              Types.email => Query.contains(
                                'email',
                                query.trim(),
                              ),
                              _ => Query.contains('name', query.trim()),
                            };

                            final result = await tables.listRows(
                              databaseId: '69951d1f002692e40827',
                              tableId: '69965edb0019ed7a133f',
                              queries: [clause],
                            );

                            final filtered = result.rows
                                .where((row) => row.data['email'] != email)
                                .toList();

                            if (mounted) {
                              setState(
                                () => users = AsyncSnapshot.withData(
                                  ConnectionState.done,
                                  filtered,
                                ),
                              );
                            }
                          } catch (error) {
                            if (mounted) {
                              setState(
                                () => users = AsyncSnapshot.withError(
                                  ConnectionState.done,
                                  error,
                                  StackTrace.current,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                    decoration: InputDecoration(
                      hintText: type != Types.all
                          ? 'Type to search...'
                          : 'Discover people...',
                      filled: true,
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      prefixIcon: type != Types.all
                          ? Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 6,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.brand100.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.brand100.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      switch (type) {
                                        Types.email =>
                                          PhosphorIconsRegular.envelope,
                                        Types.username =>
                                          PhosphorIconsRegular.at,
                                        _ => PhosphorIconsRegular.user,
                                      },
                                      size: 12,
                                      color: AppTheme.brand100,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${switch (type) {
                                        Types.email => 'Email',
                                        Types.username => 'Username',
                                        _ => 'All',
                                      }}:',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.brand100,
                                        fontFamily: 'SF Pro',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => type = Types.all),
                                      child: const Icon(
                                        PhosphorIconsRegular.x,
                                        size: 12,
                                        color: AppTheme.brand100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(PhosphorIconsRegular.magnifyingGlass),
                            ),
                      suffixIcon: search.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(PhosphorIconsRegular.x),
                              onPressed: () {
                                search.clear();
                                setState(() => users = null);
                              },
                            )
                          : PopupMenuButton<Types>(
                              icon: const Icon(
                                PhosphorIconsRegular.funnelSimple,
                              ),
                              iconSize: 20,
                              onSelected: (selected) =>
                                  setState(() => type = selected),
                              itemBuilder: (_) => [
                                for (final option in Types.values.where(
                                  (o) => o != Types.all,
                                ))
                                  PopupMenuItem(
                                    value: option,
                                    child: Row(
                                      children: [
                                        Icon(
                                          switch (option) {
                                            Types.email =>
                                              PhosphorIconsRegular.envelope,
                                            Types.username =>
                                              PhosphorIconsRegular.at,
                                            _ => PhosphorIconsRegular.user,
                                          },
                                          size: 16,
                                          color: AppTheme.brand100,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Search by ${switch (option) {
                                            Types.email => 'Email',
                                            Types.username => 'Username',
                                            _ => 'All',
                                          }}',
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
                if (searching) ...[
                  const SizedBox(height: 8),
                  Expanded(
                    child: switch (users?.connectionState) {
                      ConnectionState.waiting => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      ConnectionState.done when users!.hasError => Center(
                        child: Text(
                          'Something went wrong',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ),
                      ConnectionState.done when users!.hasData => () {
                        final existing = users!.data!
                            .where((u) => ids.contains(u.$id))
                            .toList();
                        final fresh = users!.data!
                            .where((u) => !ids.contains(u.$id))
                            .toList();

                        if (existing.isEmpty && fresh.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  PhosphorIconsRegular.magnifyingGlass,
                                  size: 48,
                                  color: AppTheme.neutral300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No users found',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (existing.isNotEmpty) ...[
                              _label('Your Chats', theme),
                              const SizedBox(height: 8),
                              for (final u in existing)
                                _tile(context, u, style, theme, ids),
                            ],
                            if (fresh.isNotEmpty) ...[
                              if (existing.isNotEmpty)
                                const SizedBox(height: 8),
                              _label('New People', theme, divider: true),
                              const SizedBox(height: 8),
                              for (final u in fresh)
                                _tile(context, u, style, theme, ids),
                            ],
                          ],
                        );
                      }(),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 40),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final f in Filters.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(switch (f) {
                                Filters.all => PhosphorIconsRegular.chatCircle,
                                Filters.unread => PhosphorIconsRegular.envelope,
                                Filters.read => PhosphorIconsFill.checks,
                                Filters.groups =>
                                  PhosphorIconsRegular.usersThree,
                                Filters.contacts =>
                                  PhosphorIconsRegular.addressBook,
                              }, size: 14),
                              label: Text(switch (f) {
                                Filters.all => 'All',
                                Filters.unread => 'Unread',
                                Filters.read => 'Read',
                                Filters.groups => 'Groups',
                                Filters.contacts => 'Contacts',
                              }),
                              selected: filter == f,
                              onSelected: (_) => setState(() => filter = f),
                            ),
                          ),
                      ],
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
                            const Icon(
                              PhosphorIconsRegular.warning,
                              size: 48,
                              color: AppTheme.neutral300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              snapshot.error is AppwriteException
                                  ? (snapshot.error as AppwriteException)
                                            .message ??
                                        'Something went wrong'
                                  : 'Something went wrong',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ when snapshot.hasData => () {
                        final rows = snapshot.data!.$2.where((row) {
                          final status = row.data['status'] as String?;
                          return switch (filter) {
                            Filters.unread => status != 'received',
                            Filters.read => status == 'received',
                            _ => true,
                          };
                        }).toList();

                        if (rows.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  PhosphorIconsRegular.chatsCircle,
                                  size: 72,
                                  color: AppTheme.neutral300,
                                ),
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
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DiscussionScreen(id: rows[index].$id),
                              ),
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
                                        backgroundImage:
                                            (rows[index].data['avatar'] ?? '')
                                                .isNotEmpty
                                            ? NetworkImage(
                                                rows[index].data['avatar'],
                                              )
                                            : null,
                                        child:
                                            (rows[index].data['avatar'] ?? '')
                                                .isEmpty
                                            ? const Icon(
                                                PhosphorIconsRegular.user,
                                                size: 20,
                                                color: AppTheme.neutral500,
                                              )
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
                                            border: Border.all(
                                              color:
                                                  style.badgeBackgroundColor!,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rows[index].data['name'] ?? 'Unnamed',
                                        style: style.titleStyle,
                                      ),
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
                                    Text(
                                      time(
                                        DateTime.parse(rows[index].$createdAt),
                                      ),
                                      style: style.trailingStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    Icon(
                                      switch (rows[index].data['status']
                                          as String?) {
                                        'sent' => PhosphorIconsRegular.check,
                                        'delivered' =>
                                          PhosphorIconsRegular.checks,
                                        'received' => PhosphorIconsFill.checks,
                                        _ => PhosphorIconsRegular.clock,
                                      },
                                      size: 16,
                                      color:
                                          rows[index].data['status'] ==
                                              'received'
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.4),
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
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _label(String text, ThemeData theme, {bool divider = false}) {
    return Row(
      children: [
        Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.neutral500,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        if (divider) ...[
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: AppTheme.neutral300, height: 1)),
        ],
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    models.Row user,
    dynamic style,
    ThemeData theme,
    Set<String> ids,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          search.clear();
          setState(() => users = null);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscussionScreen(id: user.$id),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.neutral100,
              backgroundImage: (user.data['avatar'] ?? '').isNotEmpty
                  ? NetworkImage(user.data['avatar'])
                  : null,
              child: (user.data['avatar'] ?? '').isEmpty
                  ? const Icon(
                      PhosphorIconsRegular.user,
                      size: 20,
                      color: AppTheme.neutral500,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.data['name'] ?? 'Unnamed', style: style.titleStyle),
                  if ((user.data['email'] ?? '').isNotEmpty)
                    Text(
                      user.data['email'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (ids.contains(user.$id))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.brand100.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chat',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.brand100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
