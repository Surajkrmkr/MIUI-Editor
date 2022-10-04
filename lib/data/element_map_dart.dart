
import 'package:flutter/material.dart';

import 'time/clock.dart';

enum ElementType { verticalClock, horizontalClock }

final Map<ElementType,Widget> elementWidgetMap = {
    ElementType.verticalClock: const VerticalClock(),
    ElementType.horizontalClock: const HorizontalClock(),
};

