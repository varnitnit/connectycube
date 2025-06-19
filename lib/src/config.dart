import 'package:connectycube_sdk/connectycube_sdk.dart';

const String appId = '8750';
const String authKey = '81515A88-CD69-42C7-A8F9-C86D38999535';
//String appId = "8852";
//String authKey = "B94EDA88-DA57-4A8B-A3D6-40F419DBCAF6";

const String apiEndpoint = 'https://api.connectycube.com';
const String chatEndpoint = 'chat.connectycube.com';

List<CubeUser> users = [
  CubeUser(
    id: int.parse('13514207'),
    login: "olivia.brown88",
    fullName: "Olivia Brown",
    password: "olivia.brown88",
  ),
  CubeUser(
    id: int.parse('13514208'),
    login: "dave.lee42",
    fullName: "David Lee",
    password: "dave.lee42",
  ),
  CubeUser(
    id: int.parse('13514209'),
    login: "sophia.martinez77",
    fullName: "Sophia Martinez",
    password: "sophia.martinez77",
  ),
  CubeUser(
    id: int.parse('13514210'),
    login: "michael.riv89",
    fullName: "Michael Rivera",
    password: "michael.riv89",
  ),
];
