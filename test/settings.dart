import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:zephyron/main.dart';
import 'package:zephyron/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutral900,
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder(
                future: () async {
                  final session = await account.get();
                  final user = session.$id;

                  final document = await tables.getRow(
                    databaseId: '697fa52900034a054220d',
                    tableId: 'users',
                    rowId: user,
                  );

                  return document.data;
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.neutral300,
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final data = snapshot.data!;
                  final name = data['name'] ?? 'Unknown';
                  final phone = data['phone'] ?? '+62 1309 - 1710 - 1920';
                  final image = data['profile'];
                  final initials = image == null ? name[0].toUpperCase() : null;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.neutral050,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.neutral100,
                          backgroundImage: image != null
                              ? NetworkImage(image)
                              : null,
                          child: initials != null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.neutral900,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.neutral500,
                                      fontSize: 13,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          PhosphorIconsRegular.caretRight,
                          color: AppTheme.neutral500,
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SettingItem(
                icon: PhosphorIconsRegular.user,
                title: 'Account',
                onTap: () {},
              ),
              SettingItem(
                icon: PhosphorIconsRegular.chatCircle,
                title: 'Chats',
                onTap: () {},
              ),
              SettingItem(
                icon: PhosphorIconsRegular.sun,
                title: 'Appearance',
                onTap: () {},
              ),
              SettingItem(
                icon: PhosphorIconsRegular.bell,
                title: 'Notification',
                onTap: () {},
              ),
              SettingItem(
                icon: PhosphorIconsRegular.shield,
                title: 'Privacy',
                onTap: () {},
              ),
              SettingItem(
                icon: PhosphorIconsRegular.database,
                title: 'Data Usage',
                onTap: () {},
              ),
              SettingItem(
                icon: PhosphorIconsRegular.question,
                title: 'Help',
                onTap: () {},
              ),
              SettingItem(
                icon: PhosphorIconsRegular.envelope,
                title: 'Invite Your Friends',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.neutral900, size: 24),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppTheme.neutral900),
      ),
      trailing: const Icon(
        PhosphorIconsRegular.caretRight,
        color: AppTheme.neutral500,
        size: 20,
      ),
    );
  }
}
