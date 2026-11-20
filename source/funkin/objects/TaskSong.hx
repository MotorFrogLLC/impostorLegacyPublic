package funkin.objects;

import flixel.group.FlxSpriteGroup;

class TaskSong extends FlxSpriteGroup
{
	public var text(default, set):String;
	public var meta(default, set):Array<String> = ['ME', 'I MADE THE SONG'];
	
	public var fontSize:Int = 24;
	public var borderPadding:Float = 12;
	
	public var bg:FlxSprite = new FlxSprite();
	public var metaGroup:FlxSpriteGroup = new FlxSpriteGroup();
	
	var startX:Float;

	public function new(x:Float, y:Float, text:String = '')
	{
		super(startX = x, y);
		
		bg.alpha = .3;
		bg.makeGraphic(1, 1, FlxColor.WHITE);
		
		add(bg);
		add(metaGroup);
		
		this.text = text;
	}

	public function start():Void
	{
		if (meta.length == 0 || !alive) return;
		
		reload(meta);
		
		x = (startX - width);
		FlxTween.cancelTweensOf(this);
		FlxTween.tween(this, {x: startX}, 1, {ease: FlxEase.quintInOut, onComplete: (_) -> FlxTween.tween(this, {x: startX - width}, 1, {ease: FlxEase.quintInOut, startDelay: 2})});
	}
	
	function reload(meta:Array<String>):Void
	{
		metaGroup.setPosition(x + borderPadding, y + borderPadding);
		metaGroup.group.killMembers();
		
		var w:Float = 0, h:Float = 0;
		for (i => string in text.split('\n'))
		{
			final text:FlxText = cast metaGroup.recycle(FlxText, () -> new FlxText().setFormat(Paths.font(i == 0 ? 'liberbold.ttf' : 'liber.ttf'), fontSize, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK));
			final yy:Float = (i * 30);
			
			text.setPosition(metaGroup.x, metaGroup.y + yy);
			text.text = string;
			
			w = Math.max(text.width, w);
			h = (yy + text.height);
		}
		
		bg.setGraphicSize(w + borderPadding * 2, h + borderPadding * 2);
		bg.updateHitbox();
	}
	
	public static function getMeta(song:String, infoName:String = 'info'):Array<String>
	{
		final meta:Array<String> = CoolUtil.coolTextFile(Paths.getPath('songs/${Paths.sanitize(song)}/$infoName.txt', NORMAL));
		
		return (meta.length == 0 ? null : meta);
	}
	
	function set_text(now:String):String
	{
		if (text == now) return now;
		
		reload(@:bypassAccessor meta = now.split('\n'));
		
		return now;
	}
	function set_meta(now:Array<String>):Array<String>
	{
		@:bypassAccessor text = (meta = (now ?? [])).join('\n');
		
		reload(meta);
		
		return meta;
	}
}
