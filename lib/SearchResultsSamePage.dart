import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:quikquisine490/profile.dart';
import 'package:quikquisine490/recipe.dart';
import 'package:quikquisine490/recipes.dart';
import 'package:quikquisine490/searchRetrieval.dart';
import 'package:quikquisine490/userIngredientList.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'calendar.dart';
import 'main.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:async';
import 'ingredient.dart';
import 'mysql.dart';
import 'search.dart';
import 'user.dart';
import 'package:mysql1/mysql1.dart' as mysql1Dart;

AutoCompleteTextField searchTextField;
TextEditingController controller = new TextEditingController();
ItemScrollController _scrollController = ItemScrollController();
String searchResultLabel = "Recipes based on your ingredients";
bool isLoading = false;
bool isRecipeListLoading = false;
bool searchedFromOtherPg = false;

class InitiateRecipeList extends StatefulWidget {

  RecipeListState createState() => RecipeListState();
}

Future<void> clearRecipeListSamePage() async {

  //List temp = recipeList;

  if(recipeList != null){
    recipeList.clear();
  } else {
    recipeList = [];
  }

  //recipeList = temp;
}

class RecipeListState extends State<InitiateRecipeList> {
  @override
  void initState() {

    clearRecipeListSamePage();
    //print("savedRecipesList in recipelist initstate is " + savedRecipesList.toString());

    //print("recipeList is " + recipeList.toString());

    /*if(recipeList == null){
      print("recipeList is null " + recipeList.toString());
    } else if(recipeList.isEmpty){
      print("recipeList is empty ");
      //_loadAutoCompleteRecipeList();
    }*/

    _loadAutoCompleteRecipeList();
    //savedRecipesList = recipeList;

    //print("recipeList after operation is " + recipeList.toString());
    //print("savedRecipesList after operation is " + savedRecipesList.toString());

    if(searchedFromOtherPg == false) {
      searchResultLabel = "Recipes based on your ingredients";
    }

    super.initState();
  }

  void _loadAutoCompleteRecipeList() async {
    print("Executing queries in recipes()");
    await recipes();
  }

  @override
  Widget build(BuildContext context) {
    return AutocompleteSearch();
  }
}

class AutocompleteSearch extends StatefulWidget{
  AutocompleteSearchState createState() => AutocompleteSearchState();
}

class AutocompleteSearchState extends State<AutocompleteSearch>{

  GlobalKey<AutoCompleteTextFieldState<Recipes>> searchKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: Container(
        child: Column(
            children: <Widget>[
              searchTextField = AutoCompleteTextField<Recipes>(
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                ),
                decoration: InputDecoration(
                  hintText: 'Search recipes',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  focusColor: Colors.red,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.orange[200], width: 1.5),
                  ),
                  border: const OutlineInputBorder(),
                ),
                itemBuilder: (context, item){
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(item.name,
                        style: TextStyle(
                            fontSize: 16.0
                        ),),
                      Padding(
                        padding: EdgeInsets.all(15.0),
                      ),
                    ],
                  );
                },
                itemFilter: (item, query) {
                  return item.name
                      .toLowerCase()
                      .contains(query.toLowerCase());
                },
                itemSorter: (a, b) {
                  return a.name.compareTo(b.name);
                },
                itemSubmitted: (item) {
                  setState(() {
                    searchTextField.textField.controller.text = item.name;
                  });
                },
                key: searchKey,
                suggestions: recipeList,
                suggestionsAmount: 10,
                clearOnSubmit: false,
              ),
            ]
        )
      )
    );
  }
}

class MenuOptions {
  static const String Recipes = 'Recipes';
  static const String Search = 'Search';
  static const String AdvancedSearch = 'Advanced Search';
  static const String MealPlanner = 'MealPlanner';
  static const String Profile = 'Profile';
  static const String MyIngredientList = 'My ingredients list';
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

class BasicSearch extends StatelessWidget {

  static const String _title = 'Search';

  Future<void> optionAction(String option, BuildContext context) async {

    searchedFromOtherPg = false;
    if (option == MenuOptions.Recipes) {

      await getRecipes();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title),
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
            onPressed: () => {
              searchedFromOtherPg = false,
              Navigator.pop(context, false),
            }
          )
        ),
        body: BasicSearchWidget(),
      )
    );
  }
}

class BasicSearchWidget extends StatefulWidget {
  @override
  BasicSearchWidgetState createState() => BasicSearchWidgetState();
}


class BasicSearchWidgetState extends State<BasicSearchWidget> with TickerProviderStateMixin {

  bool isFirstSearch = true;
  var db = new Mysql();

  void initState() {

    setState(() {
      isRecipeListLoading = true;
    });

    ingredientsList.clear();
    clearRecipeListSamePage();

    if(searchedFromOtherPg == false){
      clearResults();
      searchRecipeNames(null);
    }

    userIngredientNamesList = [];

    for(int i = 0; i < selectedIngredientList.length; i++) {
      userIngredientNamesList.add(selectedIngredientList[i].name);
    }

    if(categoriesList.isEmpty){
      categories();
    }

    isLoading = false;
    super.initState();
  }


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

