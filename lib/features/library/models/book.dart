enum BookStatus { reading, done, queued }

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.pagesRead,
    required this.totalPages,
    required this.status,
  });

  final int id;
  final String title;
  final String author;
  final int pagesRead;
  final int totalPages;
  final BookStatus status;

  double get progress =>
      totalPages == 0 ? 0 : (pagesRead / totalPages).clamp(0, 1);
}

// TEMPORARY mock data — remove once Drift + a real Book table exist.
// Not persisted, not wired to storage. Matches the sample set used in the
// Figma design pass so the two stay in sync while iterating.
const mockBooks = <Book>[
  Book(
    id: 1,
    title: 'The Psychology of Money',
    author: 'Morgan Housel',
    pagesRead: 130,
    totalPages: 210,
    status: BookStatus.reading,
  ),
  Book(
    id: 2,
    title: 'Thinking, Fast and Slow',
    author: 'Daniel Kahneman',
    pagesRead: 150,
    totalPages: 440,
    status: BookStatus.reading,
  ),
  Book(
    id: 3,
    title: 'Sapiens',
    author: 'Yuval Noah Harari',
    pagesRead: 350,
    totalPages: 400,
    status: BookStatus.reading,
  ),
  Book(
    id: 4,
    title: 'The Pragmatic Programmer',
    author: 'David Thomas',
    pagesRead: 45,
    totalPages: 300,
    status: BookStatus.reading,
  ),
  Book(
    id: 5,
    title: 'Atomic Habits',
    author: 'James Clear',
    pagesRead: 320,
    totalPages: 320,
    status: BookStatus.done,
  ),
  Book(
    id: 6,
    title: 'Dune',
    author: 'Frank Herbert',
    pagesRead: 0,
    totalPages: 412,
    status: BookStatus.queued,
  ),
];
