package funkin.game.huds;

class ImpostorHUD extends PsychHUD
{
	public var tintScore:Bool = (ClientPrefs.colorText != 'Disabled');
	public var tintCombo:Bool = (ClientPrefs.colorText == 'Enabled DX');
	
	override function init()
	{
		super.init();
		
		timeTxt.setPosition(108, 25);
		timeTxt.setFormat(Paths.font('vcr.ttf', false), 14, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		if (ClientPrefs.downScroll) timeTxt.y = (FlxG.height - timeTxt.y - timeTxt.height + 2);
		
		timeBar.setColors(0xff44d844, 0xff2e412e);
		timeBar.setPosition(timeTxt.x - 11, timeTxt.y - 2);
		
		ratingPop = 1.12;
		combosPop = 1.06; // i guess bro!
	}
	
	public override function popUpScore(ratingImage:String, combo:Int):Void
	{
		if (ClientPrefs.hideHud) return;
		
		super.popUpScore(ratingImage, combo);
		
		if (tintCombo)
		{
			if (showRating) ratingGraphic.color = scoreTxt.color;
			
			if (showRatingNum)
			{
				for (numScore in ratingNumGroup)
				{
					if (numScore.alive) numScore.color = scoreTxt.color;
				}
			}
		}
	}
	
	public override function reloadHealthBarColors():Void
	{
		super.reloadHealthBarColors();
		
		if (tintScore) scoreTxt.color = parent.dad.healthColour;
	}
}