    setState(() {
    });
  }

  getIngredientIds(String ingParam){

    searchedIngIDs = ingParam.split(',');
    print("searchedIngIDs is now " + searchedIngIDs.toString());

    for(int i = 0; i < searchedIngIDs.length; i++){
      for(int j = 0; j < ingredientsList.length; j++){
        if(ingredientsList[j]['name'] == searchedIngIDs[i]){

          searchedIngNames.add(ingredientsList[j]['name']);
          searchedIngIDs[i] = ingredientsList[j]['id'].toString();
        }
      }
    }

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

  Future searchRecipeNames(String searchText) async {

    String linkParams = '';
    String nameParam = '';
    String categParam = '';
    String ingText = '';
    List<dynamic> tempRecipes = [];
    List<dynamic> tempIngList = [];

    await getIngredients();

    if( userIngredientNamesList.isNotEmpty && userIngredientNamesList != null ){ // i.e. if user has 1+ ingredients

      ingText += userIngredientNamesList.toString().replaceAll("[", "").replaceAll("]", "").replaceAll(", ", ",");
    }

    print("ingText is now " + ingText);
    userIngredientNamesList = ingText.split(',');
    print("userIngredientNamesList is now " + userIngredientNamesList.toString());
    print("ingredientsList is now " + ingredientsList.toString());
    print("ingText split is now " + ingText.split(',').toString());

    if(searchText != null && searchText.isNotEmpty) {

      searchTerm = searchText;
      nameParam = searchTerm;
      linkParams += '?recipe_name=$nameParam';

      nameParam.isEmpty ? linkParams += '?search_type=Category' : linkParams += '&search_type=Category';
      categParam = categoryIDs.toString().replaceAll(new RegExp("[\\[\\]\\s]"), "");
      linkParams += '&categories=';
      linkParams += categParam;
    } else {

      linkParams += '?search_type=Ingredient';

      ingText = getIngredientIds(ingText);
      linkParams += '&ingredients=';
      linkParams += ingText;
    }

    // linkParams in same page is now &search_type=Ingredient&ingredients=1,21,4261,2691,3501,601
    print("linkParams in same page is now " + linkParams);

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

    recipesPageTitle = "Search Results";

    setState(() {
      isLoading = false;
      isRecipeListLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _searchScafKey = GlobalKey<ScaffoldState>();
    final searchResultKey = new GlobalKey();

    return Scaffold(
      key: _searchScafKey,
      body: SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            SizedBox(height: 30.0,),
            Text(
              "Discover",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 30.0,),
            InitiateRecipeList(),
            SizedBox(height: 30.0,),
            isLoading ? Center(
              child: CircularProgressIndicator(),
            ) : new RaisedButton(
              child: Text('Go!'),
              color: Colors.orange[600],
              textColor: Colors.white,
              onPressed: () async {

                setState(() {
                  isLoading = true;
                });

                searchedFromOtherPg = false;
                print("Testing search bar");

                if( searchTextField.textField.controller.text.trim().isEmpty
                    || searchTextField.textField.controller.text == null) {

                  print("Testing inner search bar");
                  final snackBar = SnackBar(
                    content: Text('Please search for a recipe name'),
                    backgroundColor: Colors.redAccent,
                  );

                  _searchScafKey.currentState..showSnackBar(snackBar);
                } else if (selectedIngredientList == null
                    || selectedIngredientList.isEmpty) {

                  final snackBar = SnackBar(
                    content: Text('Please have 1 or more ingredients in your list'),
                    duration:  Duration(seconds: 5),
                    backgroundColor: Colors.redAccent,
                  );

                  _searchScafKey.currentState..showSnackBar(snackBar);
                } else {

                  if(totalRecipes.length > 0){

                    setState(() {
                      isFirstSearch = false;
                    });
                  }

                  clearRecipeListSamePage();
                  clearResults();
                  //categories();

                  categoryIDs = retrievalCatIDs;
                  await searchRecipeNames( searchTextField.textField.controller.text );
                  searchResultLabel = recipesPageTitle;
                  searchTextField.textField.controller.clear();
                  // _scrollController.scrollTo(index: 150, duration: Duration(seconds: 1));
                  //Scrollable.ensureVisible(searchResultKey.currentContext);
                }

                print("totalRecipes in go button is now length " + totalRecipes.length.toString());

                setState(() {
                  isLoading = false;
                });
              },
            ),
            SizedBox(height: 10.0,),
            RaisedButton(
                child: Text('Advanced Search'),
                color: Colors.orange[600],
                textColor: Colors.white,
                onPressed: () async {

                  print("searchedFromOtherPg was " + searchedFromOtherPg.toString());
                  searchedFromOtherPg = false;
                  print("searchedFromOtherPg is now  " + searchedFromOtherPg.toString());
                  print("totalRecipes are of length " + totalRecipes.length.toString() + " with titles " + totalRecipes[0]['name']);
                  Navigator.push(context,MaterialPageRoute(builder: (context) => SearchPage()));
                }
            ),
            SizedBox(height: 30.0,),
            /*ScrollablePositionedList.builder(
              itemScrollController: _scrollController,
              itemCount: _myList.length,
              itemBuilder: (context, index) {
                return _myList[index];
              },
            ),*/
            new Card(
              //key: searchResultKey,
              child: new Container(
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: 10, // Space between underline and text
                  right: 10,
                  left: 10,
                ),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(
                      color: Colors.amber,
                      width: 1.3, // Underline thickness
                    ))
                ),
                child: Text(
                  searchResultLabel,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.0,),
            (userIngredientNamesList.isEmpty && searchedFromOtherPg == false) ? Center(
              child: CircularProgressIndicator(),
            ) : Container(),
            ( filteredSortedTotal.isEmpty ) ? Center(
              child: CircularProgressIndicator(),
            ) : SizedBox(
              height: 510,
              child: MyStatelessWidget(),
            ),
            /*
            setState(() {
      isRecipeListLoading = true;
    });
            */

            // _scrollController
          ],
      ),
      ),
    );
  }
}