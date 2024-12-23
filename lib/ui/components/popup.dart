import 'package:flutter/material.dart';
import 'package:counter/ui/_constant/theme/devcoop_text_style.dart';
import 'package:counter/ui/_constant/component/button.dart';

AlertDialog popUp(BuildContext context, String message) {
  return AlertDialog(
    title: Text(
      message,
      style: DevCoopTextStyle.bold_40,
    ),
    actions: <Widget>[
      mainTextButton(
        text: "확인",
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/');
        },
      )
    ],
  );
}
