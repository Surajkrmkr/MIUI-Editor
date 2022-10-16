const hourClockXml = '''
		<Image name="hour" srcExp="'hour/hour_'+ int((#hour12)) +'.png'" width="#sw" height="#sh"/>
''';

const minClockXml = '''
		<Image name="min" srcExp="'min/min_'+ int((#minute)) +'.png'" width="#sw" height="#sh"/>
''';

const dotClockXml = '''
		<Image name="dot" srcExp="'dot/dot.png'" width="#sw" height="#sh"/>
''';

textLineClockXml({String? textName, String? color, String? size}) => '''
		<DateTime x="#sw/2" y="#sh/2" align="center" alignV="center" size="$size" color="$color" formatExp="'$textName'" fontFamily="mitype-light" />
''';

const weekClockXml = '''
		<Image name="week" srcExp="'week/week_'+ int((#day_of_week-1)) +'.png'" width="#sw" height="#sh"/>
''';

const monthClockXml = '''
		<Image name="month" srcExp="'month/month_'+ int((#month+1)) +'.png'" width="#sw" height="#sh"/>
''';

const dateClockXml = '''
		<Image name="date" srcExp="'date/date_'+ int((#date)) +'.png'" width="#sw" height="#sh"/>
''';

const amClockXml = '''
		<Image name="ampm" srcExp="'ampm/ampm_'+ int((#ampm)) +'.png'" width="#sw" height="#sh"/>
''';

const weatherIconClockXml = '''
		<Image name="weatherIcon" srcExp="'weather/weather_'+ int((#date)) +'.png'" width="#sw" height="#sh"/>
''';