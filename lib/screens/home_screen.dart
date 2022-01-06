import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const String routeName = '/home';

  static Route route() {
    return MaterialPageRoute<HomeScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (context) => const HomeScreen(),
    );
  }

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final refreshControllerTop = RefreshController();
  final refreshControllerNew = RefreshController();
  final refreshControllerAsk = RefreshController();
  final refreshControllerShow = RefreshController();
  final refreshControllerJobs = RefreshController();
  late final TabController tabController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // This is for testing only.
    // FeatureDiscovery.clearPreferences(context, [
    //   Constants.featureLogIn,
    //   Constants.featureAddStoryToFavList,
    //   Constants.featureOpenStoryInWebView,
    // ]);

    SchedulerBinding.instance?.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(
        context,
        const <String>{
          Constants.featureLogIn,
        },
      );
    });

    tabController = TabController(vsync: this, length: 6)
      ..addListener(() {
        setState(() {
          currentIndex = tabController.index;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    final cacheService = locator.get<CacheService>();

    return BlocBuilder<PreferenceCubit, PreferenceState>(
      builder: (context, preferenceState) {
        return BlocConsumer<StoriesBloc, StoriesState>(
          listener: (context, state) {
            if (state.statusByType[StoryType.top] == StoriesStatus.loaded) {
              refreshControllerTop
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
            if (state.statusByType[StoryType.latest] == StoriesStatus.loaded) {
              refreshControllerNew
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
            if (state.statusByType[StoryType.ask] == StoriesStatus.loaded) {
              refreshControllerAsk
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
            if (state.statusByType[StoryType.show] == StoriesStatus.loaded) {
              refreshControllerShow
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
            if (state.statusByType[StoryType.jobs] == StoriesStatus.loaded) {
              refreshControllerJobs
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
          },
          builder: (context, state) {
            return WillPopScope(
              onWillPop: () => Future.value(false),
              child: DefaultTabController(
                length: 6,
                child: Scaffold(
                  appBar: PreferredSize(
                    preferredSize: const Size(0, 48),
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).padding.top,
                        ),
                        TabBar(
                          isScrollable: true,
                          controller: tabController,
                          indicatorColor: Colors.orange,
                          tabs: [
                            Tab(
                              child: Text(
                                'TOP',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: currentIndex == 0
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: currentIndex == 1
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'ASK',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: currentIndex == 2
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'SHOW',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: currentIndex == 3
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'JOBS',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: currentIndex == 4
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Tab(
                              icon: DescribedFeatureOverlay(
                                targetColor: Theme.of(context).primaryColor,
                                tapTarget: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                featureId: Constants.featureLogIn,
                                title: const Text(''),
                                description: const Text(
                                  'Log in using your Hacker News account '
                                  'to check out stories and comments you have '
                                  'posted in the past.',
                                  style: TextStyle(fontSize: 16),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: currentIndex == 5
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    controller: tabController,
                    children: [
                      ItemsListView<Story>(
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerTop,
                        items: state.storiesByType[StoryType.top]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.top));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.top));
                        },
                        onTap: (story) {
                          HackiApp.navigatorKey.currentState!.pushNamed(
                              StoryScreen.routeName,
                              arguments: StoryScreenArgs(story: story));

                          if (preferenceState.showWebFirst &&
                              cacheService.isFirstTimeReading(story.id)) {
                            LinkUtil.launchUrl(story.url);
                            cacheService.store(story.id);
                          }
                        },
                      ),
                      ItemsListView<Story>(
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerNew,
                        items: state.storiesByType[StoryType.latest]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.latest));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.latest));
                        },
                        onTap: (story) {
                          HackiApp.navigatorKey.currentState!.pushNamed(
                              StoryScreen.routeName,
                              arguments: StoryScreenArgs(story: story));

                          if (preferenceState.showWebFirst &&
                              cacheService.isFirstTimeReading(story.id)) {
                            LinkUtil.launchUrl(story.url);
                            cacheService.store(story.id);
                          }
                        },
                      ),
                      ItemsListView<Story>(
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerAsk,
                        items: state.storiesByType[StoryType.ask]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.ask));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.ask));
                        },
                        onTap: (story) {
                          HackiApp.navigatorKey.currentState!.pushNamed(
                              StoryScreen.routeName,
                              arguments: StoryScreenArgs(story: story));

                          if (preferenceState.showWebFirst &&
                              cacheService.isFirstTimeReading(story.id)) {
                            LinkUtil.launchUrl(story.url);
                            cacheService.store(story.id);
                          }
                        },
                      ),
                      ItemsListView<Story>(
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerShow,
                        items: state.storiesByType[StoryType.show]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.show));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.show));
                        },
                        onTap: (story) {
                          HackiApp.navigatorKey.currentState!.pushNamed(
                              StoryScreen.routeName,
                              arguments: StoryScreenArgs(story: story));

                          if (preferenceState.showWebFirst &&
                              cacheService.isFirstTimeReading(story.id)) {
                            LinkUtil.launchUrl(story.url);
                            cacheService.store(story.id);
                          }
                        },
                      ),
                      ItemsListView<Story>(
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerJobs,
                        items: state.storiesByType[StoryType.jobs]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.jobs));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.jobs));
                        },
                        onTap: (story) => LinkUtil.launchUrl(story.url),
                      ),
                      const ProfileView(),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}