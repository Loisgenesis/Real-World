import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:real_world/home.dart';
import 'package:real_world/my_colors.dart';
import 'package:real_world/my_strings.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

class HomeDetail extends StatefulWidget {
  final Data _data;
  HomeDetail(this._data);
  @override
  HomeDetailState createState() => new HomeDetailState();
}

class HomeDetailState extends State<HomeDetail> {
  final refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  var _isRequestSent = true;
  var _isRequestFailed = false;
  var _isRequestConnection = false;
  List<DataDetails> dataDetails = [];
  String errorMessage;
  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          backgroundColor: MyColors.colorPrimary,
          centerTitle: true,
          title: new Text(
           widget._data.videoName,
            style: new TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            new IconButton(
                icon: Icon(Icons.refresh),
                color: Colors.white,
                onPressed: handleRetry)
          ],
        ),
        backgroundColor: Colors.white,
        body: _isRequestSent
            ? _getProgressBar()
            : _isRequestFailed || _isRequestConnection
                ? retryButton()
                : dataDetails.isEmpty
                    ? showNoData()
                    : new SingleChildScrollView(
                        child: getCompleteUI(),
                      ));
  }

  Widget getCompleteUI() {
    return new Column(
      children: dataDetails.map((restAdd) {
        return _getCardItems(restAdd);
      }).toList(),
    );
  }

  Widget _getCardItems(DataDetails data) {
    return new Padding(
      padding: EdgeInsets.all(20.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 200.0,
            child: new CachedNetworkImage(
              imageUrl: data.imageUrl,
              fit: BoxFit.cover,
              placeholder: placeHolder(),
              errorWidget: placeHolder(),
            ),
          ),
          new SizedBox(
            height: 10.0,
          ),
          new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text(
                data.name,
                style:
                    new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
              ),
              new SizedBox(
                height: 10.0,
              ),
              new Text("Duration :${data.duration}"),
              new SizedBox(
                height: 10.0,
              ),
              new Text("Link :${data.link}")
            ],
          )
        ],
      ),
    );
  }

  Widget placeHolder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300],
      highlightColor: Colors.grey[100],
      child: Container(
        height: 200.0,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget showNoData() {
    return Container(
        alignment: Alignment.center,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Text(
              "NO TUTORIAL FOUND",
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            new SizedBox(
              height: 10.0,
            ),
            new FlatButton(
              onPressed: handleRetry,
              color: Colors.orange,
              textColor: Colors.white,
              child: const Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 20.0),
                child: const Text('RETRY'),
              ),
            ),
          ],
        ));
  }

  Widget _getProgressBar() {
    return new ListView(
      padding: EdgeInsets.all(0.0),
      children: <Widget>[
        Container(
          width: double.infinity,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0, 1, 2]
                  .map((_) => Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Container(
                          width: double.infinity,
                          height: 200.0,
                          color: Colors.white,
                        ),
                      ))
                  .toList(),
            ),
          ),
        )
      ],
    );
//    return new Center(
//      child: new Container(
//        width: 50.0,
//        height: 50.0,
//        child: new CircularProgressIndicator(),
//      ),
//    );
  }

  Widget retryButton() {
    return Container(
        alignment: Alignment.center,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Text(
              _isRequestConnection
                  ? Strings.networkError
                  : errorMessage == null || errorMessage.isEmpty
                      ? Strings.sthWentWrg
                      : errorMessage,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            new SizedBox(
              height: 10.0,
            ),
            new FlatButton(
              onPressed: handleRetry,
              color: Colors.orange,
              textColor: Colors.white,
              child: const Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 20.0),
                child: const Text('RETRY'),
              ),
            ),
          ],
        ));
  }

  //this method gets data from api
  void getData() async {
    try {
      var url =
          'https://api.letsbuildthatapp.com/youtube/course_detail?id=${widget._data.id.toString()}';
      http.Response response = await http.post(url);
      List responseMap = json.decode(response.body);
      print(responseMap);
      for (var i = 0; i < responseMap.length; i++) {
        var details = DataDetails.getPostFrmJSONPost(responseMap[i]);
        dataDetails.add(details);
        print(details);
      }

      setState(() {
        _isRequestSent = false;
        _isRequestFailed = false;
      });
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
      _handleRequestError(e);
    }
    return null;
  }

  void _handleRequestError(e) {
    var message;
    if (message is TimeoutException) {
      message = Strings.requestTimeOutMsg;
    }
    if (!mounted) {
      return;
    }
    errorMessage = message ??= Strings.sthWentWrg;
    setState(() {
      _isRequestSent = false;
      _isRequestFailed = false;
      _isRequestConnection = e is SocketException;
    });
  }

  void handleRetry() {
    dataDetails.clear();
    setState(() {
      _isRequestSent = true;
      _isRequestFailed = false;
      _isRequestConnection = false;
    });
    getData();
  }
}

class DataDetails {
  int number;
  String name;
  String duration;
  String imageUrl;
  String link;

  DataDetails(this.number, this.name, this.duration, this.imageUrl, this.link);

  static DataDetails getPostFrmJSONPost(dynamic jsonObject) {
    int number = jsonObject['number'];
    String name = jsonObject['name'];
    String duration = jsonObject['duration'];
    String imageUrl = jsonObject['imageUrl'];
    String link = jsonObject['link'];
    return new DataDetails(number, name, duration, imageUrl, link);
  }

  @override
  String toString() {
    return 'DataDetails{number: $number, name: $name, duration: $duration, imageUrl: $imageUrl, link: $link}';
  }
}
