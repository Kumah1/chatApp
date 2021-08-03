// import 'package:kumchat/models/user_model.dart';
// import 'package:flutter/material.dart';
// import 'package:kumchat/screens/chat_screen.dart';

// class FavoriteContact extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() {
//     // TODO: implement createState
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<UserM> favorites = [];

//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 10.0),
//       child: Column(
//         children: <Widget>[
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 20.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: <Widget>[
//                 Text(
//                   "Favourite Contacts",
//                   style: TextStyle(
//                     color: Colors.blueGrey,
//                     fontSize: 18.0,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 1.0,
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(
//                     Icons.more_horiz,
//                   ),
//                   iconSize: 30.0,
//                   color: Colors.blue,
//                   onPressed: () {},
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             height: 120.0,
//             child: ListView.builder(
//               padding: EdgeInsets.only(left: 10.0),
//               scrollDirection: Axis.horizontal,
//               itemCount: favorites.length,
//               itemBuilder: (BuildContext context, int index) {
//                 return GestureDetector(
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => ChatScreen(
//                         user: favorites[index],
//                       ),
//                     ),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(10.0),
//                     child: Column(
//                       children: <Widget>[
//                         CircleAvatar(
//                           radius: 35.0,
//                           backgroundImage:
//                               AssetImage(favorites[index].imageUrl),
//                         ),
//                         SizedBox(
//                           height: 6.0,
//                         ),
//                         Text(
//                           favorites[index].username,
//                           style: TextStyle(
//                             color: Colors.blueGrey,
//                             fontSize: 16.0,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
