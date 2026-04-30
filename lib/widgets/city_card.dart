//顯示城市的卡片
import 'package:flutter/material.dart';
import '../models/city.dart';

class CityCard extends StatelessWidget {
  final double cityTextFontSize = 24;
  final double subTitleTextFontSize = 16;
  static const String _fallbackImageUrl =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQs9gUXKwt2KErC_jWWlkZkGabxpeGchT-fyw&s';
  const CityCard({super.key, required this.city, required this.onSelect});

  final CityLevel city;
  //valueChanged是一種call back function 回傳選擇的城市給父 widget(也就是CitySelectionPage)
  final ValueChanged<CityLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onSelect(city),
        child: SizedBox(
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                city.backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Image.network(_fallbackImageUrl, fit: BoxFit.cover);
                },
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      city.name,
                      style: TextStyle(
                        fontSize: cityTextFontSize,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '入場費: ${city.entryFee}',
                      style: TextStyle(
                        fontSize: subTitleTextFontSize,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 12,
                top: 12,
                child: Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
