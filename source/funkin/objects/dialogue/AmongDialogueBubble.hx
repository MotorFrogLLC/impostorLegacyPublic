package funkin.objects.dialogue;

using StringTools;

import flixel.addons.text.FlxTypeText;
import flixel.util.FlxSignal;

@:access(flixel.text.FlxText)
@:access(flixel.addons.text.FlxTypeText)
class AmongDialogueBubble extends flixel.group.FlxSpriteGroup
{
	public var bubble:FunkinSprite;
	
	public var icon:HealthIcon;
	public var title:FlxText;
	
	public var dialogue:FlxTypeText;
	public var displayDialogue:FlxText;
	var rtlWrapMeasure:FlxText;
	
	public var targetText:String = 'scientists';
	public var onType:FlxTypedSignal<(text:String, i:Int, length:Int) -> Void> = new FlxTypedSignal();
	public var onFinish:FlxTypedSignal<(text:String) -> Void> = new FlxTypedSignal();
	
	var arabicFix:Bool = Lang.hasSpecial('rightToLeft');
	
	public function new(x:Float = 0, y:Float = 0, character:String = 'unknown', iconName:String = 'unknown', rightToLeft:Bool = false)
	{
		super(x, y);
		
		final align:FlxTextAlign = (rightToLeft ? FlxTextAlign.RIGHT : FlxTextAlign.LEFT);
		
		bubble = cast new FunkinSprite().loadGraphic(Paths.image('ui/dialogue/bubble'));
		
		icon = new HealthIcon(iconName, rightToLeft);
		icon.setGraphicSize(Std.int(icon.width * 0.7));
		@:privateAccess icon.updateOffset = false;
		icon.updateHitbox();
		icon.x = (rightToLeft ? bubble.width - icon.width - 15 : 15);
		
		title = new FlxText(70, 5, bubble.width - 140, Lang.str(character, character), 28);
		title.setFormat(Paths.font('liberbold.ttf'), Lang.hasSpecial('smallerDialogue') ? 20 : 30, FlxColor.WHITE, align, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.borderSize = 2;
		
		dialogue = new FlxTypeText(70, 36, Std.int(bubble.width - 140), '', 28);
		dialogue.setFormat(Paths.font('liber.ttf'), 26, FlxColor.BLACK, align);
		dialogue._defaultFormat.leading = (Lang.getFlag('dialogueLeading') ?? 0);
		dialogue.updateDefaultFormat();
		dialogue.alpha = 0;
		
		dialogue.x += (rightToLeft ? -50 : 50);
		title.x = dialogue.x;
		
		displayDialogue = new FlxText(dialogue.x, dialogue.y, dialogue.fieldWidth, '', 28);
		displayDialogue.setFormat(Paths.font('liber.ttf'), 26, FlxColor.BLACK, align);
		displayDialogue._defaultFormat.leading = (Lang.getFlag('dialogueLeading') ?? 0);
		displayDialogue.textField.wordWrap = true;
		displayDialogue.textField.multiline = true;
		displayDialogue.updateDefaultFormat();
		
		rtlWrapMeasure = new FlxText(0, 0, dialogue.fieldWidth, '', 28);
		rtlWrapMeasure.setFormat(Paths.font('liber.ttf'), 26, FlxColor.BLACK, align);
		rtlWrapMeasure.textField.multiline = true;
		rtlWrapMeasure.textField.wordWrap = true;
		
		add(bubble);
		add(icon);
		add(title);
		add(displayDialogue);
	}
	
	var _unclipped:Bool = true;
	public function clipTo(y:Float):Void
	{
		if (y < 0)
		{
			if (_unclipped) return;
			
			_unclipped = true;
		}
		else
		{
			_unclipped = false;
		}
		
		for (member in members)
		{
			member.clipRect ??= flixel.math.FlxRect.get();
			
			member.clipRect.y = Math.max(0, y / member.scale.y);
			member.clipRect.setSize(member.frameWidth, member.frameHeight);
		}
	}
	
	var _prevText:String;
	public override function update(elapsed:Float):Void
	{
		dialogue.update(elapsed);
		super.update(elapsed);
		
		if (dialogue.text != _prevText)
		{
			if (arabicFix)
			{
				var ftLen = dialogue.text.length;
				if (ftLen > 0)
				{
					if (ftLen > dialogue._finalText.length) ftLen = targetText.length;
					
					var startIndex = (targetText.length - ftLen);
					if (startIndex < 0) startIndex = 0;
					
					displayDialogue.text = formatArabicDialogueText(targetText.substring(startIndex));
					Lang.arabicTextFix(displayDialogue);
				}
				else
				{
					displayDialogue.text = '';
				}
			}
			else
			{
				displayDialogue.text = dialogue.text;
			}
			
			onType.dispatch(displayDialogue.text, dialogue.text.length, targetText.length);
			if (dialogue.text.length == targetText.length) onFinish.dispatch(displayDialogue.text);
			
			_prevText = dialogue.text;
		}
	}
	
	public function play(line:String):Void
	{
		dialogue.resetText(targetText = Lang.str(line, line));
		dialogue.start(.05, true);
	}
	
	function formatArabicDialogueText(source:String):String
	{
		if (source == null || source.length < 1 || rtlWrapMeasure == null) return source;
		
		var wrappedLines:Array<String> = [];
		for (paragraph in source.split("\n"))
		{
			if (paragraph.trim().length < 1)
			{
				wrappedLines.push("");
				continue;
			}
			
			var words = paragraph.split(" ");
			var currentLine:String = "";
			for (i in 0...words.length)
			{
				var word = words[words.length - 1 - i];
				var candidate = (currentLine.length > 0) ? (word + " " + currentLine) : word;
				rtlWrapMeasure.text = candidate;
				if (currentLine.length > 0 && rtlWrapMeasure.textField.numLines > 1)
				{
					wrappedLines.unshift(currentLine);
					currentLine = word;
				}
				else currentLine = candidate;
			}
			wrappedLines.unshift(currentLine);
		}
		
		rtlWrapMeasure.text = '';
		return wrappedLines.join("\n");
	}
}
