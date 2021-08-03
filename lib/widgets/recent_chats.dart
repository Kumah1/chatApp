// import 'package:kumchat/models/user_model.dart';
// import 'package:flutter/material.dart';
// import 'package:kumchat/models/message_model.dart';
// import 'package:kumchat/screens/chat_screen.dart';

// class RecentChats extends StatefulWidget {
//   @override
//   Widget build(BuildContext context, int index) {
//     List<MessageModel>? chats;
//     List<UserM>? user;

//     return Expanded(
//       child: Container(
//         margin: EdgeInsets.only(top: 5.0, bottom: 5.0, right: 20.0),
//         padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(30.0),
//             topRight: Radius.circular(30.0),
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(30.0),
//             topRight: Radius.circular(30.0),
//           ),
//           child: ListView.builder(
//             itemCount: chats!.length,
//             itemBuilder: (BuildContext context, int index) {
//               final MessageModel chat = chats[index];
//               return GestureDetector(
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ChatScreen(
//                       user: user![index],
//                     ),
//                   ),
//                 ),
//                 child: Container(
//                   margin: EdgeInsets.only(
//                     top: 5.0,
//                     bottom: 5.0,
//                   ),
//                   padding: EdgeInsets.symmetric(vertical: 10.0),
//                   decoration: BoxDecoration(
//                       color: chat.unread ? Color(0xFFFFEFEE) : Colors.white,
//                       borderRadius: BorderRadius.only(
//                         topRight: Radius.circular(20.0),
//                         bottomRight: Radius.circular(20.0),
//                       )),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: <Widget>[
//                       Row(
//                         children: <Widget>[
//                           CircleAvatar(
//                             radius: 35.0,
//                             backgroundImage: AssetImage(user![index].imageUrl),
//                           ),
//                           SizedBox(
//                             width: 10.0,
//                           ),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: <Widget>[
//                               Text(
//                                 user[index].username,
//                                 style: TextStyle(
//                                     color: Colors.grey,
//                                     fontSize: 15.0,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               SizedBox(
//                                 height: 5.0,
//                               ),
//                               Container(
//                                 width: MediaQuery.of(context).size.width * 0.40,
//                                 child: Text(
//                                   chat.text,
//                                   style: TextStyle(
//                                       color: Colors.blueGrey,
//                                       fontSize: 15.0,
//                                       fontWeight: FontWeight.w600),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               )
//                             ],
//                           ),
//                         ],
//                       ),
//                       Column(
//                         children: <Widget>[
//                           Text(
//                             chat.time,
//                             style: TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 15.0,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                           SizedBox(
//                             height: 5.0,
//                           ),
//                           chat.unread
//                               ? Container(
//                                   width: 40.0,
//                                   height: 20.0,
//                                   decoration: BoxDecoration(
//                                     color: Theme.of(context).primaryColor,
//                                     borderRadius: BorderRadius.circular(30.0),
//                                   ),
//                                   alignment: Alignment.center,
//                                   child: Text(
//                                     'New',
//                                     style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 12.0,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 )
//                               : Text(''),
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   State<StatefulWidget> createState() {
//     // TODO: implement createState
//     return null;
//   }
// }
