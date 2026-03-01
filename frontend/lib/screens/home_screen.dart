import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/topics_provider.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topicsProvider = Provider.of<TopicsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final allTopics = topicsProvider.topics;
    final queue = topicsProvider.todaysRevisionQueue;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SmartRev'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(Icons.person, color: theme.primaryColor),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        color: theme.primaryColor,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CHANGE 1 – Dynamic greeting (no streak)
                _buildGreetingSection(theme, authProvider),
                const SizedBox(height: 32),
                
                // CHANGE 5 – Show ALL topics in Today's Queue
                if (queue.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Queue",
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${queue.length} Pending',
                          style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Show ALL queue items, not just the first one
                  ...queue.map((topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildQueueCard(topic, theme),
                  )),
                  const SizedBox(height: 20),
                ],
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your Topics",
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/upload-notes');
                      },
                      icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      label: const Text('AI Quiz', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (allTopics.isEmpty)
                  _buildEmptyState(theme)
                else
                  _buildTopicsGrid(allTopics, theme),
                  
                const SizedBox(height: 80), // Padding for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-topic');
        },
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
             Navigator.pushNamed(context, '/analytics');
             setState(() => _currentIndex = 0);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined), label: 'Analytics'),
        ],
      ),
    );
  }

  /// CHANGE 1 – Dynamic greeting, CHANGE 2 – Streak removed
  Widget _buildGreetingSection(ThemeData theme, AuthProvider authProvider) {
    // Dynamic username: logged in → username, else → "User"
    final displayName = authProvider.isAuthenticated ? authProvider.username : 'User';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Greetings,',
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          displayName,
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
        ),
      ],
    );
  }

  /// Queue card – navigates to flashcard revision or quiz revision depending on content.
  Widget _buildQueueCard(Topic topic, ThemeData theme) {
    return InkWell(
      onTap: () {
        // Navigate to flashcard revision if flashcards exist, otherwise quiz
        if (topic.flashcards.isNotEmpty) {
          Navigator.pushNamed(context, '/flashcard-revision', arguments: {
            'topicId': topic.id,
          });
        } else if (topic.quiz != null) {
          Navigator.pushNamed(context, '/revision', arguments: {
            'topicId': topic.id,
            'quiz': topic.quiz,
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Urgent',
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topic.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.subject,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsGrid(List<Topic> topics, ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3.5,
      ),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        final strength = topic.memoryStrength;
        
        Color strengthColor;
        String statusText;
        if (strength <= 40) {
          strengthColor = const Color(0xFFEF4444); // Weak
          statusText = 'Weak';
        } else if (strength <= 70) {
          strengthColor = const Color(0xFFF59E0B); // Moderate
          statusText = 'Moderate';
        } else {
          strengthColor = const Color(0xFF10B981); // Strong
          statusText = 'Strong';
        }

        return InkWell(
          onTap: () {
            // Navigate to flashcard revision if flashcards exist, otherwise quiz
            if (topic.flashcards.isNotEmpty) {
              Navigator.pushNamed(context, '/flashcard-revision', arguments: {
                'topicId': topic.id,
              });
            } else if (topic.quiz != null) {
              Navigator.pushNamed(context, '/revision', arguments: {
                'topicId': topic.id,
                'quiz': topic.quiz,
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(color: strengthColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(color: strengthColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (topic.isAiGenerated)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Text(
                      topic.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: strength / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: strengthColor,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revise: ${topic.nextRevisionDate}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.library_books, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No topics yet',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your smart revision journey by adding your first topic!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
