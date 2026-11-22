package funkin.objects.dialogue;

typedef AmongDialogueCharacterFile =
{
	var side:Int;
	var name:String;
	var icon:String;
	var asset:String;
	var sound:Dynamic;
	
	var ?zIndex:Int;
	var ?flipX:Bool;
	var ?scale:Float;
	var ?no_antialiasing:Bool;
	
	var ?offsets:Array<Float>;
	var ?transitionOffset:Array<Float>;
	
	var ?boxColor:Dynamic;
	var ?boxLightColor:Dynamic;
	var ?boxShadeColor:Dynamic;
	
	var animations:Array<AmongDialogueCharacterAnim>;
}

typedef AmongDialogueCharacterAnim =
{
	var anim:String;
	var name:String;
	var loop:Bool;
	var ?fps:Int;
	var ?reset:Bool;
	var offsets:Array<Int>;
}

class AmongDialogueCharacter extends FunkinSprite
{
	public var curCharacter:String = 'unknown';
	public var data:AmongDialogueCharacterFile;
	
	public var titleName:String = '???';
	public var icon:String = 'unknown';
	
	public var side:Int = 1;
	public var positionOffset:FlxPoint = FlxPoint.get();
	public var transitionOffset:Null<FlxPoint> = null;
	
	public var boxColor:FlxColor;
	public var boxLightColor:FlxColor;
	public var boxShadeColor:FlxColor;
	
	public var speaking:Bool = false;
	public var sounds:Array<FlxSound> = [];
	
	public function new(character:String)
	{
		super();
		
		loadCharacter(character);
		
		animation.onFinish.add((anim:String) -> if (hasAnim('$anim-loop')) playAnim('$anim-loop', true));
		animation.onLoop.add((anim:String) -> {
			if (speaking) return;
			
			if (animation.exists('$anim-loop'))
			{
				animation.play('$anim-loop', true);
			}
			else
			{
				animation.pause();
			}
		});
	}
	
	public function loadCharacter(file:String, force:Bool = false):AmongDialogueCharacter
	{
		if (curCharacter == file && !force) return this;
		
		final path:String = Paths.getPath('data/dialogue/$file.json', null, PathsTestMode.NORMAL);
		data = (FunkinAssets.exists(path) ? FunkinAssets.parseJson5(FunkinAssets.getContent(path)) : null);
		
		if (data == null) return this;
		
		curCharacter = file;
		
		return loadFile(data);
	}
	
	public function loadFile(data:AmongDialogueCharacterFile):AmongDialogueCharacter
	{
		icon = data.icon;
		side = data.side;
		titleName = data.name;
		zIndex = (data.zIndex ?? switch(side)
		{
			case 0: 10;
			case 1: 0;
			case 2: 15;
			default: 5;
		});
		
		if (data.offsets != null) positionOffset.set(data.offsets[0], data.offsets[1]);
		if (data.transitionOffset != null) transitionOffset = FlxPoint.get(data.transitionOffset[0], data.transitionOffset[1]);
		
		boxColor = (data.boxColor is String ? FlxColor.fromString(data.boxColor) : (Std.parseInt(data.boxColor) ?? FlxColor.RED));
		boxLightColor = (data.boxLightColor is String ? FlxColor.fromString(data.boxLightColor) : (Std.parseInt(data.boxLightColor) ?? FlxColor.WHITE));
		boxShadeColor = (data.boxShadeColor is String ? FlxColor.fromString(data.boxShadeColor) : (Std.parseInt(data.boxShadeColor) ?? FlxColor.BLUE));
		
		loadAtlas('ui/dialogue/characters/${data.asset}');
		
		flipX = (data.flipX ?? false);
		if (data.scale != null) scale.set(data.scale, data.scale);
		if (data.no_antialiasing != null) antialiasing = !data.no_antialiasing;
		
		sounds.resize(0);
		if (data.sound is String)
		{
			sounds.push(FlxG.sound.load(Paths.sound('dialogue/${data.sound}'), .6));
		}
		else if (data.sound != null)
		{
			var sound:Array<String> = cast data.sound;
			for (sound in sound) sounds.push(FlxG.sound.load(Paths.sound('dialogue/$sound'), .6));
		}
		
		for (anim in data.animations)
		{
			if (anim.loop)
			{
				addOffset('${anim.anim}-loop', anim.offsets[0], anim.offsets[1]);
				addAnimByPrefix('${anim.anim}-loop', anim.name, anim.fps ?? 24, true);
			}
			
			addAnimByPrefix(anim.anim, anim.name, anim.fps ?? 24, anim.reset ?? true);
			addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			
			if (animation.curAnim == null) playAnim(anim.anim, true);
		}
		
		updateHitbox();
		
		return this;
	}
	
	public override function destroy():Void
	{
		super.destroy();
		
		positionOffset.put();
		transitionOffset?.put();
	}
}
