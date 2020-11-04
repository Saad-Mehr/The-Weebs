import 'package:flutter/material.dart';
import 'main.dart';
import 'mysql.dart';
import 'user.dart';

class Second extends StatefulWidget {
  @override
  _SecondState createState() => _SecondState();
}

class _SecondState extends State<Second> {

  var db = new Mysql();
  var emailText = '';

  void getUser() {
    db.getConnection().then((conn) {
      String sql = 'select first_name, last_name from heroku_19a4bd20cf30ab1.user where id = 1;';
      conn.query(sql).then((results) {
        for(var row in results) {
          setState(() {
            emailText = row[1];
          });
        }
      });
    });
  }

  final TextEditingController _email_controller = TextEditingController();
  final TextEditingController _password_controller = TextEditingController();
  Future<User> _futureUser;
  final succBar = SnackBar(content: Text('Yay! A SnackBar!'));

  @override
  Widget build(BuildContext context) {
    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
        body: Container(
          height: height,
          width: width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: width,
                  height: height*0.45,
                  child: Image.asset('assets/login_food_icon.png',fit: BoxFit.fill,),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('Signup',style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold),),
                    ],
                  ),
                ),
                SizedBox(height: 30.0,),
                TextField(
                  controller: _email_controller,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    suffixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
                SizedBox(height: 20.0,),
                TextField(
                  controller: _password_controller,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: Icon(Icons.visibility_off),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
                SizedBox(height: 30.0,),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Forgot password?',style: TextStyle(fontSize: 12.0),),
                      RaisedButton(
                        child: Text('Signup'),
                        color: Color(0xffEE7B23),
                        onPressed: () {
                        },
                      ),
                      Text(
                        'user:',
                      ),
                      Text(
                        '$emailText',
                      )
                    ],
                  ),
                ),
                SizedBox(height:20.0),
                GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Myapp()));
                  },
                  child: Text.rich(
                    TextSpan(
                        text: 'Already have an account? ',
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                                color: Color(0xffEE7B23)
                            ),
                          ),
                        ]
                    ),
                  ),
                ),


              ],
            ),
          ),
        )
    );
  }
}