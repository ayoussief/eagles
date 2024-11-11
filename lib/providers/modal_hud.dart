import 'package:flutter/material.dart';

class ModalHud extends ChangeNotifier
{
  bool isLoading = false;

  changeisLoading(bool value)
  {
    isLoading = value;
    notifyListeners();
  }
}