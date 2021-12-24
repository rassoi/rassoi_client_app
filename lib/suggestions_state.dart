import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SuggestionsState extends ChangeNotifier {
  List<String> allMealNames = [];
  List<String> allIngredientsNames = [];
  FutureOr<Iterable<String>> mealNamesFuture = List.empty();
  FutureOr<Iterable<String>> ingredientsNamesFuture = List.empty();

  SuggestionsState() {
    init();
  }

  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    List<String> mealNames = [];
    List<String> ingredientsNames = [];
    mealNamesFuture = await FirebaseFirestore.instance
        .collection("/recipes")
        .get()
        .then<List<String>>((collection) {
      for (var doc in collection.docs) {
        mealNames.add(doc.id);
      }
      allMealNames.addAll(mealNames);
      allMealNames.sort((a, b) =>
          a.toUpperCase().toString().compareTo(b.toUpperCase().toString()));
      return mealNames;
    });

    ingredientsNamesFuture = await FirebaseFirestore.instance
        .collection("/ingredients")
        .get()
        .then<List<String>>((collection) {
      for (var doc in collection.docs) {
        ingredientsNames.add(doc.id);
      }
      allIngredientsNames.addAll(ingredientsNames);
      allIngredientsNames.sort((a, b) =>
          a.toUpperCase().toString().compareTo(b.toUpperCase().toString()));
      return ingredientsNames;
    });
  }

  bool isMeanNameValid(String? mealName) {
    return mealName!.isNotEmpty &&
        !allMealNames
            .map((mealName) => mealName.toUpperCase())
            .contains(mealName.toUpperCase());
  }

  bool isIngredientNameFromList(String ingredientName) {
    for (var element in allIngredientsNames) {
      if (element.toUpperCase() == ingredientName.toUpperCase()) {
        return true;
      }
    }
    return false;
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

  FutureOr<Iterable<String>> getIngredientsSuggestion(String? queryIngredientName) {
    if (allIngredientsNames.isEmpty) {
      return ingredientsNamesFuture;
    } else if (queryIngredientName == null || queryIngredientName.isEmpty) {
      return allIngredientsNames;
    } else {
      List<String> list = [];
      for (var ingredientName in allIngredientsNames) {
        if (ingredientName.toUpperCase().contains(queryIngredientName.toUpperCase())) {
          list.add(ingredientName);
        }
      }
      return list;
    }
  }
}
