enum Menu { chats, stories }

enum Filters {
  all('All'),
  unread('Unread'),
  read('Read'),
  groups('Groups'),
  contacts('Contacts');

  final String label;
  const Filters(this.label);
}

enum Status { sending, sent, delivered, read }
