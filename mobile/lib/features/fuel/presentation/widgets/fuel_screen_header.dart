import 'package:flutter/material.dart';



import '../fuel_palette.dart';



class FuelScreenHeader extends StatelessWidget {

  const FuelScreenHeader({super.key});



  @override

  Widget build(BuildContext context) {

    return const Padding(

      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),

      child: Align(

        alignment: Alignment.centerLeft,

        child: Text(

          'Nhiên liệu',

          style: TextStyle(

            fontSize: 26,

            fontWeight: FontWeight.w900,

            color: FuelPalette.textPrimary,

            letterSpacing: -0.4,

          ),

        ),

      ),

    );

  }

}

