import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:zephyron/enums.dart';
import 'package:zephyron/models/artifact.dart' as model;
import 'package:zephyron/components/artifact.dart';
import 'package:zephyron/utils/formats.dart';
import 'package:zephyron/dashboard/chats/discussion.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => ChatsPageState();
}

class ChatsPageState extends State<ChatsPage> {
  Filters filter = Filters.all;

  final List<model.Artifact> artifacts = [
    model.Artifact(
      id: '1',
      name: 'Emma Wilson',
      avatar: 'https://i.pravatar.cc/150?img=1',
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      message: 'Typing...',
      status: Status.sending,
    ),
    model.Artifact(
      id: '2',
      name: 'Sarah Johnson',
      avatar: 'https://i.pravatar.cc/150?img=20',
      timestamp: DateTime.now().subtract(Duration(minutes: 15)),
      message: 'Let\'s sync up tomorrow',
      status: Status.delivered,
    ),
    model.Artifact(
      id: '3',
      name: 'James Chen',
      avatar: 'https://i.pravatar.cc/150?img=2',
      timestamp: DateTime.now().subtract(Duration(hours: 1)),
      message: 'Sent a photo',
      status: Status.sent,
    ),
    model.Artifact(
      id: '4',
      name: 'Mike Thompson',
      avatar: 'https://i.pravatar.cc/150?img=21',
      timestamp: DateTime.now().subtract(Duration(hours: 3)),
      message: 'Meeting at 3pm',
      status: Status.delivered,
    ),
    model.Artifact(
      id: '5',
      name: 'Sofia Rodriguez',
      avatar: 'https://i.pravatar.cc/150?img=3',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      message: 'You: Sounds good!',
      status: Status.read,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = Artifact.of(context);

    List<model.Artifact> displayedChats;
    switch (filter) {
      case Filters.all:
        displayedChats = artifacts;
        break;
      case Filters.unread:
        displayedChats = artifacts
            .where((artifact) => artifact.status != Status.read)
            .toList();
        break;
      case Filters.read:
        displayedChats = artifacts
            .where((artifact) => artifact.status == Status.read)
            .toList();
        break;
      default:
        displayedChats = artifacts;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://i.pravatar.cc/150?img=1',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
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
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
                  filled: true,
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
                        setState(() {
                          filter = filterType;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: displayedChats.length,
                itemBuilder: (context, index) {
                  final artifact = displayedChats[index];

                  return Artifact(
                    skeleton: artifact,
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(artifact.avatar),
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
                                  color: style.badgeBackgroundColor!,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(artifact.name, style: style.titleStyle),
                    subtitle: Row(
                      children: [
                        if (artifact.status == Status.sending)
                          Icon(
                            PhosphorIconsRegular.clock,
                            size: 14,
                            color: style.statusIconColor,
                          )
                        else if (artifact.status == Status.sent)
                          Icon(
                            PhosphorIconsRegular.check,
                            size: 14,
                            color: style.statusIconColor,
                          )
                        else if (artifact.status == Status.delivered)
                            Icon(
                              PhosphorIconsRegular.checks,
                              size: 14,
                              color: style.statusIconColor,
                            )
                          else if (artifact.status == Status.read)
                              Icon(
                                PhosphorIconsRegular.checks,
                                size: 14,
                                color: style.statusIconColor,
                              ),
                        if (artifact.status != null) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            artifact.message,
                            style: style.subtitleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      time(artifact.timestamp),
                      style: style.trailingStyle,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiscussionScreen(),
                        ),
                      );
                    },
                    onLongPress: () {},
                  );
                },
                separatorBuilder: (context, index) =>
                const SizedBox(height: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}