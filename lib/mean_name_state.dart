import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';

class MealNameState extends ChangeNotifier {
  List<String> allMealNames = [];
  FutureOr<Iterable<String>> mealNamesFuture = List.empty();

  MealNameState() {
    init();
  }

  Future<void> init() async {
    await Firebase.initializeApp();
    // mealNamesFuture =
    mealNamesFuture = FirebaseFirestore.instance
        .collection("/recipes")
        .get()
        .then<List<String>>((collection) {
      List<String> mealNames = [];
      for (var doc in collection.docs) {
        mealNames.add(doc.id);
      }
      allMealNames.addAll(mealNames);
      allMealNames.sort((a, b) => a.toUpperCase().toString().compareTo(b.toUpperCase().toString()));
      return mealNames;
    });
/*        .snapshots()
        .map((event) => null).get()*/
    /*listen((event) {
          QuerySnapshot<Map<String, dynamic>>  g = event;
          for (var doc in g.docs) {
            doc.id;
          }*/
  }

/*    var future = mealNamesFuture as Future<List<String>>;
    future.then((value) {
      allMealNames.addAll(value);
      return value;
    });*/

  bool isMeanNameValid(String? mealName) {
    return allMealNames.contains(mealName);
  }

  FutureOr<Iterable<String>> getMealSuggestion(String? queryMealName) {
    if (allMealNames.isEmpty) {
      return mealNamesFuture;
    } else if (queryMealName == null || queryMealName.isEmpty) {
      return allMealNames;
    } else {
      List<String> list = [];
      for (var mealName in allMealNames) {
        if (mealName.toUpperCase().contains(queryMealName.toUpperCase())) {
          list.add(mealName);
        }
      }
      return list;
    }
  }
}
