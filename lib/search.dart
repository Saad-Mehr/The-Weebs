import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart' as mysql1Dart;
import 'package:quikquisine490/ingredient.dart';
import 'package:quikquisine490/recipes.dart';
import 'package:quikquisine490/searchRetrieval.dart';
import 'package:quikquisine490/user.dart';
import 'SearchResultsSamePage.dart';
import 'calendar.dart';
import 'main.dart';
import 'mysql.dart';
import 'profile.dart';
import 'userIngredientList.dart';


var searchTerm = "";
final String searchTypeTextAll = "All";
final String searchTypeTextPref = "Preference";
final String searchTypeTextCat = "Category";
final String searchTypeTextIng = "Ingredient";
final String searchTypeTextName = "Recipe";
List newCategories = [];
List newPreferences = [];
List categoryIDs = [];
List preferenceIDs = [];
bool isAnyCategoryChecked = false;
bool isAnyPreferenceChecked = false;
bool isIngredientSearch = false;
var checkedCategories = [];
var checkedPreferences = [];
List<dynamic> recipeIDs = [];
List<dynamic> recipeNames = [];
List<dynamic> recipeDesc = [];
List<dynamic> recipeServing = [];
List<dynamic> recipeIngredients = [];
List<dynamic> recipePicURLs = [];
List<dynamic> recipePrep = [];
List<dynamic> recipeRate = [];
List<dynamic> recipeReviews = [];
List<dynamic> sortedRecipeIng = [];
List<dynamic> sortedRecipeIngNames = [];
List<dynamic> filteredSortedIng = [];
List<Map<dynamic,dynamic>> ingredientsList = [];
List<dynamic> searchedIngIDs = [];
List<dynamic> searchedIngNames = [];
List<dynamic> missingIngredients = [];
// used for storing user's list of ingredients
List<dynamic> userIngredientNamesList = [];

class SearchPage extends StatelessWidget {
  static const String _title = 'Advanced Search';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(
            title: const Text(_title),
            backgroundColor: Colors.deepOrangeAccent,
            actions: <Widget>[
              PopupMenuButton<String>(
                  onSelected: (option) => optionAction(option, context),
                  itemBuilder: (BuildContext context) {
                    return MenuOptions.options.map((String option){
                      return PopupMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList();
                  }
              )
            ],
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, false),
            )
        ),
        body:
        SearchWidget(),
      ),
    );
  }

  Future<void> optionAction(String option, BuildContext context) async {

      if (option == MenuOptions.Recipes) {
        await getRecipes();
        //filteredSortedIng.clear();
        recipesPageTitle = 'Recipes';
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipePage()),
        );
      }
      else if (option == MenuOptions.Search) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BasicSearch()),
        );
      }
      else if (option == MenuOptions.AdvancedSearch) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchPage()),
        );
      }
      else if (option == MenuOptions.MealPlanner) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      }
      else if (option == MenuOptions.Profile) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => profile()),
        );
      }
      else if (option == MenuOptions.MyIngredientList) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserIngredientList()),
        );
      }
      else if (option == MenuOptions.Logout) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Myapp()),
        );
      }
  }

}

class MenuOptions {
  static const String Recipes = 'Recipes';
  static const String Search = 'Search';
  static const String AdvancedSearch = 'Advanced Search';
  static const String MealPlanner = 'MealPlanner';
  static const String Profile = 'Profile';
  static const String MyIngredientList = 'My ingredients';
  static const String Logout = 'Logout';

  static const List<String> options = <String>[
    Recipes,
    Search,
    AdvancedSearch,
    MealPlanner,
    Profile,
    MyIngredientList,
    Logout
  ];

}

class SearchWidget extends StatefulWidget {
  @override
  SearchWidgetState createState() =>
      new SearchWidgetState();
}

String get getSearchTerm{
  return searchTerm;
}

List get getRecipeNames {
  return recipeNames;
}

List get getRecipeDesc {
  return recipeDesc;
}

void clearRecipeList(){

  searchTerm = "";
  recipeIDs.clear();
  recipeNames.clear();
  recipeDesc.clear();
  recipeServing.clear();
  recipeIngredients.clear();
  recipePicURLs.clear();
  recipePrep.clear();
  recipeRate.clear();
  recipeReviews.clear();
  sortedRecipeIng = [];
  filteredSortedIng.clear();
  categoryIDs.clear();
  preferenceIDs.clear();
  checkedCategories.clear();
  checkedPreferences.clear();
  searchedIngIDs.clear();
  searchedIngNames.clear();
  missingIngredients.clear();
  isAnyCategoryChecked = false;
  isAnyPreferenceChecked = false;
  isIngredientSearch = false;
}

