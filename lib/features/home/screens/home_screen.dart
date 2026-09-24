import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../../core/database/tables.dart' show BookStatus;
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/content_column.dart';
import '../../library/models/week_stats.dart';
import '../../library/state/book_repository.dart';
import '../../library/widgets/add_book_sheet.dart';
import '../../library/widgets/empty_shelf_card.dart';
import '../widgets/also_reading_list.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/home_shortcut_tip.dart';
import '../widgets/week_card.dart';

/// Home screen, the center of the strip. A time aware greeting, the book being
/// read right now, this week, and any other books in progress. With no books
/// yet it invites the reader to add the first one.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _navClearance = 112;

  final Stream<List<Book>> _books = BookRepository.instance.watchAll();
  final Stream<WeekStats> _week = BookRepository.instance.watchThisWeek();

  String _greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Ready for a new chapter?';
    if (hour >= 12 && hour < 17) return 'A page or two before it gets busy?';
    if (hour >= 17 && hour < 21) return 'Golden hour, good for reading.';
    return "It's past your bedtime... one more chapter?";
  }

  List<Widget> _content(
    BuildContext context,
    AsyncSnapshot<List<Book>> snapshot,
    List<Book> books,
  ) {
    if (snapshot.hasError) {
      return const <Widget>[Text('Could not load your books.')];
    }
    if (!snapshot.hasData) return const <Widget>[];

    if (books.isEmpty) {
      return <Widget>[
        EmptyShelfCard(onAdd: () => showAddBookSheet(context)),
      ];
    }

    final reading =
        books.where((book) => book.status == BookStatus.reading).toList();
    final others = reading.skip(1).take(5).toList();

    return <Widget>[
      if (reading.isEmpty)
        const NothingInProgressCard()
      else
        ContinueReadingCard(book: reading.first),
      const SizedBox(height: 28),
      WeekCard(stream: _week),
      if (others.isNotEmpty) ...[
        const SizedBox(height: 28),
        AlsoReadingList(books: others),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SafeArea(
            child: ContentColumn(
              child: StreamBuilder<List<Book>>(
                stream: _books,
                builder: (context, snapshot) {
                  final books = snapshot.data ?? const <Book>[];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, _navClearance),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: Semantics(
                          header: true,
                          child: Text(
                            _greeting(DateTime.now().hour),
                            style: AppFonts.serifStyle(
                              size: 30,
                              height: 1.27,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ..._content(context, snapshot, books),
                    ],
                  );
                },
              ),
            ),
          ),
          const Positioned.fill(child: HomeShortcutTip()),
        ],
      ),
    );
  }
}
