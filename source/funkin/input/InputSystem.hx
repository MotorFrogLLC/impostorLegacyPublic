package funkin.input;

using funkin.utils.FlxGamepadUtil;

import funkin.input.Controls;

import flixel.util.FlxSignal;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

import openfl.events.KeyboardEvent;

import lime.ui.Gamepad as LimeGamepad;
import lime.ui.GamepadButton;
import lime.ui.GamepadAxis;
import lime.system.System;

typedef AxisEvent = (id:GamepadAxis, x:Float) -> Void;
typedef GamepadEvent = (id:GamepadButton) -> Void;

/**
 * An `InputSystem` object tracks note inputs with events
 * You can add listeners to check for when an input is pressed and released
 * ```haxe
 * input = new InputSystem();
 * input.addEventListener(InputEvent.INPUT_PRESSED, onInputPressed);
 * input.addEventListener(InputEvent.INPUT_RELEASED, onInputReleased);
 * ```
 * Input events can also be cancelled
 * ```haxe
 * function onInputPressed(event:InputEvent)
 * {
 *  if (badInput)
 *      event.cancel();
 * }
 * ```
 */
class InputSystem implements flixel.util.IFlxDestroyable extends openfl.events.EventDispatcher
{
	/**
	 * The list of actions checked for, in order of their note direction
	 */
	public static final ACTION_LIST:Array<Action> = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];
	
	/**
	 * The current controls instance used for this input system
	 */
	public var controls:funkin.input.Controls;
	
	/**
	 * Array of all actions and whether they're currently pressed or not
	 */
	public var active:Array<Bool> = [];
	
	/**
	 * Key binds attached to this input system
	 */
	public var keyBinds:Array<Array<FlxKey>> = [];
	/**
	 * Gamepad binds attached to this input system
	 */
	public var gamepadBinds:Array<Array<flixel.input.gamepad.FlxGamepadInputID>> = [];
	
	var gamepads:Array<FlxGamepad> = [];
	
	/**
	 * Creates a new input system
	 * @param controls 
	 */
	public function new(controls:Controls)
	{
		super();
		
		this.controls = controls;
		this.populate(ACTION_LIST);
		
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyboardInput);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyboardInput);
		
		for (i in 0 ... FlxG.gamepads.numActiveGamepads) hookGamepad(FlxG.gamepads.getByID(i));
		
		FlxG.gamepads.deviceConnected.add(hookGamepad);
		FlxG.gamepads.deviceDisconnected.add(unhookGamepad);
	}
	function populate(actionList:Array<Action>):Void
	{
		active = [for (_ in actionList) false];
		keyBinds = [for (_ in actionList) []];
		gamepadBinds = [for (_ in actionList) []];
		
		for (noteData => action in actionList)
		{
			for (input in this.controls.actions.get(action).inputs)
			{
				switch (input.device)
				{
					case KEYBOARD: keyBinds[noteData].push(input.inputID);
					case GAMEPAD: gamepadBinds[noteData].push(input.inputID);
					default:
				}
			}
		}
		
		trace(gamepadBinds);
	}
	
	/**
	 * Checks if a note direction is pressed
	 * @param noteData 
	 */
	public inline function inputPressed(noteData:Int):Bool
	{
		return active[noteData];
	}
	
	/**
	 * Checks if any note direction is pressed
	 */
	public inline function anyPressed():Bool
	{
		return active.contains(true);
	}
	
	var gamepadEvents:Map<FlxGamepad, {onButtonDown:GamepadEvent, onButtonUp:GamepadEvent, onAxisMove:AxisEvent}> = [];
	var gamepadDigital:Map<FlxGamepad, Map<GamepadAxis, Int>> = [];
	function hookGamepad(gamepad:FlxGamepad):Void
	{
		final limeGamepad:LimeGamepad = gamepad.getLimeGamepad();
		if (limeGamepad == null) return trace('oh');
		
		final blob = {
			onButtonDown: function(button:GamepadButton) onGamepadInput(gamepad, button, true),
			onButtonUp: function(button:GamepadButton) onGamepadInput(gamepad, button, false),
			onAxisMove: function(axis:GamepadAxis, x:Float) onGamepadAxisMove(gamepad, axis, x)
		};
		limeGamepad.onButtonDown.add(blob.onButtonDown);
		limeGamepad.onButtonUp.add(blob.onButtonUp);
		limeGamepad.onAxisMove.add(blob.onAxisMove);
		
		gamepadDigital.set(gamepad, [LEFT_X => 0, LEFT_Y => 0, RIGHT_X => 0, RIGHT_Y => 0, TRIGGER_LEFT => 0, TRIGGER_RIGHT => 0]);
		gamepadEvents.set(gamepad, blob);
		gamepads.push(gamepad);
	}
	function unhookGamepad(gamepad:FlxGamepad):Void
	{
		final limeGamepad:LimeGamepad = gamepad.getLimeGamepad();
		if (limeGamepad == null) return;
		
		final blob = gamepadEvents.get(gamepad);
		limeGamepad.onButtonDown.remove(blob?.onButtonDown);
		limeGamepad.onButtonUp.remove(blob?.onButtonUp);
		limeGamepad.onAxisMove.remove(blob?.onAxisMove);
		
		gamepadDigital.remove(gamepad);
		gamepadEvents.remove(gamepad);
		gamepads.remove(gamepad);
	}
	
	function getBindFromKey(key:FlxKey):Int
	{
		for (i in 0 ... keyBinds.length) if (keyBinds[i]?.contains(key)) return i;
		
		return -1;
	}
	function getBindFromButton(button:FlxGamepadInputID):Int
	{
		for (i in 0 ... gamepadBinds.length) if (gamepadBinds[i]?.contains(button)) return i;
		
		return -1;
	}
	
	inline function doInput(bind:Int, down:Bool, device:Device, inputID:Int, timer:Float):Void
	{
		if (bind < 0) return;
		
		if (active[bind] != down) {
			active[bind] = down;
			
			dispatchEvent(new InputEvent(down ? InputEvent.INPUT_PRESSED : InputEvent.INPUT_RELEASED, false, true, bind, device, inputID, System.getTimer()));
		}
	}
	inline function onKeyboardInput(event:KeyboardEvent):Void
	{
		doInput(getBindFromKey(event.keyCode), event.type == KeyboardEvent.KEY_DOWN, Keys, event.keyCode, System.getTimer());
	}
	inline function onGamepadInput(gamepad:FlxGamepad, button:GamepadButton, down:Bool):Void
	{
		final butt = gamepad.getButtonInputID(button);
		doInput(getBindFromButton(butt), down, Gamepad(gamepad.id), cast butt, System.getTimer());
	}
	inline function onGamepadAxisMove(gamepad:FlxGamepad, axis:GamepadAxis, x:Float):Void
	{
		final digital = gamepadDigital.get(gamepad);
		final butt = gamepad.getAxisInputID(axis, digital.get(axis));
		
		if (Math.abs(x) > gamepad.deadZone)
		{
			if (digital.get(axis) != 0 && !FlxMath.sameSign(x, digital.get(axis))) doInput(getBindFromButton(butt), false, Gamepad(gamepad.id), cast butt, System.getTimer());
			
			digital.set(axis, FlxMath.signOf(x));
			
			final butt = gamepad.getAxisInputID(axis, digital.get(axis));
			doInput(getBindFromButton(butt), true, Gamepad(gamepad.id), cast butt, System.getTimer());
		}
		else if (digital.get(axis) != 0)
		{
			doInput(getBindFromButton(butt), false, Gamepad(gamepad.id), cast butt, System.getTimer());
			
			digital.set(axis, 0);
		}
	}
	
	public function destroy():Void
	{
		FlxG.gamepads.deviceConnected.remove(hookGamepad);
		FlxG.gamepads.deviceDisconnected.remove(unhookGamepad);
		
		while (gamepads.length > 0) unhookGamepad(gamepads[0]);
		
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyboardInput);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyboardInput);
	}
}
