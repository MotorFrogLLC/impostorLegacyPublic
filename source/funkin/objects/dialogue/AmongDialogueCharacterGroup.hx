package funkin.objects.dialogue;

class AmongDialogueCharacterGroup extends flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup<AmongDialogueCharacter>
{
	public var map:Map<String, AmongDialogueCharacter> = [];
	public var activeCharacters:Map<Int, AmongDialogueCharacter> = [];
	
	public var sideOffsets:Map<Int, FlxPoint> = [
		0 => FlxPoint.get(-320, 0),
		1 => FlxPoint.get(0, 0),
		2 => FlxPoint.get(320, 0),
	];
	public var transitionOffsets:Map<Int, FlxPoint> = [
		0 => FlxPoint.get(-50, 0),
		1 => FlxPoint.get(0, 50),
		2 => FlxPoint.get(50, 0),
	];
	
	public function preload(character:String):AmongDialogueCharacter
	{
		if (map.exists(character)) return map.get(character);
		
		var char:AmongDialogueCharacter = new AmongDialogueCharacter(character);
		map.set(character, char);
		
		add(char);
		char.alpha = .0001;
		
		return char;
	}
	
	public function show(character:String):AmongDialogueCharacter
	{
		var char:AmongDialogueCharacter = preload(character);
		
		char.revive();
		char.setPosition(x, y + 30);
		
		var offset:FlxPoint = sideOffsets.get(char.side);
		if (offset != null)
		{
			char.x += offset.x;
			char.y += offset.y;
		}
		
		char.x -= Math.round(char.width / 2);
		char.y -= char.height;
		
		char.x += char.positionOffset.x;
		char.y += char.positionOffset.y;
		
		var current:AmongDialogueCharacter = activeCharacters.get(char.side);
		
		activeCharacters.set(char.side, char);
		sort(SortUtil.sortByZ);
		
		if (current != char)
		{
			transition(current, false);
			transition(char, true);
		}
		
		return char;
	}
	
	public function transition(character:AmongDialogueCharacter, transIn:Bool = true):Void
	{
		if (character == null) return;
		
		var targetX:Null<Float> = null, targetY:Null<Float> = null;
		
		var offset:FlxPoint = (character.transitionOffset ?? transitionOffsets.get(character.side) ?? FlxPoint.weak(0, 50));
		if (offset != null)
		{
			if (transIn)
			{
				if (offset.x != 0) targetX = character.x;
				if (offset.y != 0) targetY = character.y;
				
				character.x += offset.x;
				character.y += offset.y;
			}
			else
			{
				if (offset.x != 0) targetX = (character.x + offset.x);
				if (offset.y != 0) targetY = (character.y + offset.y);
			}
		}
		
		if (transIn) character.alpha = 0;
		
		var a:Dynamic = {alpha: (transIn ? 1 : 0)};
		if (targetX != null) a.x = targetX;
		if (targetY != null) a.y = targetY;
		
		FlxTween.cancelTweensOf(character);
		FlxTween.tween(character, a, .5, {ease: FlxEase.quadInOut});
	}
}
