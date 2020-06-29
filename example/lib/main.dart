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
      title: 'Flutter Clipboard',
      debugShowCheckedModeBanner: false,
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
  String pasteValue='';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 100,
                ),
                TextFormField(
                  controller: field,
                  decoration: InputDecoration(
                    hintText: 'Enter text'
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    InkWell(
                      onTap: (){
                        if(field.text.trim() == ""){
                          print('enter text');
                        } else {
                          print(field.text);
                          FlutterClipboard.copy(field.text).then(( value ) =>
                              print('copied'));
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(15)
                        ),
                        child: Center(child: Text('COPY')),
                      ),
                    ),
                    InkWell(
                      onTap: (){
                          
                          FlutterClipboard.paste().then((value) {
                            print(value);
                            setState(() {
                              field.text = value;
                              pasteValue = value;
                            });
                          });
                      },
                      child: Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(15)
                        ),
                        child: Center(child: Text('PASTE')),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Text('Clipboard Text: $pasteValue',style: TextStyle(fontSize: 20),)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
