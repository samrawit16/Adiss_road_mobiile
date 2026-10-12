import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/images/adiss.png',
      'location': 'Addis Ababa',
      'title': 'Know the road.\nBeat the risk.',
      'description':
          'See dangerous areas before you reach them with real road safety data from Addis Ababa.',
    },
    {
      'image': 'assets/images/road.png',
      'location': 'Addis Ababa',
      'title': 'See danger\nbefore you get there.',
      'description':
          'Discover high-risk roads and accident hotspots so you can stay alert and make safer decisions.',
    },
    {
      'image': 'assets/images/hero_addis.png',
      'location': 'Addis Ababa',
      'title': 'Report fast.\nHelp keep roads safe.',
      'description':
          'Report accidents and road hazards in seconds and help make Addis Ababa safer for everyone.',
    },
  ];

  final Color overlayNavy = const Color(0xFF173B82);
  final Color amber = const Color(0xFFFFB900);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_page == _pages.length - 1) {
      context.go('/register');
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() {
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: _pages.length,
        onPageChanged: (index) {
          setState(() {
            _page = index;
          });
        },
        itemBuilder: (context, index) {
          final page = _pages[index];

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                page['image'],
                fit: BoxFit.cover,
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      overlayNavy.withOpacity(0.32),
                      overlayNavy.withOpacity(0.18),
                      overlayNavy.withOpacity(0.25),
                      overlayNavy.withOpacity(0.72),
                      overlayNavy.withOpacity(0.94),
                    ],
                    stops: const [
                      0.0,
                      0.25,
                      0.48,
                      0.72,
                      1.0,
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 42,
                            height: 42,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 9),
                          const Text(
                            'AAGuardian',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _skip,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.22),
                                ),
                              ),
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 23,
                                height: 23,
                                decoration: BoxDecoration(
                                  color: amber,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: overlayNavy,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                page['location'],
                                style: TextStyle(
                                  color: overlayNavy,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          page['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 37,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          page['description'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          ...List.generate(
                            _pages.length,
                            (i) {
                              final selected = i == _page;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: selected ? 30 : 8,
                                height: 7,
                                margin: const EdgeInsets.only(right: 7),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? amber
                                      : Colors.white.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: amber,
                            foregroundColor: overlayNavy,
                            elevation: 2,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _page == _pages.length - 1
                                    ? 'Get Started'
                                    : 'Continue',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 13),

                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Log In',
                                  style: TextStyle(
                                    color: amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}