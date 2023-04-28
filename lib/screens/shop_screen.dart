import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/models/profile.dart';
import 'package:fplwordle/providers/profile_provider.dart';
import '../helpers/utils/color_palette.dart';
import '../helpers/widgets/leading_button.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Profile? profile = context.select<ProfileProvider, Profile?>((provider) => provider.profile);
    List<ShopItem> shopItems = [
      ShopItem(
          title: "Starter Pack", description: "Get 50 coins", image: "assets/shop/coins.png", price: 1, onTap: () {}),
      ShopItem(
          title: "Bag of Coins",
          description: "Get 500 coins and 1 month free of ads",
          image: "assets/shop/sack-of-coins.gif",
          price: 5,
          onTap: () {}),
      ShopItem(
          title: "Treasure Chest",
          description: "Get 2000 coins and 1 year free of ads",
          image: "assets/shop/chest-of-coins.gif",
          price: 10,
          onTap: () {}),
      ShopItem(
          title: "Goodbye Ads (Monthly Package)",
          description: "Subscribe to remove ads for a month",
          image: "assets/shop/no-ads.gif",
          price: 0.5,
          onTap: () {}),
      ShopItem(
          title: "Goodbye Ads (Yearly Package)",
          description: "Subscribe to remove ads for a year",
          image: "assets/shop/no-ads.gif",
          price: 4,
          onTap: () {}),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leadingButton(context),
        centerTitle: true,
        title: headingText(text: "SHOP"),
        actions: [
          // coins button
          Container(
            margin: const EdgeInsets.all(8),
            child: AnimatedNeumorphicContainer(
                depth: 0,
                color: Palette.primary,
                height: 40,
                radius: 25.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/coin.png', height: 25, width: 25),
                      const SizedBox(width: 8),
                      bodyText(text: profile!.coins.toString(), color: Colors.white, fontSize: 20, bold: true),
                    ],
                  ),
                )),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // shop items
                  ...shopItems
                      .map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 20), child: _buildShopItem(context, item, true)))
                      .toList(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // shop items 1-3
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...shopItems
                        .sublist(0, 3)
                        .map((item) => Container(
                            margin: const EdgeInsets.only(right: 20), child: _buildShopItem(context, item, false)))
                        .toList(),
                  ],
                ),
                const SizedBox(height: 30),
                // shop items 4-5
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...shopItems
                        .sublist(3, 5)
                        .map((item) => Container(
                            margin: const EdgeInsets.only(right: 20), child: _buildShopItem(context, item, false)))
                        .toList(),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildShopItem(BuildContext context, ShopItem item, bool isMobile) {
    return InkWell(
      onTap: item.onTap(),
      child: AnimatedNeumorphicContainer(
          depth: 0,
          color: Palette.primary,
          width: !isMobile ? 400 : MediaQuery.of(context).size.width - 80,
          radius: 25.0,
          child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  Center(
                    child: headingText(
                      text: item.title,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // image
                      Container(
                        alignment: Alignment.center,
                        height: 70,
                        width: 70,
                        margin: const EdgeInsets.only(right: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          image: DecorationImage(
                            image: AssetImage(item.image),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            // description
                            Align(
                              alignment: Alignment.centerLeft,
                              child: bodyText(text: item.description, fontSize: 15, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            // price
                            Align(
                              alignment: Alignment.centerLeft,
                              child: bodyText(text: "\$${item.price.toString()}", fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ))),
    );
  }
}

class ShopItem {
  String title, description, image;
  double price;
  final Function onTap;

  ShopItem({
    required this.title,
    required this.description,
    required this.image,
    required this.price,
    required this.onTap,
  });
}
