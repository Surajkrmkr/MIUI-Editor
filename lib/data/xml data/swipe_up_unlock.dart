const swipeUpUnlockXml = '''
  <Unlocker name="unlocker" visibility="not(#unlocker_v)">
    <StartPoint x="0" y="0" w="#sw" h="#sh" easeType="BounceEaseOut" easeTime="400"/>
    <EndPoint x="0" y="-#sh" w="#sw" h="#sh - 400">
      <Path x="0" y="0" tolerance="2000">
        <Position x="0" y="0"/>
        <Position x="0" y="-#sh"/>
      </Path>
    </EndPoint>
	</Unlocker>
''';

