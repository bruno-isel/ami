import 'package:flutter/material.dart';

const kPrimaryBlue = Color(0xFF007AFF);
const kCategoryWork = Color(0xFF007AFF);
const kCategoryPersonal = Color(0xFFFF9500);

const kWorkListId = 'work';
const kPersonalListId = 'personal';

const kHintBarText =
    'Hold to reorder  ·  Swipe to delete  ·  Shake for options';

const double kShakeThreshold = 20.0;
const int kShakeWindowMs = 800;

const Duration kAnimDuration = Duration(milliseconds: 300);
const Duration kUndoTimeout = Duration(seconds: 5);
