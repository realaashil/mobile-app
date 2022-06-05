import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_app/ib_theme.dart';
import 'package:mobile_app/models/ib/ib_chapter.dart';
import 'package:mobile_app/ui/components/cv_drawer_tile.dart';
import 'package:mobile_app/ui/views/base_view.dart';
import 'package:mobile_app/ui/views/ib/ib_page_view.dart';
import 'package:mobile_app/viewmodels/ib/ib_landing_viewmodel.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:theme_provider/theme_provider.dart';

class IbLandingView extends StatefulWidget {
  const IbLandingView({Key? key}) : super(key: key);

  static const String id = 'ib_landing_view';

  @override
  _IbLandingViewState createState() => _IbLandingViewState();
}

class _IbLandingViewState extends State<IbLandingView> {
  final IbChapter _homeChapter = IbChapter(
    id: 'index.md',
    navOrder: '1',
    value: 'Interactive Book Home',
  );
  late IbChapter _selectedChapter;
  late ValueNotifier<Function?> _tocNotifier;
  late IbLandingViewModel _model;

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  void initState() {
    _tocNotifier = ValueNotifier(null);
    _selectedChapter = _homeChapter;
    super.initState();
  }

  @override
  void dispose() {
    _tocNotifier.dispose();
    super.dispose();
  }

