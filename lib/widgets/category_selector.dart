import 'package:flutter/material.dart';

class CategorySelector extends StatefulWidget {
  @override
  CategorySelectorState createState() => CategorySelectorState();
}

class CategorySelectorState extends State<CategorySelector> {
  int selectedIndex = 0;
  final List<String> categories = ['STATUS','CHATS', 'ONLINE', 'GROUPS', 'CALLS'];

  @override
  Widget build(BuildContext context) {
    return Container(
       height: 60.0,
       color: Theme.of(context).primaryColor,
       child: ListView.builder(
         scrollDirection: Axis.horizontal,
         itemCount: categories.length,
         itemBuilder: (BuildContext context, int index){
           return GestureDetector(
             onTap: (){
               setState(() {
                selectedIndex = index;
               });
             },
              child: Padding(
               padding: EdgeInsets.symmetric(
                 horizontal: 20.0,
                 vertical: 10.0,
               ),
               child: Text(categories[index],
               style: TextStyle(
                 color: index == selectedIndex ? Colors.white : Colors.white60,
                 fontSize: 24.0,
                 fontWeight: FontWeight.bold,
                 letterSpacing: 0.5,
                 ),
               ),
             ),
           );
         },
       ),
    );
  }
  _selectedPage(){
    switch(selectedIndex){
      case 0:

    }
  }
}