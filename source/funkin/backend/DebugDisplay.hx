package funkin.backend;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;

import flixel.util.FlxStringUtil;
import flixel.FlxG;

import insanity.custom.InsanityType;

/**
 * enum that handles the display type of the FPS counter.
 */
enum abstract FpsDisplayMode(Int) to Int {
	var DISABLED;
	var FPS;
	var SIMPLE;
	var ADVANCED;
	
	public static inline function fromString(str:String):FpsDisplayMode
	{
		return switch (str.toLowerCase())
		{
			case 'advanced': ADVANCED;
			case 'simple': SIMPLE;
			case 'fps': FPS;
			default: DISABLED;
		}
	}
}

/**
 * A FL Sprite that displays the current FPS and GC memory
 */
@:nullSafety
class DebugDisplay extends Sprite
{
	public static var instance:Null<DebugDisplay> = null;
	
	/**
	 * Creates a DebugDisplay instance
	 * 
	 * Use after your FlxGame is initiated.
	 */
	public static function init()
	{
		if (FlxG.game?.parent == null || instance != null) return;
		
		instance = new DebugDisplay(10, 3, 0xFFFFFF);
		instance.visible = (instance.displayType != FpsDisplayMode.DISABLED);
		
		FlxG.game.parent.addChild(instance);
	}
	
	/**
	 * The visualized text showing the current fps
	 */
	final textField:TextField;
	
	/**
	 * The bg for the text
	 */
	final textUnderlay:Bitmap;
	
	/**
	 * If disabled, the fps counter will no longer update visually
	 */
	var canUpdate:Bool = true;
	
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int = 0;
	
	/**
		The current memory usage of the garbage collector.
	**/
	public var gcMemory(get, never):Float;
	
	/**
	 * The current memory usage of the entire program.
	 * 
	 * Only supported on `Windows` currently
	 */
	public var taskMemory(get, never):Float;
	
	public var displayType:Int = FpsDisplayMode.SIMPLE;
	
	public var plugins:Array<Void->Null<String>> = [];
	
	var times:Array<Float> = [];
	
	var deltaTimeout:Float = 0.0;
	
	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();
		
		textUnderlay = new Bitmap();
		textUnderlay.bitmapData = new BitmapData(1, 1, true, 0x6F000000);
		
		final textFormat = new TextFormat(Paths.font('aller.ttf'), 14, color);
		textFormat.leading = 5;
		
		textField = new TextField();
		textField.selectable = false;
		textField.mouseEnabled = false;
		textField.defaultTextFormat = textFormat;
		textField.autoSize = LEFT;
		textField.text = "";
		
		displayType = FpsDisplayMode.fromString(ClientPrefs.fpsDisplayType);
		
		addChild(textUnderlay);
		addChild(textField);
		
		this.x = x;
		this.y = y;
	}
	
	public static function addPlugin(fun:Void->String):Void->Null<String>
	{
		if (instance == null || instance.plugins.contains(fun)) return fun;
		
		instance.plugins.push(fun);
		
		return fun;
	}
	
	// Event Handlers
	override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = Lib.getTimer();
		times.push(now);
		while (times[0] < now - 1000) times.shift();
			
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 100)
		{
			deltaTimeout += deltaTime;
			return;
		}
		
		currentFPS = times.length;
		updateText();
		textUnderlay.width = (textField.textWidth + 6);
		textUnderlay.height = (textField.textHeight + 1);
		
		deltaTimeout = 0.0;
	}
	
	// rebind this function to set a custom fps counter
	public dynamic function updateText():Void
	{
		__updateText();
	}
	
	var _state:Null<flixel.FlxState> = null;
	var stateName:String = '';
	
	@:nullSafety(Off) // die
	function __updateText()
	{
		displayType = FpsDisplayMode.fromString(ClientPrefs.fpsDisplayType);
		visible = (displayType != DISABLED);
		
		if (!canUpdate) return;
		
		switch (displayType)
		{
			case DISABLED: return;
				
			case FPS #if (!cpp) | SIMPLE #end:
				textField.text = '$currentFPS FPS';
				
			#if cpp
			case SIMPLE:
				textField.text = '$currentFPS FPS  ·  ${FlxStringUtil.formatBytes(taskMemory)}';
			#end
				
			case ADVANCED:
				var str:String = ('$currentFPS FPS  ·  ${FlxStringUtil.formatBytes(gcMemory)} gc' #if cpp + '  ·  ${FlxStringUtil.formatBytes(taskMemory)} task' #end);
				
				if (FlxG.state != null && _state != FlxG.state)
				{
					if (FlxG.state is funkin.scripting.ScriptedState)
					{
						var scripted:funkin.scripting.ScriptedState = cast (_state = FlxG.state);
						var path:String = funkin.scripts.FunkinScript.getPath('scripts/states/${scripted.scriptName}');
						#if ASSET_REDIRECT path = path.replace(Paths.trail, ''); #end
						stateName = 'ScriptedState · (${path.replace('scripts/states/', '../../')})';
					}
					else
					{
						stateName = InsanityType.getClassName(InsanityType.getClass(_state = FlxG.state));
					}
				}
				
				str += '  ·  $stateName';
				
				for (fun in plugins)
				{
					try
					{
						final pluginStr:Null<String> = fun();
						
						if (pluginStr != null && pluginStr.length > 0) str += '\n$pluginStr';
					}
					catch (e)
					{
						Logger.log('Error on debug display plugin: $e', ERROR, true);
						
						plugins.remove(fun);
					}
				}
				
				textField.text = str;
				
			default:
		}
	}
	
	inline function get_gcMemory():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#elseif hl
		return hl.Gc.stats().currentMemory;
		#else
		return (cast openfl.system.System.totalMemoryNumber : UInt);
		#end
	}
	
	inline function get_taskMemory():Float
	{
		return external.Native.getTaskMemory();
	}
}
