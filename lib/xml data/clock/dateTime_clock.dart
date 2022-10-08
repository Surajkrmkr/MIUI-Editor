const hourClockXml = '''
		<Image name="hour" x="#sw/2" y="#sh/2" srcExp="'hour/hour_'+ int((#hour12)) +'.png'" align="center" alignV="center" width="#sw" height="#sh"/>
''';


const minClockXml = '''
		<Image name="min" x="#sw/2" y="#sh/2" srcExp="'min/min_'+ int((#minute)) +'.png'" align="center" alignV="center" width="#sw" height="#sh"/>
''';

const dotClockXml = '''
		<Image name="dot" x="#sw/2" y="#sh/2" srcExp="'dot/dot.png'" align="center" alignV="center" width="#sw" height="#sh"/>
''';

const weekClockXml = '''
		<Image name="week" x="#sw/2" y="#sh/2" srcExp="'week/week_'+ int((#day_of_week-1)) +'.png'" align="center" alignV="center" width="#sw" height="#sh"/>
''';

const monthClockXml = '''
		<Image name="month" x="#sw/2" y="#sh/2" srcExp="'month/month_'+ int((#month+1)) +'.png'" align="center" alignV="center" width="#sw" height="#sh"/>
''';

const dateClockXml = '''
		<Image name="date" x="#sw/2" y="#sh/2" srcExp="'date/date_'+ int((#date)) +'.png'" align="center" alignV="center" width="#sw" height="#sh"/>
''';