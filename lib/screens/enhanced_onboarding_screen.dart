// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'login_screen.dart';

@Deprecated('V1: pantalla legacy fuera del flujo. Usar OnboardingScreen.')
class EnhancedOnboardingScreen extends StatefulWidget {
  static const routeName = '/enhanced_onboarding';
  const EnhancedOnboardingScreen({super.key});

  @override
  State<EnhancedOnboardingScreen> createState() =>
      _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState extends State<EnhancedOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final storage = appSecureStorage;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Te damos la bienvenida a ManejApp',
      description:
          'La mejor app para aprender a manejar con instructores profesionales',
      icon: Icons.drive_eta,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Reserva tus Clases',
      description: 'Elegí tu instructor, fecha y hora. Todo desde tu celular',
      icon: Icons.calendar_today,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Paga de Forma Segura',
      description: 'Integración con MercadoPago para pagos seguros y rápidos',
      icon: Icons.payment,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Comunícate con tu Instructor',
      description: 'Chat en tiempo real para coordinar detalles de tus clases',
      icon: Icons.chat,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Sigue tu Progreso',
      description:
          'Visualiza tus clases, pagos y calificaciones en un solo lugar',
      icon: Icons.trending_up,
      color: AppColors.primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await storage.write(key: 'first_launch_completed', value: 'true');
    if (mounted) {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _EnhancedOnboardingPageContent(
                    key: ValueKey<int>(index),
                    page: page,
                    pageIndex: index,
                    currentPage: _currentPage,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Atrás'),
                    )
                  else
                    const SizedBox(width: 80),
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Siguiente',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusPill),
                        boxShadow: AppSizes.softShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: _completeOnboarding,
                        child: const Text('Comenzar'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surfaceLighter,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _EnhancedOnboardingPageContent extends StatelessWidget {
  final OnboardingPage page;
  final int pageIndex;
  final int currentPage;

  const _EnhancedOnboardingPageContent({
    super.key,
    required this.page,
    required this.pageIndex,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = pageIndex == currentPage;
    return AnimatedOpacity(
      opacity: isActive ? 1 : 0.5,
      duration: const Duration(milliseconds: 250),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isActive ? 1 : 0.6),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: page.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page.icon,
                  size: 100,
                  color: page.color,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              page.title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              page.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
