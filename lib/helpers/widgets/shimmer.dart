import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

Color shimmerColor = Colors.white;
Color containerColor = Colors.grey[400]!;

Widget chatRoomsShimmer() {
  return ListView.separated(
    itemCount: 15,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    separatorBuilder: (BuildContext context, int index) {
      return const SizedBox(
          // height: 8,
          );
    },
    itemBuilder: (BuildContext context, int index) {
      return lastMessageShimmer();
    },
  );
}

Widget lastMessageShimmer() {
  return Container(
    padding: const EdgeInsets.all(8),
    margin: const EdgeInsets.only(left: 5),
    child: Row(
      children: [
        // image
        Shimmer(
          color: shimmerColor,
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(color: containerColor, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        SizedBox(
          height: 70,
          width: 260,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // username
              Shimmer(
                color: shimmerColor,
                child: Container(
                  height: 20,
                  width: 100,
                  color: containerColor,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              // message
              Shimmer(
                color: shimmerColor,
                child: Container(
                  height: 20,
                  width: 250,
                  color: containerColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}