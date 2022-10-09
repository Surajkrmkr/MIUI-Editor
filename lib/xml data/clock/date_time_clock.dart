const hourClockXml = '''
		<Image name="hour" scale="1.1" srcExp="'hour/hour_'+ int((#hour12)) +'.png'" width="#sw" height="#sh"/>
''';

const minClockXml = '''
		<Image name="min" scale="1.1" srcExp="'min/min_'+ int((#minute)) +'.png'" width="#sw" height="#sh"/>
''';

const dotClockXml = '''
		<Image name="dot" scale="1.1" srcExp="'dot/dot.png'" width="#sw" height="#sh"/>
''';

const weekClockXml = '''
		<Image name="week" scale="1.1" srcExp="'week/week_'+ int((#day_of_week-1)) +'.png'" width="#sw" height="#sh"/>
''';

const monthClockXml = '''
		<Image name="month" scale="1.1" srcExp="'month/month_'+ int((#month+1)) +'.png'" width="#sw" height="#sh"/>
''';

const dateClockXml = '''
		<Image name="date" scale="1.1" srcExp="'date/date_'+ int((#date)) +'.png'" width="#sw" height="#sh"/>
''';