  void setSelectedChapter(IbChapter chapter) {
    Get.back();
    if (_selectedChapter.id != chapter.id) {
      setState(() => _selectedChapter = chapter);
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: () {
          if (!_model.showCaseState.drawerButton) {
            _model.onShowCased('drawer');
          }
          _key.currentState?.openDrawer();
        },
        icon: Showcase(
          key: _model.drawer,
          description: 'Navigate to different chapters',
          overlayPadding: const EdgeInsets.all(12.0),
          onTargetClick: () {
            _model.onShowCased('drawer');
            _key.currentState?.openDrawer();
          },
          disposeOnTap: true,
          child: const Icon(Icons.menu),
        ),
      ),
      title: Text(
        _selectedChapter.id == _homeChapter.id
            ? 'CircuitVerse'
            : 'Interactive Book',
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: _tocNotifier,
          builder: (context, value, child) {
            return value != null
                ? Showcase(
                    key: _model.toc,
                    description: 'Show Table of Contents',
                    onTargetClick: () {
                      _model.onShowCased('toc');
                      if (_key.currentState!.isDrawerOpen) Get.back();
                      Future.delayed(
                        const Duration(milliseconds: 200),
                        value as VoidCallback,
                      );
                    },
                    disposeOnTap: true,
                    child: IconButton(
                      icon: const Icon(Icons.menu_book_rounded),
                      onPressed: value as VoidCallback,
                    ),
                  )
                : Container();
          },
        ),
      ],
      centerTitle: true,
    );
  }

  Widget _buildChapter(IbChapter chapter) {
    return InkWell(
      onTap: () => setSelectedChapter(chapter),
      child: CVDrawerTile(
        title: chapter.value,
        color: (_selectedChapter.id == chapter.id)
            ? IbTheme.getPrimaryColor(context)
            : IbTheme.textColor(context),
      ),
    );
  }

  Widget _buildExpandableChapter(IbChapter chapter) {
    var nestedPages = <Widget>[];

    var hasSelectedChapter = false;
    for (var nestedChapter in chapter.items ?? <IbChapter>[]) {
      if (nestedChapter.id == _selectedChapter.id) {
        hasSelectedChapter = true;
      }

      nestedPages.add(_buildChapter(nestedChapter));
    }

    return ExpansionTile(
      maintainState: true,
      initiallyExpanded:
          (_selectedChapter.id.startsWith(chapter.id) || hasSelectedChapter)
              ? true
              : false,
      title: ListTile(
        contentPadding: const EdgeInsets.all(0),
        title: GestureDetector(
          onTap: () => setSelectedChapter(chapter),
          child: Text(
            chapter.value,
            style: Theme.of(context).textTheme.headline6?.copyWith(
                  fontFamily: 'Poppins',
                  color: (_selectedChapter.id.startsWith(chapter.id))
                      ? IbTheme.getPrimaryColor(context)
                      : IbTheme.textColor(context),
                ),
          ),
        ),
      ),
      children: nestedPages,
    );
  }

  Widget _buildChapters(List<IbChapter> chapters) {
    var _chapters = <Widget>[];

    for (var chapter in chapters) {
      if (chapter.items != null && chapter.items!.isNotEmpty) {
        _chapters.add(_buildExpandableChapter(chapter));
      } else {
        _chapters.add(_buildChapter(chapter));
      }
    }

    return Column(children: _chapters);
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Stack(
        children: [
          ListView(
            children: <Widget>[
              InkWell(
                onTap: () {
                  Get.back();
                  Get.back();
                },
                child: CVDrawerTile(
                  title: 'Return to Home',
                  color: IbTheme.textColor(context),
                ),
              ),
              const Divider(thickness: 1),
              InkWell(
                onTap: () => setSelectedChapter(_homeChapter),
                child: CVDrawerTile(
                  title: 'Interactive Book Home',
                  color: (_selectedChapter.id == _homeChapter.id)
                      ? IbTheme.getPrimaryColor(context)
                      : IbTheme.textColor(context),
                ),
              ),
              if (!_model.isSuccess(_model.IB_FETCH_CHAPTERS))
                const InkWell(
                  child: CVDrawerTile(
                    title: 'Loading...',
                  ),
                )
              else
                _buildChapters(_model.chapters),
            ],
          ),
          Positioned(
            right: 5,
            top: 27,
            child: IconButton(
              icon: Theme.of(context).brightness == Brightness.dark
                  ? const Icon(Icons.brightness_low)
                  : const Icon(Icons.brightness_high),
              iconSize: 28.0,
              onPressed: () {
                ThemeProvider.controllerOf(context).nextTheme();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<IbLandingViewModel>(
      onModelReady: (model) {
        _model = model;
        model.init();
      },
      builder: (context, model, child) {
        // Set next page for home page
        if (model.isSuccess(model.IB_FETCH_CHAPTERS) &&
            _homeChapter.next == null) {
          _homeChapter.nextPage = model.chapters[0];
          model.chapters[0].prev = _homeChapter;
        }

        return WillPopScope(
          onWillPop: () {
            if (_selectedChapter != _homeChapter) {
              setState(() => _selectedChapter = _homeChapter);
              return Future.value(false);
            }
            _model.saveShowcaseState();
            return Future.value(true);
          },
          child: Theme(
            data: IbTheme.getThemeData(context),
            child: ShowCaseWidget(
              onComplete: (index, globalKey) {
                final String key = globalKey
                    .toString()
                    .substring(1, globalKey.toString().length - 1)
                    .split(" ")
                    .last;
                model.onShowCased(key);
              },
              builder: Builder(builder: (context) {
                return Scaffold(
                  key: _key,
                  appBar: _buildAppBar(),
                  drawer: _buildDrawer(),
                  body: PageTransitionSwitcher(
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                    ) {
                      return FadeThroughTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        child: child,
                      );
                    },
                    child: IbPageView(
                      key: Key(_selectedChapter.toString()),
                      tocCallback: (val) {
                        Future.delayed(Duration.zero, () async {
                          if (mounted) {
                            _tocNotifier.value = val;
                          }
                        });
                      },
                      setPage: (chapter) {
                        if (chapter == null) return;
                        setState(() => _selectedChapter = chapter);
                      },
                      chapter: _selectedChapter,
                      setShowCase: (updatedState) {
                        model.showCaseState = updatedState;
                      },
                      showCase: model.showCaseState,
                      globalKeysMap: model.keyMap,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
