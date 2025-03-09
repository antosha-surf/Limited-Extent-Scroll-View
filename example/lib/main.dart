import 'dart:math';

import 'package:flutter/material.dart';
import 'package:limited_extent_scroll_view/limited_extent_scroll_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final r = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              constraints: BoxConstraints(maxHeight: 400),
              builder: (ctx) {
                return MyBottomSheet();
              },
            );
          },
          child: Text('Open Bottom Sheet'),
        ),
      ),
    );
  }
}

class MyBottomSheet extends StatefulWidget {
  const MyBottomSheet({super.key});

  @override
  State<MyBottomSheet> createState() => _MyBottomSheetState();
}

class _MyBottomSheetState extends State<MyBottomSheet> {
  final gk = GlobalKey();

  final items = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  double? _height;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _height = gk.currentContext?.size?.height;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          color: Colors.amber[600],
          child: const Center(child: Text('Header')),
        ),
        if (_height == null)
          Expanded(child: Center(key: gk, child: SizedBox.expand()))
        else
          LimitedExtentScrollView(
            maxExtent: _height!,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  return Dismissible(
                    background: Container(color: Colors.green),
                    key: ValueKey<int>(items[index]),
                    onDismissed: (DismissDirection direction) {
                      setState(() {
                        items.removeAt(index);
                      });
                    },
                    child: ListTile(title: Text('Item ${items[index]}')),
                  );
                }, childCount: items.length),
              ),
            ],
          ),
        Container(
          height: 50,
          color: Colors.amber[500],
          child: const Center(child: Text('Footer')),
        ),
      ],
    );
  }
}

class HeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.amber[600],
      child: const Center(child: Text('Header')),
    );
  }

  @override
  double get maxExtent => 150;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
