import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

int _byteLength(String value) => utf8.encode(value).length;

InputCounterWidgetBuilder buildCountersFor(String currentValue) =>
    (context, {required currentLength, required isFocused, maxLength}) => Text(
          maxLength != null ? '${_byteLength(currentValue)}/$maxLength' : '',
          style: Theme.of(context).textTheme.caption,
        );

TextInputFormatter limitBytesLength(int maxByteLength) =>
    TextInputFormatter.withFunction((oldValue, newValue) {
      final newLength = _byteLength(newValue.text);
      if (newLength <= maxByteLength) {
        return newValue;
      }
      return oldValue;
    });
