import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:real_world/home_detail.dart';
import 'package:real_world/my_colors.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:real_world/my_strings.dart';

class Home extends StatefulWidget {
  @override
  HomeState createState() => new HomeState();
}

class HomeState extends State<Home> {
  final refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  var _isRequestSent = true;
  var _isRequestFailed = false;
  var _isRequestConnection = false;
  List<Data> data = [];
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
            Strings.title,
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
                : data.isEmpty
                    ? showNoData()
                    : new SingleChildScrollView(
                        child: getCompleteUI(),
                      ));
  }

  Widget getCompleteUI() {
    return new Column(
      children: data.map((restAdd) {
        return _getCardItems(restAdd);
      }).toList(),
    );
  }

  Widget _getCardItems(Data data) {
    return
      new InkWell(
        onTap: (){
          singlePage(data);
        },
        child: new Padding(
          padding: EdgeInsets.all(20.0),
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                height: 300.0,
                child: new CachedNetworkImage(
                  imageUrl: data.videoImageUrl,
                  fit: BoxFit.cover,
                  placeholder: placeHolder(),
                  errorWidget: placeHolder(),
                ),
              ),
              new SizedBox(
                height: 10.0,
              ),
              new Row(
                children: <Widget>[
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            image: CachedNetworkImageProvider(data.videoImageUrl),
                            fit: BoxFit.cover)),
                  ),
                  new SizedBox(
                    width: 20.0,
                  ),
                  new Expanded(
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new Text(data.videoName,
                            style: new TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 15.0),),
                          new SizedBox(height: 10.0,),
                          new Text("Number of views :${data.noOfViews}")
                        ],
                      ))
                ],
              )
            ],
          ),
        ),
      );
  }
  void singlePage(Data data) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => new HomeDetail(data),
        ));
  }

  Widget placeHolder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300],
      highlightColor: Colors.grey[100],
      child: Container(
        height: 300.0,
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
                          height: 300.0,
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
      const url = "https://api.letsbuildthatapp.com/youtube/home_feed";
      http.Response response = await http.post(url);
      Map<String, dynamic> body = json.decode(response.body);
      //print(body);
      var dat = body["videos"] as List;
      for (var i = 0; i < dat.length; i++) {
        var details = Data.getPostFrmJSONPost(dat[i]);
        var channel = dat[i]["channel"];
        for (var i = 0; i < channel.length; i++) {
          //var chan = channel[i];
          details.channelName = channel['name'];
          details.profileImageUrl = channel['profileImageUrl'];
          details.numberOfSubscribers = channel['numberOfSubscribers'];
        }
        data.add(details);
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
    data.clear();
    setState(() {
      _isRequestSent = true;
      _isRequestFailed = false;
      _isRequestConnection = false;
    });
    getData();
  }
}

class Data {
  int id;
  String videoName;
  String videoLink;
  String videoImageUrl;
  num noOfViews;
  String channelName;
  String profileImageUrl;
  num numberOfSubscribers;

  Data(
      this.id,
      this.videoName,
      this.videoLink,
      this.videoImageUrl,
      this.noOfViews,
      this.channelName,
      this.profileImageUrl,
      this.numberOfSubscribers);

  static Data getPostFrmJSONPost(dynamic jsonObject) {
    int id = jsonObject['id'];
    String videoName = jsonObject['name'];
    String videoLink = jsonObject['link'];
    String videoImageUrl = jsonObject['imageUrl'];
    num noOfViews = jsonObject['numberOfViews'];
    String channelName;
    String profileImageUrl;
    num numberOfSubscribers;
    return new Data(id, videoName, videoLink, videoImageUrl, noOfViews,
        channelName, profileImageUrl, numberOfSubscribers);
  }

  @override
  String toString() {
    return 'Data{id: $id, videoName: $videoName, videoLink: $videoLink, videoImageUrl: $videoImageUrl, noOfViews: $noOfViews,channelName: $channelName, profileImageUrl: $profileImageUrl, numberOfSubscribers: $numberOfSubscribers}';
  }
}
