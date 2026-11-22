package funkin.objects.dialogue;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSignal;

typedef AmongDialogueLine = {
	var line:String;
	var character:String;
	var ?expression:String;
	var ?rightToLeft:Bool;
}

class AmongDialogue extends FlxSpriteGroup
{
	public var boxBack:FunkinSprite;
	public var box:funkin.objects.RGBSprite;
	
	public var logGroup:FlxTypedSpriteGroup<AmongDialogueBubble> = new FlxTypedSpriteGroup();
	public var characters:AmongDialogueCharacterGroup = new AmongDialogueCharacterGroup();
	public var currentSpeaker:AmongDialogueCharacter;
	
	public var bubbleY:Float = 55;
	public var bubblePadding:Float = 10;
	
	public var queue:Array<AmongDialogueLine> = [];
	
	public var onAdvance:FlxTypedSignal<(line:AmongDialogueLine, character:AmongDialogueCharacter) -> Void> = new FlxTypedSignal();
	public var onFinish:FlxTypedSignal<Void -> Void> = new FlxTypedSignal();
	public var onCancel:FlxTypedSignal<Void -> Void> = new FlxTypedSignal();
	public var canInput:Bool = true;
	public var curBubble:Int = -1;
	
	var rtl:Bool = Lang.hasSpecial('rightToLeft');
	
	var controls:funkin.input.Controls;
	
	public function new()
	{
		super();
		
		controls = funkin.input.Controls.instance;
		
		boxBack = cast new FunkinSprite().loadGraphic(Paths.image('ui/dialogue/dialogueBoxBack'));
		box = cast new funkin.objects.RGBSprite().loadGraphic(Paths.image('ui/dialogue/dialogueBox'));
		box.rgbGraphics.setColors([0xffff1515, 0xffffffff, 0xff7d0058]);
		characters.x = Math.round(box.x + box.width * .5);
		
		add(characters);
		add(boxBack);
		add(logGroup);
		add(box);
	}
	
	function getBubbleOffset(i:Int):Float
	{
		return (logGroup.members[0].y - logGroup.members[i].y + (Math.min(FlxG.height, y + box.height) - logGroup.y - bubbleY - logGroup.members[curBubble].height) * .5);
	}
	
	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (FlxG.mouse.justPressed && FlxG.mouse.y >= box.y)
		{
			for (i => bubble in logGroup.members)
			{
				if (!FlxG.mouse.overlaps(bubble.bubble)) continue;
				
				scroll(i - curBubble);
				break;
			}
		}
		
		var yy:Float = (logGroup.y + bubbleY);
		
		if (curBubble == logGroup.length - 1)
		{
			var lastBubble = logGroup.members[logGroup.length - 1];
			yy = (Math.min(box.y + box.height - bubbleY, FlxG.height) - logGroup.height - bubblePadding);//Math.min(logGroup.y + logGroup.height, FlxG.height);
		}
		else if (curBubble > 0)
		{
			yy += getBubbleOffset(curBubble);
		}
		
		for (bubble in logGroup.members)
		{
			if (yy > FlxG.height && bubble.y > FlxG.height) break;
			
			final bubbleHeight:Float = Math.max(bubble.displayDialogue.height + bubble.displayDialogue.y - bubble.y + 15, bubble.bubble.height);
			
			bubble.y = MathUtil.decayLerp(bubble.y, yy, 25, elapsed);
			
			bubble.bubble.scale.y = MathUtil.decayLerp(bubble.bubble.scale.y, bubbleHeight / bubble.bubble.frameHeight, 25, elapsed);
			bubble.bubble.updateHitbox();
			
			yy += (bubbleHeight + bubblePadding);
			
			bubble.clipTo(logGroup.y - bubble.y + 5);
		}
		
