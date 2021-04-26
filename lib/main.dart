import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future main() async{
  await DotEnv.load(fileName: ".env");
  runApp(Home());
}

class Home extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     return MaterialApp(
       home: Body(),
     );
   }
 }

 class Body extends StatefulWidget {
   @override
   _BodyState createState() => _BodyState();
 }

 class _BodyState extends State<Body> {
    List listResponse = [];
    String q;
    int currentOffset;
    Timer _debounce;
    String msg = "Nothing to see here!";
    ScrollController _scrollController = new ScrollController();

    Future getData(query) async{
      var data =  await http.get(Uri.parse("https://api.giphy.com/v1/gifs/search?api_key=${env['GIPHY_KEY']}&q=$query&limit=10&offset=0&rating=g&lang=en"));
      setState(() {
        currentOffset = 10;
        q = query;
        if (jsonDecode(data.body)["pagination"]["count"] == 0) {
          msg = "Can't find anything with that search keyword";
          listResponse = [];
        }
        else listResponse = jsonDecode(data.body)["data"];
        }
      );
    }

    Future addData(query) async{
      var data =  await http.get(Uri.parse("https://api.giphy.com/v1/gifs/search?api_key=${env['GIPHY_KEY']}&q=$query&limit=10&offset=$currentOffset&rating=g&lang=en"));
      setState(() {
        List temp;
        if (jsonDecode(data.body)["pagination"]["count"] > 0 ){
          temp = jsonDecode(data.body)["data"];
          for (int i=0; i<10; i++){
            listResponse.add(temp[i]);
          }
        currentOffset += 10;
      }}
      );
    }

    _onSearchChanged(String query) {
      if (_debounce?.isActive ?? false) _debounce.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        getData(query);
      });
    }

    @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if(_scrollController.position.pixels == _scrollController.position.maxScrollExtent){
        addData(q);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: Text("GIPHY search"),
         centerTitle: true,
       ),
       body: Container(
           child: Column(
             children: <Widget>[
               Padding(
                 padding: const EdgeInsets.all(8.0),
                 child: TextField(
                   onChanged: (text){
                     _onSearchChanged(text);
                   },
                   decoration: InputDecoration(
                     prefixIcon: Icon(Icons.search),
                     border: OutlineInputBorder(),
                     hintText: "Search for GIF"
                   ),
                 ),
               ),
              listResponse.isNotEmpty ? Expanded(
                 child: ListView.builder(
                   controller: _scrollController,
                   itemCount: listResponse.length,
                   itemBuilder: (context, index){
                     if (index == listResponse.length-1) return LinearProgressIndicator();
                   return Padding(
                     padding: const EdgeInsets.all(9.0),
                     child: Card(
                         child: Image.network(listResponse[index]['images']['original']['url'], fit: BoxFit.fitWidth)
                     ),
                   );
                 },
                 ),
               ) : Container(
                  alignment: Alignment.center,
                  child: Center(
                      child: Text("$msg")
                  )
              ),
              ]
           )
       ),
     );
   }
 }