class SearchWidgetState extends State<SearchWidget> with TickerProviderStateMixin {

  bool isLoading = false;
  bool isCategoryLoading = false;
  bool isPreferenceLoading = false;
  bool isIngredientLoading = false;
  bool isCatChecked = false;
  bool isPrefChecked = false;
  bool isUserIngListChecked = false;
  bool isAllErr = false;
  bool isIngredientErr = false;
  String errMsg = "";
  Map<String, bool> categoryMap = {};
  Map<String, bool> preferenceMap = {};
  var db = new Mysql();
  final recipesAllController = TextEditingController();
  final ingredientsAllController = TextEditingController();
  final onlyCategoriesController = TextEditingController();
  final onlyPreferencesController = TextEditingController();
  final onlyIngredientsController = TextEditingController();

  Future getIngredients() async {

    String sqlQuery = 'SELECT ingredients.id, ingredients.name ' +
        'FROM heroku_19a4bd20cf30ab1.ingredients;';

    await db.getConnection().then((conn) {

      return conn.query(sqlQuery).then((mysql1Dart.Results results) {
        results.forEach((row) {

          Map r = new Map();
          for(int i=0; i<results.fields.length; i++) {
            r[results.fields[i].name] = row[i];
          }

          ingredientsList.add(r);
        });
      });
    });

    print('ingredientsList is ' + ingredientsList.toString());

    setState(() {
      isIngredientLoading = false;
    });
  }

  getIngredientIds(String ingParam){

    searchedIngIDs = ingParam.split(',');

    print("searchedIngIDs in search.dart is now " + searchedIngIDs.toString());
    print("ingredientsList in search.dart is now " + ingredientsList.toString());

    for(int i = 0; i < searchedIngIDs.length; i++){
      for(int j = 0; j < ingredientsList.length; j++){
        if(ingredientsList[j]['name'] == searchedIngIDs[i]){

          searchedIngNames.add(ingredientsList[j]['name']);
          searchedIngIDs[i] = ingredientsList[j]['id'].toString();
        }
      }
    }

    print("searchedIngIDs in search.dart is now " + searchedIngIDs.toString());
    ingParam = searchedIngIDs.toString().replaceAll(new RegExp("[\\[\\]\\s]"), "");
    return ingParam;
  }

  Future sortSearchedIngredients() async {

    sortedRecipeIng.length = recipeIngredients.length;
    sortedRecipeIngNames.length = recipeIngredients.length;

    for(int i = 0; i < recipeIngredients.length; i++){

      sortedRecipeIng[i] = [];
      sortedRecipeIngNames[i] = [];
      for(int j = 0; j < recipeIngredients[i].length; j++){

        sortedRecipeIng[i].add("${recipeIngredients[i][j]['ingredient_qty']} ${recipeIngredients[i][j]['name']}\n");
        sortedRecipeIngNames[i].add("${recipeIngredients[i][j]['name']}");
      }

      filteredSortedIng.add(sortedRecipeIng[i].toString().replaceAll("[", "").replaceAll("]", "").replaceAll(",", ""));
    }

    List<dynamic> tempArr = sortedRecipeIngNames;
    List<dynamic> tempUserIng = userIngredientNamesList.map((element)=>element.toLowerCase()).toList();

    for(int i = 0; i < tempArr.length; i++) {

      if(tempUserIng.isNotEmpty){

        tempArr[i] = tempArr[i].map((element) => element.toLowerCase()).toList();
        tempArr[i].removeWhere((element) => tempUserIng.contains(element));
      }

      if( tempArr[i].isEmpty ) {

        missingIngredients.add("Missing ingredients:\n " + "You have all the ingredients!");
      } else {

        missingIngredients.add("Missing ingredients:\n " + tempArr[i].toString()
            .replaceAll("[", "").replaceAll("]", "")
            .replaceAll(",", "\n"));
      }
    }

  }

