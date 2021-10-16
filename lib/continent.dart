import 'package:flutter/material.dart';

class Continent {

  const Continent({
    required this.name,
    required this.size,
  });

  final String name;
  final int size;

  @override
  String toString() {
    return '$name ($size)';
  }
}

const List<Continent> continentOptions = <Continent>[
Continent(name: 'Africa', size: 30370000),
Continent(name: 'Antarctica', size: 14000000),
Continent(name: 'Asia', size: 44579000),
Continent(name: 'Australia', size: 8600000),
Continent(name: 'Europe', size: 10180000),
Continent(name: 'North America', size: 24709000),
Continent(name: 'South America', size: 17840000),
];