import 'package:example/core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  TextEditingController field = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 200,
            ),
            TextFormField(
              controller: field,
              decoration: InputDecoration(
                hintText: 'Enter text'
              ),
            ),
            Row(
              children: <Widget>[
                InkWell(
                  onTap: (){
                    if(field.text.trim() == ""){
                      print('enter text');
                    } else {
                      FlutterClipboard.copy(field.text).then(( value ) =>
                          print('copied'));
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Text('COPY'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
