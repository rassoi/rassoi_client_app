import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'suggestions_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    _hasNetworkConnection().asStream().listen((isConnectedToNet) {
      if (!isConnectedToNet) {
        _showSnackBar(context, "Not connected to Internet. Restart app",
            secondsDuration: 5);
      }
    });
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Recipe Entry'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  bool showIndicator = false;
  final uniqueMealNameEditingController = TextEditingController();
  final mealNameDescriptionEditingController = TextEditingController();
  final mealNameEditingController = TextEditingController();
  final youTubeLinkEditingController = TextEditingController();

  final List<TextEditingController> ingredientNameControllerList = [];
  final List<Widget> ingredientWidgetsList = [];

  final List<File?> _ingredientImageList = [];
  int latestBucketStart = -1; // 0 index

  File? _recipeImage;

  void submitIngredient(Future<String> future, SuggestionsState suggestionsState,
      BuildContext context, int bucketIndex, int count) async {
    FirebaseStorage _storage = FirebaseStorage.instance;
    int random = Random().nextInt(100000) + 1001;
    Reference storageReference =
        _storage.ref("images/ingredients/" + random.toString());
    File file = File("mages/ingredients/");
    try {
      file = _ingredientImageList[count]!;
    } on Exception {
      return Future.error("get lost");
    }
    future = future
          .then((value) => storageReference.putFile(file).then((downloadUrl) =>
              downloadUrl.ref.getDownloadURL().then((url) =>
                  FirebaseFirestore.instance
                      .collection("/ingredients")
                      .doc(ingredientNameControllerList[bucketIndex].text)
                      .set({
                    'english':
                        ingredientNameControllerList[bucketIndex + 1].text,
                    // John Doe
                    'hindi': ingredientNameControllerList[bucketIndex + 2].text,
                    // Stokes and Sons
                    'img': url,
                    // 42
                  })))).then((value) => "completed 1");
  }

  Future<String> submitForm(
      SuggestionsState suggestionsState, BuildContext context) async {
    bool hasNetworkConnection = await _hasNetworkConnection();
    if (!hasNetworkConnection) {
      return Future.error(false);
    }
    int bucketIndex = 0;
    int count = 0;
    Future<String> future = Future.value("Started");
    while (bucketIndex + 2 <= ingredientNameControllerList.length - 1) {
      if (!suggestionsState.isIngredientNameFromList(
          ingredientNameControllerList[bucketIndex].text)) {
        int bucketPosition = bucketIndex;
        int position = count;
        submitIngredient(future, suggestionsState, context, bucketPosition, position);
      }
      bucketIndex = bucketIndex + 3;
      count++;
    }
    // Upload meal
    var dishNameLowerCase = mealNameEditingController.text.toLowerCase();
    List<String> dishArrayName = [];
    for (int i = 0; i < dishNameLowerCase.length; i++) {
      dishArrayName.add(dishNameLowerCase.substring(0, i + 1));
    }
    FirebaseStorage _storage = FirebaseStorage.instance;
    int random = Random().nextInt(100000) + 1001;
    Reference storageReference =
        _storage.ref("images/recipes/" + random.toString());
    File image = File("dd");
    try {
      image = _recipeImage!;
      future = future.then((value) =>
          storageReference.putFile(image).then(
                  (downloadUrl) =>
                  downloadUrl.ref.getDownloadURL().then((url) =>
                      FirebaseFirestore.instance
                          .collection("/recipes")
                          .doc(uniqueMealNameEditingController.text)
                          .set({
                        "desc": mealNameDescriptionEditingController.text,
                        "img": url,
                        "name": mealNameEditingController.text,
                        "nameAsArray": dishArrayName,
                        "youtube_link": youTubeLinkEditingController.text,
                        "categoryName": suggestionsState.categoriesSelectedList
                      })))).then((value) => "completed 2");
    } on Exception {
    return Future.error("get lost 2");
    }
    // Upload ingredients inside the meal
    bucketIndex = 0;
    while (bucketIndex + 2 <= ingredientNameControllerList.length - 1) {
      int bucketPosition = bucketIndex;
      submitIngredientInsideMeal(future, suggestionsState, context, bucketPosition);
      bucketIndex = bucketIndex + 3;
    }
    return future;
  }

  void submitIngredientInsideMeal(
      Future<String> future,
      SuggestionsState suggestionsState,
      BuildContext context,
      int bucketIndex) {
    future = future.then((value) => FirebaseFirestore.instance
            .collection("/recipes")
            .doc(uniqueMealNameEditingController.text)
            .collection("/ingreds")
            .doc(ingredientNameControllerList[bucketIndex].text)
            .set({
          "reference": ("/ingredients/" +
              ingredientNameControllerList[bucketIndex].text),
        })).then((value) => "completed 3");
  }

  void postSubmit(SuggestionsState suggestionState, bool dataSubmitted) {
    setState(() {
      showIndicator = false;
      if (dataSubmitted) {
        // reset all data
        suggestionState.removeAllSelectedCategories();
        suggestionState.init();
        uniqueMealNameEditingController.text = "";
        mealNameDescriptionEditingController.text = "";
        mealNameEditingController.text = "";
        youTubeLinkEditingController.text = "";
        ingredientNameControllerList.removeRange(
            0, ingredientNameControllerList.length);
        ingredientWidgetsList.removeRange(
            0, ingredientWidgetsList.length);
        _ingredientImageList.removeRange(
            0, _ingredientImageList.length);
        latestBucketStart = -1;
        _recipeImage = null;
        _showSnackBar(
            context, "Form Successfully submitted",
            secondsDuration: 5);
      } else {
        _showSnackBar(
            context, "Network error occurred.",
            secondsDuration: 5);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SuggestionsState>(
      create: (context) {
        return SuggestionsState();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            if (!showIndicator)
              Center(
                child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Consumer<SuggestionsState>(
                        builder: (context, suggestionState, _) {
                      return TextButton(
                          child: const Text(
                            "Submit",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            if (_recipeImage == null) {
                              _showSnackBar(context, "Add recipe image");
                              return;
                            }
                            if (ingredientWidgetsList.isEmpty) {
                              _showSnackBar(
                                  context, "Add at least 1 ingredient");
                              return;
                            }
                            List<String> ingredientUniqueNames = [];
                            int uniqueNamesIndex = 0;
                            int position = 0;
                            while (uniqueNamesIndex <=
                                ingredientNameControllerList.length - 1) {
                              if (ingredientUniqueNames.contains(
                                  ingredientNameControllerList[uniqueNamesIndex]
                                      .text)) {
                                _showSnackBar(context,
                                    "All ingredient unique names must be different");
                                return;
                              } else {
                                if (!suggestionState.isIngredientNameFromList(
                                        ingredientNameControllerList[uniqueNamesIndex].text)
                                    && _ingredientImageList[position] == null) {
                                  _showSnackBar(
                                      context,
                                      "Upload image for ingredient " +
                                          (position + 1).toString());
                                  return;
                                }
                                ingredientUniqueNames.add(
                                    ingredientNameControllerList[
                                            uniqueNamesIndex]
                                        .text);
                              }
                              position++;
                              uniqueNamesIndex = uniqueNamesIndex + 3;
                            }
                            _showSnackBar(
                                context, "Submitting form. Do not leave app",
                                secondsDuration: 5);
                            setState(() {
                              showIndicator = true;
                            });
                            submitForm(suggestionState, context).then((value) => postSubmit(suggestionState, true))
                                .onError((error, stackTrace) => postSubmit(suggestionState, false));
                          });
                    })),
              )
          ],
        ),
        body: showIndicator
            ? const Center(child: CircularProgressIndicator())
            : Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Consumer<SuggestionsState>(
                              builder: (context, mealNameState, _) {
                            return TypeAheadFormField(
                              textFieldConfiguration: TextFieldConfiguration(
                                decoration: const InputDecoration(
                                  labelText: "Unique Meal Name",
                                  border: OutlineInputBorder(),
                                ),
                                controller: uniqueMealNameEditingController,
                              ),
                              itemBuilder:
                                  (BuildContext context, String itemData) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(itemData),
                                );
                              },
                              suggestionsCallback: (pattern) {
                                return mealNameState.getMealSuggestion(pattern);
                              },
                              onSuggestionSelected: (suggestion) {
                                uniqueMealNameEditingController.value =
                                    TextEditingValue(
                                        text: suggestion as String);
                              },
                              validator: (meanName) {
                                if (!mealNameState.isMeanNameValid(meanName)) {
                                  return "Unique Meal name not valid";
                                }
                              },
                            );
                          }),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Description",
                              border: OutlineInputBorder(),
                            ),
                            validator: (description) {
                              return description!.isEmpty
                                  ? "Fill Description"
                                  : null;
                            },
                            controller: mealNameDescriptionEditingController,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Meal name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (mealName) {
                              if (mealName!.isEmpty) {
                                return "Fill meal name";
                              }
                            },
                            controller: mealNameEditingController,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Youtube link",
                              border: OutlineInputBorder(),
                            ),
                            validator: (youTubeLink) {
                              if (youTubeLink!.isEmpty || !youTubeLink.contains(".")) {
                                return "Not a link";
                              }
                            },
                            controller: youTubeLinkEditingController,
                          ),
                        ),
                        Consumer<SuggestionsState>(
                            builder: (context, categoryState, _) {
                              return Wrap(
                                children: getSelectedCategoryButtons(categoryState),
                              );
                            }),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Consumer<SuggestionsState>(
                              builder: (context, categoryState, _) {
                                return TypeAheadFormField(
                                  textFieldConfiguration: const TextFieldConfiguration(
                                    decoration: InputDecoration(
                                      labelText: "Add Category",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  //  onSuggestionSelected: onSuggestionSelected,
                                  itemBuilder:
                                      (BuildContext context, String itemData) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(itemData),
                                    );
                                  },
                                  suggestionsCallback: (pattern) {
                                    return categoryState.getCategorySuggestion(pattern);
                                  },
                                  onSuggestionSelected: (suggestion) {
                                    categoryState.setSelectedCategory(suggestion);
                                    setState(() {});
                                  },
                                );
                              }),
                        ),
                        if (_recipeImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Image.file(
                              _recipeImage!,
                              height: 120,
                              width: 120,
                              scale: 0.1,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ElevatedButton(
                            child: const Text("Upload Image of recipe"),
                            onPressed: () => _showPicker(context, -1, -1),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary: Colors.green),
                                child: const Text("Add new ingredient"),
                                onPressed: () => _addIngredientsWidget(),
                              ),
                            ),
                            if (ingredientWidgetsList.length >= 5)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      primary: Colors.red),
                                  child: const Text("Remove last ingredient"),
                                  onPressed: () {
                                    setState(() {
                                      if (ingredientNameControllerList.length >=
                                          3) {
                                        ingredientNameControllerList
                                            .removeRange(
                                                ingredientNameControllerList
                                                        .length -
                                                    3,
                                                ingredientNameControllerList
                                                    .length);
                                      }
                                      if (ingredientWidgetsList.length >= 5) {
                                        ingredientWidgetsList.removeRange(
                                            ingredientWidgetsList.length - 5,
                                            ingredientWidgetsList.length);
                                      }
                                      if (_ingredientImageList.isNotEmpty) {
                                        _ingredientImageList.removeLast();
                                      }
                                      if (latestBucketStart == 0 ||
                                          latestBucketStart == -1) {
                                        latestBucketStart = -1;
                                      } else {
                                        latestBucketStart =
                                            latestBucketStart - 5;
                                      }
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                        ...ingredientWidgetsList,
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  _imgFromCamera(int widgetListImageIndex, int imageBucketIndex) async {
    XFile? pickImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      if (imageBucketIndex > -1) {
        _ingredientImageList[imageBucketIndex] = File(pickImage!.path);
        ingredientWidgetsList[widgetListImageIndex] = Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Image.file(
            File(pickImage.path),
            height: 120,
            width: 120,
            scale: 0.1,
          ),
        );
      } else {
        _recipeImage = File(pickImage!.path);
      }
    });
  }

  _imgFromGallery(int widgetListImageIndex, int imageBucketIndex) async {
    XFile? pickImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (imageBucketIndex > -1) {
        _ingredientImageList[imageBucketIndex] = File(pickImage!.path);
        ingredientWidgetsList[widgetListImageIndex] = Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Image.file(
            File(pickImage.path),
            height: 120,
            width: 120,
            scale: 0.1,
          ),
        );
      } else {
        _recipeImage = File(pickImage!.path);
      }
    });
  }

  void _showPicker(context, int widgetListImageIndex, int imageBucketIndex) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Photo Library'),
                    onTap: () {
                      _imgFromGallery(widgetListImageIndex, imageBucketIndex);
                      Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    _imgFromCamera(widgetListImageIndex, imageBucketIndex);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  _addIngredientsWidget() {
    _ingredientImageList.add(null);
    int imageBucketIndex = _ingredientImageList.length - 1;

    if (latestBucketStart == -1) {
      latestBucketStart = 0;
    } else {
      latestBucketStart = latestBucketStart + 5;
    }
    int widgetListImageIndex = latestBucketStart + 3;

    ingredientNameControllerList.add(TextEditingController());
    ingredientNameControllerList.add(TextEditingController());
    ingredientNameControllerList.add(TextEditingController());
    int uniqueIngredientControllerIndex =
        ingredientNameControllerList.length - 3;

    setState(() {
      ingredientWidgetsList.addAll([
        Padding(
          padding: const EdgeInsets.only(top: 14.0),
          child:
              Consumer<SuggestionsState>(builder: (context, mealNameState, _) {
            return TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                decoration: const InputDecoration(
                  labelText: "Unique Ingredient Name",
                  border: OutlineInputBorder(),
                ),
                controller: ingredientNameControllerList[
                    uniqueIngredientControllerIndex],
              ),
              //  onSuggestionSelected: onSuggestionSelected,
              itemBuilder: (BuildContext context, String itemData) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(itemData),
                );
              },
              suggestionsCallback: (pattern) {
                return mealNameState.getIngredientsSuggestion(pattern);
              },
              onSuggestionSelected: (suggestion) {
                ingredientNameControllerList[uniqueIngredientControllerIndex]
                    .value = TextEditingValue(text: suggestion as String);
              },
              validator: (ingredientName) {
                if (ingredientName == null || ingredientName.isEmpty) {
                  return "Fill valid ingredient unique name";
                }
              },
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: "Ingredient Name English",
              border: OutlineInputBorder(),
            ),
            validator: (ingredientEnglishName) {
              if (ingredientEnglishName!.isEmpty) {
                return "Fill English name of ingredient";
              }
            },
            controller: ingredientNameControllerList[
                ingredientNameControllerList.length - 2],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: "Ingredient Name Hindi",
              border: OutlineInputBorder(),
            ),
            validator: (ingredientHindiName) {
              if (ingredientHindiName!.isEmpty) {
                return "Fill Hindi name of ingredient";
              }
            },
            controller: ingredientNameControllerList[
                ingredientNameControllerList.length - 1],
          ),
        ),
        Container(),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ElevatedButton(
            child: Text((_ingredientImageList.length).toString() +
                ". Upload Image of Ingredients"),
            onPressed: () =>
                _showPicker(context, widgetListImageIndex, imageBucketIndex),
          ),
        )
      ]);
    });
    _showSnackBar(context, "New ingredient list added.");
  }

  List<Widget> getSelectedCategoryButtons(SuggestionsState categoryState) {
    List<Widget> selectedCategoryButtons = [];
    for (String selectedCategory in categoryState.categoriesSelectedList) {
      selectedCategoryButtons.add(Container(
        height: 52,
        padding: const EdgeInsets.fromLTRB(0, 10, 10, 5),
        child: TextButton.icon(
            style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: const BorderSide(color: Colors.red)
                    )
                ),
            ),
            onPressed: () {
              categoryState.removeSelectedCategory(selectedCategory);
              setState(() {});
            },
            icon: const Center(child: Icon(Icons.cancel_outlined)),
            label: Text(selectedCategory)),
      ));
    }
    return selectedCategoryButtons;
  }
}

Future<bool> _hasNetworkConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
    return false;
  } on SocketException catch (_) {
    return false;
  }
}

_showSnackBar(BuildContext context, String message, {secondsDuration = 3}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: secondsDuration),
  ));
}
