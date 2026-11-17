package funkin.utils;

import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

import lime.ui.Gamepad as LimeGamepad;
import lime.ui.GamepadAxis as LimeGamepadAxis;
import lime.ui.GamepadButton as LimeGamepadButton;

/**
 * Utilities for working with Flixel gamepads.
 */
class FlxGamepadUtil
{
	// FLX_GAMEINPUT_API internally assigns 6 axes to IDs 0-5, which LimeGamepadButton doesn't account for, so we need to offset the ID by 6.
	public static final BUTTON_OFFSET:Int = 6;
	
	/**
	 * Resolves Flixel input ID from a Lime gamepad button ID
	 * @param	gamepad		Flixel gamepad
	 * @param	button		Lime button ID
	 */
	public static inline function getButtonInputID(gamepad:FlxGamepad, button:LimeGamepadButton):FlxGamepadInputID
	{
		return (gamepad.mapping.getID(button + BUTTON_OFFSET) ?? NONE);
	}
	
	/**
	 * Resolves Flixel input ID from a Lime gamepad axis ID and value
	 * @param	gamepad		Flixel gamepad
	 * @param	button		Lime axis ID
	 * @param	x			Axis value
	 */
	public static inline function getAxisInputID(gamepad:FlxGamepad, axis:LimeGamepadAxis, x:Float):FlxGamepadInputID
	{
		return switch (axis)
		{
			case LEFT_X: (x < 0 ? LEFT_STICK_DIGITAL_LEFT : LEFT_STICK_DIGITAL_RIGHT);
			case LEFT_Y: (x < 0 ? LEFT_STICK_DIGITAL_UP : LEFT_STICK_DIGITAL_DOWN);
			
			case RIGHT_X: (x < 0 ? RIGHT_STICK_DIGITAL_LEFT : RIGHT_STICK_DIGITAL_RIGHT);
			case RIGHT_Y: (x < 0 ? RIGHT_STICK_DIGITAL_UP : RIGHT_STICK_DIGITAL_DOWN);
			
			default: gamepad.mapping.getID(cast axis);
		};
	}
	
	/**
	 * Resolves Lime gamepad from a Flixel gamepad instance
	 * @param	gamepad		Lime gamepad
	 */
	public static function getLimeGamepad(gamepad:FlxGamepad):Null<LimeGamepad>
	{
		return @:privateAccess
		{
			final gamepadDevice:openfl.ui.GameInputDevice = gamepad?._device;
			
			for (gamepad => device in openfl.ui.GameInput.__devices) if (device == gamepadDevice) return gamepad;
			
			return null;
		}
	}
	
	/**
	 * Resolves Flixel gamepad from a Lime gamepad instance
	 * @param	gamepad		Flixel gamepad
	 */
	public static function getFlxGamepadByLimeGamepad(gamepad:LimeGamepad):FlxGamepad // well this isnt used now but what freaking ever
	{
		@:privateAccess
		{
			var gameInputDevice:openfl.ui.GameInputDevice = openfl.ui.GameInput.__getDevice(gamepad);
			var gamepadIndex:Int = FlxG.gamepads.findGamepadIndex(gameInputDevice);
			
			return FlxG.gamepads.getByID(gamepadIndex);
		}
	}
}
