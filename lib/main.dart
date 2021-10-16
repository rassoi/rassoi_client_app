import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

import 'mean_name_state.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Recipe Entry'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final _formKey = GlobalKey<FormState>();

  final mealNameEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MealNameState>(
      create: (context) {
        return MealNameState();
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              Center(
                child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            int b = 0;
                          }
                        },
                        child: const Text("Submit"))),
              )
            ],
          ),
          body: Container(
            padding: const EdgeInsets.all(10),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Consumer<MealNameState>(builder: (context, mealNameState, _) {
                    return TypeAheadFormField(
                      textFieldConfiguration: TextFieldConfiguration(
                        decoration: const InputDecoration(
                          labelText: "Meal Name",
                          border: OutlineInputBorder(),
                        ),
                        controller: mealNameEditingController,
                      ),
                      //  onSuggestionSelected: onSuggestionSelected,
                      itemBuilder: (BuildContext context, String itemData) {
                        if (itemData == null) {
                          return const CircularProgressIndicator();
                        }
                        return Text(itemData);
                      },
                      suggestionsCallback: (pattern) {
                        return mealNameState.getMealSuggestion(pattern);
                      },
                      onSuggestionSelected: (suggestion) {},
                      validator: (meanName) {
                        if (!mealNameState.isMeanNameValid(meanName)) {
                          return "Meal name not valid";
                        }
                      },
                    );
                  }),
                  TextFormField(
                      decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                          errorStyle: TextStyle(
                            color: Colors.red,
                          )),
                      validator: (value) {
                        return "Not a unique value";
                      }),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Img: /img/recepies",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  ElevatedButton(
                    child: const Text("Upload Image of recepie"),
                    onPressed: () {},
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Ingredient",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  ElevatedButton(
                    child: const Text("Add Ingredient"),
                    onPressed: () {},
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Reference",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  ElevatedButton(
                    child: const Text("Upload Image of Ingrediants"),
                    onPressed: () => 7,
                  ),
                ],
              ),
            ),
          )),
    );
  }
}













/*                Autocomplete<Continent>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return continentOptions.where((Continent continent) {
                        return continent.name
                            .toLowerCase()
                            .startsWith(textEditingValue.text.toLowerCase());
                      }).toList();
                    },
                  ),*/
/*TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Meal name",
                    ),
                  )*/
/*                Autocomplete(optionsBuilder: (textEditingValue) {

                  }),*/
/*   const Autocomplete({
                    Key? key,
                    required AutocompleteOptionsBuilder<T> optionsBuilder,
                    AutocompleteOptionToString<T> displayStringForOption = RawAutocomplete.defaultStringForOption,
                    AutocompleteFieldViewBuilder fieldViewBuilder = _defaultFieldViewBuilder,
                    AutocompleteOnSelected<T>? onSelected,
                    AutocompleteOptionsBuilder<T>? optionsViewBuilder,
                  }),*/