  Future metaSearch(String searchType, String searchText, String ingredientText) async {

    String linkParams = '';
    String nameParam = '';
    String prefParam = '';
    String categParam = '';
    String ingParam = '';
    String ingText = '';
    List<dynamic> tempRecipes = [];
    List<dynamic> tempIngList = [];
    userIngredientNamesList = [];

    for(int i = 0; i < selectedIngredientList.length; i++){
      userIngredientNamesList.add(selectedIngredientList[i].name);
    }

    if(ingredientText != null) {
      ingText = ingredientText.trim();
    }

    if( userIngredientNamesList.isNotEmpty && (userIngredientNamesList != null) ){

      ingText += userIngredientNamesList.toString().replaceAll("[", "").replaceAll("]", "");
      print("ingText is right now " + ingText);
    }

    if ( ingText.isNotEmpty && (ingText != null) ) {

      ingText += ", " + userIngredientNamesList.toString().replaceAll("[", "").replaceAll("]", "");
      print("ingText is right now " + ingText);
    }

    userIngredientNamesList = ingText.split(" ").join("").split(',');

    if( searchText != null && searchText.isNotEmpty && searchType != searchTypeTextName ){

      searchTerm = searchText;
      nameParam = searchTerm;
      linkParams += '?recipe_name=$nameParam';
    }

    if(searchType == searchTypeTextAll){

      nameParam.isEmpty ? linkParams += '?search_type=All' : linkParams += '&search_type=All';

      await getCheckedCategories();
      await getCheckedPreferences();

      if(isAnyPreferenceChecked == true) {
        prefParam = preferenceIDs.toString().replaceAll(new RegExp("[\\[\\]\\s]"), "");
        linkParams += '&preferences=';
        linkParams += prefParam;
      }

      if(isAnyCategoryChecked == true) {
        categParam = categoryIDs.toString().replaceAll(new RegExp("[\\[\\]\\s]"), "");
        linkParams += '&categories=';
        linkParams += categParam;
      }

      if(ingText.isNotEmpty){

        ingParam = getIngredientIds(ingText.split(" ").join(""));
        linkParams += '&ingredients=';
        linkParams += ingParam;
      }

    } else if (searchType == searchTypeTextPref){

      nameParam.isEmpty ? linkParams += '?search_type=Preference' : linkParams += '&search_type=Preference';
      await getCheckedPreferences();

      if(isAnyPreferenceChecked == true){

        prefParam = preferenceIDs.toString().replaceAll(new RegExp("[\\[\\]\\s]"), "");
        linkParams += '&preferences=';
        linkParams += prefParam;
      }

    } else if (searchType == searchTypeTextCat){

      nameParam.isEmpty ? linkParams += '?search_type=Category' : linkParams += '&search_type=Category';
      await getCheckedCategories();

      if(isAnyCategoryChecked == true) {

        categParam = categoryIDs.toString().replaceAll(new RegExp("[\\[\\]\\s]"), "");
        linkParams += '&categories=';
        linkParams += categParam;
      }

    } else if (searchType == searchTypeTextIng){

      nameParam.isEmpty ? linkParams += '?search_type=Ingredient' : linkParams += '&search_type=Ingredient';

      if(ingText.isNotEmpty){

        ingParam = getIngredientIds(ingText.split(" ").join(""));
        linkParams += '&ingredients=';
        linkParams += ingParam;
      }
    } else if (searchType == searchTypeTextName){

      nameParam.isEmpty ? linkParams += '?search_type=Recipe' : linkParams += '&search_type=Recipe';

      categParam = categoryIDs.toString().replaceAll(new RegExp("[\\[\\]\\s]"), "");
      linkParams += '&recipe_name=';
      linkParams += searchText;

    } else {

      print('Bad searchType input');
    }

    // linkParams in advanced page is now ?search_type=Ingredient&ingredients=eggegg,21,4261,2691,3501,601,1,21,4261,2691,3501,601
    print("linkParams in advanced page is now " + linkParams);

    await recipeSearch(linkParams);

    await getSearchIng();

    searchList.forEach((searchList) => recipeIDs.add(searchList['id']));
    searchList.forEach((searchList) => recipeNames.add(searchList['name']));
    searchList.forEach((searchList) => recipeDesc.add(searchList['description']));
    searchList.forEach((searchList) => recipeServing.add(searchList['serving']));
    searchList.forEach((searchList) => recipeIngredients.add(searchList['list_of_ingredients']));
    searchList.forEach((searchList) => recipePicURLs.add(searchList['get_image_url']));
    searchList.forEach((searchList) => recipePrep.add(searchList['preparation']));
    searchList.forEach((searchList) => recipeRate.add(searchList['AverageRating']));
    searchList.forEach((searchList) => recipeReviews.add(searchList['review']));

    await sortSearchedIngredients();

    tempIngList = filteredSortedIng;

    for(int i = 0; i < recipeIDs.length; i++) {
      for(int j = 0; j < totalRecipes.length; j++) {
        if( recipeIDs[i] == totalRecipes[j]['id'] ) {
          tempRecipes.add(totalRecipes[j]);
        }
      }
    }

    totalRecipes = tempRecipes;
    tempIngList = filteredSortedIng;

    for (int i = 0; i < missingIngredients.length; i++) {
      filteredSortedIng[i] += "\n${missingIngredients[i]}\n";
    }

    filteredSortedTotal = filteredSortedIng;
    filteredSortedIng = tempIngList;

    recipesPageTitle = "Recipes found: " + totalRecipes.length.toString();
    //print("filteredSortedTotal is ------------------ " + filteredSortedTotal.toString());

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {

    clearRecipeList();
    ingredientsList.clear();

    setState(() {
      isCategoryLoading = true; //Data is loading
      isPreferenceLoading = true;
      isIngredientLoading = true;
    });

    super.initState();
    findCategories();
    findPreferences();
    getIngredients();
    print('hi there');
  }

  void findCategories() async {

    int responseCode = await categories();
    print(responseCode);

    if(responseCode == 200){

      newCategories = categoriesList;

      setState(() {
        for(int i = 0; i < newCategories.length; i++){
          categoryMap.putIfAbsent(newCategories[i]['name'].toString(), () => false);
        }
      });
    } else {

      print("Error: unauthorized");
    }

    setState(() {
      isCategoryLoading = false;
    });
  }

  void findPreferences() async {

    int responseCode = await preferences();
    print(responseCode);

    if(responseCode == 200){

      newPreferences = preferencesList;

      setState(() {
        for(int i = 0; i < newPreferences.length; i++){
          preferenceMap.putIfAbsent(newPreferences[i]['name'].toString(), () => false);
        }
      });
    } else {

      print("Error: unauthorized");
    }

    setState(() {
      isPreferenceLoading = false;
    });
  }

  Future getCheckedCategories() async {

    categoryMap.forEach((key, value) {
      if(value == true) {
        checkedCategories.add(key);

        for(var i = 0; i < categoriesList.length; i++){
          if(categoriesList[i]['name'] == key){
            categoryIDs.add(categoriesList[i]['id']);
          }
        }

        isAnyCategoryChecked = true;
      }
    });
  }

  Future getCheckedPreferences() async {

    preferenceMap.forEach((key, value) {

      if(value == true) {

        checkedPreferences.add(key);

        for(var i = 0; i < preferencesList.length; i++){

          if(preferencesList[i]['name'] == key){

            preferenceIDs.add(preferencesList[i]['id']);
          }
        }

        isAnyPreferenceChecked = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: <Widget>[
            Container(
              constraints: BoxConstraints.expand(height: 60),
              child: TabBar(
                  labelColor: Colors.orange[900],
                  indicatorColor: Colors.orange[700],
                  tabs: [
                    Tab(
                      text: "All",
                      icon: Icon(Icons.search),
                    ),
                    Tab(
                      text: "Category",
                      icon: Icon(Icons.book),
                    ),
                    Tab(
                      text: "Preference",
                      icon: Icon(Icons.favorite),
                    ),
                    Tab(
                      text: "Ingredient",
                      icon: Icon(Icons.local_dining),
                    ),
                  ]
              ),
            ),
            Expanded(
              child: Container(
                child: TabBarView(children: [
                  Container(
                    height: height,
                    width: width,
                    margin: const EdgeInsets.only(left: 20.0, right: 20.0),

                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 40.0,),
                          Text(
                            "Input name (optional)",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 20.0,),
                          TextField(
                            controller: recipesAllController,
                            decoration: InputDecoration(
                              hintText: 'Search recipe name',
                              prefixIcon: Icon(Icons.search),
                              isDense: true,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.orange[200], width: 1.5),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 40.0,),
                          Text(
                            "Check Categories",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 20.0,),
                          isCategoryLoading ? Center(
                            child: CircularProgressIndicator(),
                          ) : Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Card(
                                  child: (new ListView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    children: categoryMap.keys.map((String key) {
                                      return new CheckboxListTile(
                                        title: new Text(key, style: TextStyle(color: Colors.black54),),
                                        value: categoryMap[key],
                                        activeColor: Colors.green,
                                        checkColor: Colors.white,
                                        onChanged: (bool value) {
                                          setState(() {
                                            categoryMap[key] = value;
                                            if(categoryMap.values.contains(true)) {
                                              isCatChecked = true;
                                            } else {
                                              isCatChecked = false;
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ))
                              )
                          ),
                          SizedBox(height: 40.0,),
                          Text(
                            "Check Preferences",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 20.0,),
                          isPreferenceLoading ? Center(
                            child: CircularProgressIndicator(),
                          ) : Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Card(
                                  child: (new ListView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    children: preferenceMap.keys.map((String key) {
                                      return new CheckboxListTile(
                                        title: new Text(key, style: TextStyle(color: Colors.black54),),
                                        value: preferenceMap[key],
                                        activeColor: Colors.green,
                                        checkColor: Colors.white,
                                        onChanged: (bool value) {
                                          setState(() {
                                            preferenceMap[key] = value;
                                            if(preferenceMap.values.contains(true)) {
                                              isPrefChecked = true;
                                            } else {
                                              isPrefChecked = false;
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ))
                              )
                          ),
                          SizedBox(height: 40.0,),
                          Text(
                            "Input Ingredients",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 50.0,),
                          isIngredientLoading ? Center(
                            child: CircularProgressIndicator(),
                          ) : new TextField(
                            controller: ingredientsAllController,
                            decoration: InputDecoration(
                              hintText: 'Search ingredients',
                              prefixIcon: Icon(Icons.search),
                              isDense: true,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.orange[200], width: 1.5),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 25.0,),
                          new CheckboxListTile(
                            title: new Text("Search with your saved ingredients", style: TextStyle(color: Colors.black54),),
                            value: isUserIngListChecked,
                            activeColor: Colors.green,
                            checkColor: Colors.white,
                            onChanged: (bool value) {
                              setState(() {

                                isUserIngListChecked = value;
                              });
                            },
                          ),
                          SizedBox(height: 5.0,),
                          isAllErr ? Center(
                              child: Text(
                                errMsg,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.red[400],
                                ),
                              )
                          ) : SizedBox(height: 21.0,),
                          SizedBox(height: 1.0,),
                          isLoading ? Center(
                            child: CircularProgressIndicator(),
                          ) : new RaisedButton(
                            child: Text('Search'),
                            color: Colors.orange[600],
                            textColor: Colors.white,
                            onPressed: () async {
                              setState(() {
                                isLoading = true; //Data is loading
                              });

                              errMsg = "";
                              isAllErr = false;

                              if( ( isCatChecked == false ) || ( isPrefChecked == false ) ){

                                errMsg += "Error: At least 1 category and preference box must be selected.\n\n";
                                isAllErr = true;
                                setState(() {
                                  isLoading = false; //Data is loading
                                });
                              }

                              if( isUserIngListChecked == false && ingredientsAllController.text.trim().isEmpty ) {

                                errMsg += "Error: An ingredient must be entered.\n\n";
                                isAllErr = true;
                                setState(() {
                                  isLoading = false; //Data is loading
                                });
                              }

                              if( isAllErr == false ) {

                                clearResults();
                                isIngredientSearch = true;
                                await metaSearch(searchTypeTextAll, recipesAllController.text, ingredientsAllController.text);
                                searchedFromOtherPg = true;
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>BasicSearch()));
                                searchResultLabel = "Advanced Search";
                              }
                            },
                          ),
                          SizedBox(height: 50.0,),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: height,
                    width: width,
                    margin: const EdgeInsets.only(left: 20.0, right: 20.0),

                    child: SingleChildScrollView(
                      child: Column(
                          children: [
                            SizedBox(height: 40.0,),
                            TextField(
                              controller: onlyCategoriesController,
                              decoration: InputDecoration(
                                hintText: 'Search recipes',
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.orange[200], width: 1.5),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 40.0,),
                            Text(
                              "Categories",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 20.0,),
                            isCategoryLoading ? Center(
                              child: CircularProgressIndicator(),
                            ) : Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Card(
                                    child: (new ListView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      children: categoryMap.keys.map((String key) {
                                        return new CheckboxListTile(
                                          title: new Text(key, style: TextStyle(color: Colors.black54),),
                                          value: categoryMap[key],
                                          activeColor: Colors.green,
                                          checkColor: Colors.white,
                                          onChanged: (bool value) {
                                            setState(() {
                                              categoryMap[key] = value;
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ))
                                )
                            ),
                            SizedBox(height: 50.0,),
                            isLoading ? Center(
                              child: CircularProgressIndicator(),
                            ) : new RaisedButton(
                              child: Text('Search'),
                              color: Colors.orange[600],
                              textColor: Colors.white,
                              onPressed: () async {
                                setState(() {
                                  isLoading = true; //Data is loading
                                });

                                clearResults();

                                await metaSearch(searchTypeTextCat, onlyCategoriesController.text, null);
                                searchedFromOtherPg = true;
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>BasicSearch()));
                                searchResultLabel = "Advanced Search";
                              },
                            ),
                          ]
                      ),
                    ),
                  ),
                  Container(
                    height: height,
                    width: width,
                    margin: const EdgeInsets.only(left: 20.0, right: 20.0),

                    child: SingleChildScrollView(
                      child: Column(
                          children: [
                            SizedBox(height: 40.0,),
                            TextField(
                              controller: onlyPreferencesController,
                              decoration: InputDecoration(
                                hintText: 'Search recipes',
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.orange[200], width: 1.5),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 40.0,),
                            Text(
                              "Preferences",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 20.0,),
                            isPreferenceLoading ? Center(
                              child: CircularProgressIndicator(),
                            ) : Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Card(
                                    child: (new ListView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      children: preferenceMap.keys.map((String key) {
                                        return new CheckboxListTile(
                                          title: new Text(key, style: TextStyle(color: Colors.black54),),
                                          value: preferenceMap[key],
                                          activeColor: Colors.green,
                                          checkColor: Colors.white,
                                          onChanged: (bool value) {
                                            setState(() {
                                              preferenceMap[key] = value;
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ))
                                )
                            ),
                            SizedBox(height: 50.0,),
                            isLoading ? Center(
                              child: CircularProgressIndicator(),
                            ) : new RaisedButton(
                              child: Text('Search'),
                              color: Colors.orange[600],
                              textColor: Colors.white,
                              onPressed: () async {
                                setState(() {
                                  isLoading = true; //Data is loading
                                });

                                clearResults();

                                await metaSearch(searchTypeTextPref, onlyPreferencesController.text, null);
                                searchedFromOtherPg = true;
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>BasicSearch()));
                                searchResultLabel = "Advanced Search";
                              },
                            ),
                          ]
                      ),
                    ),
                  ),
                  Container(
                    height: height,
                    width: width,
                    margin: const EdgeInsets.only(left: 20.0, right: 20.0),

                    child: SingleChildScrollView(
                      child: Column(
                          children: [
                            SizedBox(height: 40.0,),
                            isIngredientLoading ? Center(
                              child: CircularProgressIndicator(),
                            ) : new TextField(
                              controller: onlyIngredientsController,
                              decoration: InputDecoration(
                                hintText: 'Search ingredients',
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.orange[200], width: 1.5),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 25.0,),
                            new CheckboxListTile(
                              title: new Text("Search with your saved ingredients", style: TextStyle(color: Colors.black54),),
                              value: isUserIngListChecked,
                              activeColor: Colors.green,
                              checkColor: Colors.white,
                              onChanged: (bool value) {
                                setState(() {

                                  isUserIngListChecked = value;

                                  print("isUserIngListChecked is now " + isUserIngListChecked.toString());
                                });
                              },
                            ),
                            SizedBox(height: 5.0,),
                            isIngredientErr ? Center(
                                child: Text(
                                  errMsg,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.red[400],
                                  ),
                                )
                            ) : SizedBox(height: 1.0,),
                            SizedBox(height: 15.0,),
                            isLoading ? Center(
                              child: CircularProgressIndicator(),
                            ) : new RaisedButton(
                              child: Text('Search'),
                              color: Colors.orange[600],
                              textColor: Colors.white,
                              onPressed: () async {
                                setState(() {
                                  isLoading = true; //Data is loading
                                });

                                clearResults();
                                errMsg = "";
                                isIngredientErr = false;

                                if( isUserIngListChecked == false && onlyIngredientsController.text.trim().isEmpty ) {

                                  errMsg += "Error: An ingredient must be entered.";
                                  isIngredientErr = true;
                                  setState(() {
                                    isLoading = false; //Data is loading
                                  });
                                } else {

                                  isIngredientErr = false;
                                  isIngredientSearch = true;
                                  await metaSearch(searchTypeTextIng, null, onlyIngredientsController.text);
                                  searchedFromOtherPg = true;
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>BasicSearch()));
                                  searchResultLabel = "Advanced Search";
                                }

                              },
                            ),
                          ]
                      ),
                    ),
                  ),
                ]),
              ),
            )
          ],
        ),
      ),
    );
  }

}