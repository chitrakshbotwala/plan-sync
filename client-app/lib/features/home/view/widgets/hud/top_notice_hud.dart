import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:plan_sync/features/home/viewmodel/home_view_model.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:plan_sync/features/home/view/widgets/hud/notice_carousel_widget.dart';
import 'package:plan_sync/features/home/view/widgets/version_check.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TopNoticeHud extends StatefulWidget {
  const TopNoticeHud({super.key});

  @override
  State<TopNoticeHud> createState() => _TopNoticeHudState();
}

class _TopNoticeHudState extends State<TopNoticeHud> {
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Consumer2<VersionViewModel, HomeViewModel>(
      builder: (context, version, home, _) {
        List<Widget> widgets = [
          if (version.isUpdateAvailable) const VersionCheckWidget(),
          ...home.notices.map(
            (notice) => NoticeCarouselWidget(
              notice: notice,
              onDelete: () => home.dismissNotice(notice.id),
            ),
          ),
        ];

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            Animation<Offset> tween = Tween<Offset>(
              begin: const Offset(-1.0, 0),
              end: const Offset(0.0, 0),
            ).animate(animation);
            return SlideTransition(
              position: tween,
              child: child,
            );
          },
          child: widgets.isEmpty
              ? const SizedBox()
              : Column(
                  children: [
                    ExpandablePageView(
                      controller: pageController,
                      children: widgets,
                    ),
                    if (widgets.length > 1) ...[
                      const SizedBox(height: 8),
                      SmoothPageIndicator(
                        controller: pageController,
                        count: widgets.length,
                        effect: WormEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          activeDotColor: colorScheme.secondary,
                          dotColor: colorScheme.onSurface.withOpacity(0.48),
                          paintStyle: PaintingStyle.stroke,
                        ),
                        onDotClicked: (index) {
                          pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ],
                    SizedBox(height: widgets.length > 1 ? 8 : 12),
                  ],
                ),
        );
      },
    );
  }
}