		if (canInput)
		{
			if (controls.UI_UP_P || FlxG.mouse.wheel > 0) scroll(-1);
			if (controls.UI_DOWN_P || FlxG.mouse.wheel < 0) scroll(1);
			
			if (curBubble == -1)
			{
				if (controls.ACCEPT) if (advance()) FlxG.sound.play(Paths.sound('clickText'), .8);
				
				if (controls.BACK) cancel();
			}
			
			if (controls.ACCEPT || controls.BACK)
			{
				if (curBubble >= 0)
				{
					logGroup.members[curBubble].bubble.color = FlxColor.WHITE;
					curBubble = -1;
				}
			}
		}
	}
	
	public function queueFromData(data:Array<String>, preload:Bool = true):Void
	{
		for (line in data)
		{
			var info:Array<String> = line.split(':');
			info.shift();
			
			queueLine({
				character: info[0],
				expression: info[1],
				line: info[2]
			});
			
			if (preload) characters.preload(info[0]);
		}
	}
	
	public function queueLine(line:AmongDialogueLine):AmongDialogueLine
	{
		queue.push(line);
		
		if (logGroup.length == 0) advance();
		
		return line;
	}
	
	public function scroll(mod:Int = 0):Void
	{
		if (curBubble >= 0) logGroup.members[curBubble].bubble.color = FlxColor.WHITE;
		
		curBubble += mod;
		
		if (curBubble < 0) curBubble = 0;
		if (curBubble >= logGroup.length) curBubble = (logGroup.length - 1);
		
		logGroup.members[curBubble].bubble.color = FlxColor.LIME;
	}
	
	@:access(flixel.addons.text.FlxTypeText)
	public function advance(force:Bool = false):Bool
	{
		if (!force && logGroup.length > 0 && logGroup.members[0].dialogue._typing)
		{
			logGroup.members[0].dialogue.skip();
			return false;
		}
		
		for (bubble in logGroup) bubble.active = false;
		
		var line:AmongDialogueLine = queue.shift();
		
		if (line == null)
		{
			finish();
			return true;
		}
		
		speak(line.character, line.expression);
		
		if (line.line != null) addBubble(line.line, currentSpeaker.titleName, currentSpeaker.icon, line.rightToLeft);
		
		if (onAdvance != null) onAdvance.dispatch(line, currentSpeaker);
		
		if (line.line == null) return advance();
		
		return true;
	}
	
	public function finish():Void
	{
		canInput = false;
		
		if (onFinish != null) onFinish.dispatch();
	}
	
	public function cancel():Void
	{
		canInput = false;
		
		if (onCancel != null) onCancel.dispatch();
	}
	
	public function speak(character:String, ?expression:String):AmongDialogueCharacter
	{
		currentSpeaker = characters.show(character);
		currentSpeaker.playAnim(expression, true);
		currentSpeaker.speaking = true;
		
		box.rgbGraphics.r = currentSpeaker.boxColor;
		box.rgbGraphics.g = currentSpeaker.boxLightColor;
		box.rgbGraphics.b = currentSpeaker.boxShadeColor;
		
		return currentSpeaker;
	}
	
	public function addBubble(line:String = 'Hello world!', dialogueName:String = 'red', iconName:String = 'red', ?rightToLeft:Bool):AmongDialogueBubble
	{
		var speaker:AmongDialogueCharacter = currentSpeaker;
		
		final bubble:AmongDialogueBubble = logGroup.insert(0, new AmongDialogueBubble(92, bubbleY - 5, dialogueName, iconName, rightToLeft ?? rtl));
		bubble.play(line);
		
		bubble.dialogue.sounds = currentSpeaker.sounds;
		bubble.dialogue.completeCallback = () -> speaker.speaking = false;
		
		return bubble;
	}
	
	public static function getDialogueData(song:String, dialogueName:String = 'dialogue'):Array<String>
	{
		final meta:Array<String> = CoolUtil.coolTextFile(Paths.getPath('songs/${Paths.sanitize(song)}/$dialogueName.txt', NORMAL));
		
		return (meta.length == 0 ? null : meta);
	}
}
