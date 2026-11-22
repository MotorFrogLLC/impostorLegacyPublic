import funkin.objects.FunkinCaptionGroup;
import funkin.objects.FunkinCaption;
import funkin.objects.TaskSong;

import flixel.text.FlxText;
import flixel.addons.text.FlxTypeText;

import funkin.backend.DebugDisplay;
import funkin.backend.math.Vector3;
import funkin.data.GameFlags;
import funkin.data.ClientPrefs;
import funkin.data.CosmicubeData;
import funkin.utils.ProgressionUtil;

using StringTools;

var flashSprite:FlxSprite;
var reactorFade:Float = 3;
public var dbText:String = '';
public var bfOff:Dynamic = -1;
public var dadOff:Dynamic = -1;
public var showDevInfo:Bool = false;

// Akinator game below vvvvvvvvvvv

/**
 * Can the camera follow who is singing?
**/
public var canFollow:Bool = true;

/**
 * Does your character have a GF skin?
**/
public var hasGfSkin = (ClientPrefs.gfSkin != 'default' && !isStoryMode);

/**
 * Does your character have a BF skin?
**/
public var hasBfSkin = (ClientPrefs.bfSkin != 'default' && !isStoryMode);

/**
 * Does your character have a pet?
**/
public var hasPet = (ClientPrefs.pet != '' && !isStoryMode);

/**
 * Does your character have Colored UI on?
**/
public var hasColor = (ClientPrefs.colorText != 'Disabled');

public var captionGroup:FunkinCaptionGroup;
public var caption:FunkinCaption;

public var taskGroup:TaskSong;

// CAMERA SHIT
var camBopInterval:Int = 4;
var camBopIntensity:Float = 1;
var twistAmount:Float = 1;
var camTwistIntensity:Float = 0;
var camTwistIntensity2:Float = 3;
var camTwist:Bool = false;

function onLoad()
{
	taskGroup = new funkin.objects.TaskSong(0, 200);
	switchCredits();
	
	captionGroup = new FunkinCaptionGroup(500);
	captionGroup.camera = camOther;
}

function onCreatePost()
{
	modifyGUI();
	
	if (!ClientPrefs.inDevMode) return;
	
	var WATERMARK:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/pause/looksie_extreme_demon'));
	WATERMARK.camera = camOther;
	WATERMARK.alpha = 0.3;
	WATERMARK.setPosition((FlxG.width - WATERMARK.width), (FlxG.height - WATERMARK.height));
	add(WATERMARK);
	
	DebugDisplay.addPlugin(() -> ('[ TAB to hide or show debug menu ]' + (showDevInfo ? dbText : '')));
}

function onCountdownStarted():Void startTaskSong(false);

public function switchCredits(infoName:String = 'info'):Void taskGroup.meta = TaskSong.getMeta(songName, infoName);
public function startTaskSong(revive:Bool = true):Void
{
	if (revive) taskGroup.revive();
	
	add(taskGroup);
	taskGroup.start();
	taskGroup.cameras = [camOther];
}

/**
	* Used for the weird camera thing all stage.luas in V4 do.
	** look at this
	* ```haxe
	camSpecialThing([500, 700], [1000, 700], 0.9, 0);
	* ```
**/
public function camSpecialThing(?dad = null, ?bf = null, ?zoom:Float = -1, ?snaptoo:Int = -1)
{
	if (zoom > 0) defaultCamZoom = zoom;
	if (bf != null && bf != -1) bfOff = bf;
	if (dad != null && dad != -1) dadOff = dad;
	if (snaptoo != -1 && snaptoo != null)
	{
		var huh = (snaptoo == 0 ? dad : bf);
		snapCamToPos(huh[0], huh[1]);
	}
}

/**
 * resets the camera positions. not really used considering this mod relies on `camSpecialThing` like oxygen
**/
public function resetCam()
{
	// Reset hardbaked positions for camera
	dadOff = -1;
	bfOff = -1;
}

var doCamFollow:Bool = ClientPrefs.camFollowsCharacters;
function onMoveCamera(whosTurn:Bool)
{
	// CAMERA SPECIAL THING
	if (dadOff == -1 && bfOff == -1) return;
	
	if (camCurTarget == boyfriend) whosTurn = 'boyfriend'; // sure watever i dont care. hmph
	
	if (whosTurn == 'dad')
	{
		camFollow.setPosition(dadOff[0], dadOff[1]);
	}
	else
	{
		camFollow.setPosition(bfOff[0], bfOff[1]);
	}
	
	if (!startingSong && doCamFollow && canFollow)
	{
		var character = (camCurTarget ?? switch (whosTurn)
		{
			case 'gf': gf;
			case 'dad': (opponentStrums?.owner ?? dad);
			default: (playerStrums?.owner ?? boyfriend);
		});
		
		final displacement = character.getSingDisplacement();
		camFollow.x += displacement.x;
		camFollow.y += displacement.y;
	}
}

function modifyGUI()
{
	switch (playHUD.ratingSuffix)
	{
		case '-nuzzus':
			playHUD.ratingScale = 2;
			playHUD.combosScale = 2;
			playHUD.combosPadding = 0;
	}
}

if (ClientPrefs.inDevMode) {
function onUpdate(elapsed)
{
	if (FlxG.keys.justPressed.TAB)
	{
		showDevInfo = !showDevInfo;
		
		if (showDevInfo)
		{
			game.add(dbGroup);
		}
		else
		{
			game.remove(dbGroup, true);
		}
	}
	
	if (showDevInfo)
	{
		dbText = '\nVS IMPOSTOR LEGACY v'
			+ Main.LEGACY_VERSION
			+ '\nHealth: '
			+ game.health
			+ '\nDad Camera, BF Camera:'
			+ [dadOff, bfOff]
			+ '\nCamera Position:'
			+ [camFollow.x, camFollow.y]
			+ ' (zoom: '
			+ defaultCamZoom
			+ ', add: '
			+ defaultCamZoomAdd
			+ ')'
			+ '\nSong Time: '
			+ Conductor.songPosition
			+ ' ('
			+ Math.round(Conductor.songPosition / 1000)
			+ 's)'
			+ '\n'
			+ getBool('Story Mode', PlayState.isStoryMode)
			+ (PlayState.isStoryMode ? getBool('\nIn Cutscene', inCutscene) : '')
			+ '\nQueued Currency (score / 600): '
			+ Std.int(songScore / 600)
			+ '\nCharacters: '
			+ [dad.curCharacter, (gf == null ? null : gf.curCharacter), boyfriend.curCharacter]
			+ '\n'
			+ getBool('Low Quality', ClientPrefs.lowQuality)
			+ getBool(' | Photosensitive', ClientPrefs.photosensitive)
			+ getBool(' | Shaders', ClientPrefs.shaders)
			+ '\nAllocated Notes: '
			+ notes.length;
	}
}

public function getBool(sss:String, bbb:Bool, ?withSlashN:Bool = true):String
{
	return (withSlashN ? '\n' : '') + sss + ': ' + (bbb ? 'ON' : 'OFF');
}
}

function onFirstEventPush(event:EventNote) // I had to add this callback to all scripts it was only being called by event scripts (which makes sense)
{
	switch (event.event)
	{
		case 'Reactor Beep':
			flashSprite = new FlxSprite(0, 0).makeScaledGraphic(1280, 720, 0xFFb30000);
			flashSprite.alpha = 0.001;
			
			if (ClientPrefs.photosensitive)
			{
				flashSprite.camera = camHUD;
				insert(0, flashSprite);
			}
			else
			{
				flashSprite.camera = camOther;
				add(flashSprite);
			}
		case 'Optional Captions':
			prepareCaptions();
	}
}

public function prepareCaptions():Void
{
	if (!ClientPrefs.subtitles || caption != null) return;
	
	add(captionGroup).add(caption = new FunkinCaption());
	caption.visible = false;
}

public function showCaption(string:String, ?y:Float):Void
{
	if (!ClientPrefs.subtitles) return;
	
	prepareCaptions();
	
	caption.set(string, y ?? captionGroup.defaultY);
	caption.visible = true;
	
	if (showDevInfo) trace(caption.text);
}

public function hideCaption():Void
{
	if (caption == null) return;
	
	caption.visible = false;
}

/**
 * If val == '' then return null
**/
public function nullBlank(val)
{
	return val.length == 0 || val.trim() == '';
}

function onEvent(eventName, value1, value2)
{
	switch (eventName)
	{
		case 'Legacy' if (value1 == 'Show Task Song'):
			switchCredits(value2.length > 0 ? value2 : null);
			startTaskSong();
		case 'Optional Captions':
			if (nullBlank(value1) || value1 == '0') return hideCaption();
			
			showCaption(value1, nullBlank(value2) ? null : Std.parseInt(value2));
		case 'Set Cams':
			var coords = value1.split(',');
			var zoomy = Std.parseFloat(value2);
			if (showDevInfo) trace([coords, zoomy]);
			camSpecialThing([coords[0], coords[1]], [coords[2], coords[3]], zoomy);
		case 'Reset Cams':
			resetCam();
		case 'Insta Cam Zoom':
			switch (Std.int(value2))
			{
				default:
					camGame.zoom += Std.parseFloat(value1);
					defaultCamZoom += Std.parseFloat(value1);
				case 1:
					camGame.zoom = Std.parseFloat(value1);
					defaultCamZoom = Std.parseFloat(value1);
			}
		case '_placeholder':
			if (showDevInfo) trace('vs placeholder');
		case 'Reactor Beep':
			if (flashSprite != null)
			{
				FlxTween.cancelTweensOf(flashSprite);
				if (ClientPrefs.photosensitive)
				{
					FlxTween.tween(flashSprite, {alpha: .15}, .2, {ease: FlxEase.sineOut, onComplete: function() FlxTween.tween(flashSprite, {alpha: 0}, .4, {ease: FlxEase.quadInOut})});
				}
				else
				{
					flashSprite.alpha = .3;
					FlxTween.tween(flashSprite, {alpha: 0}, 1 / reactorFade);
				}
			}
			
		case 'Change Character':
			if (hasColor) scoreTxt.color = dad.healthColour == FlxColor.BLACK ? FlxColor.WHITE : dad.healthColour;
		case 'flash':
			var charType = 1;
			if (value1 != null) charType = Std.int(value1);
			// also used for identity crisis idk why dont blame me shrug
			switch (charType)
			{
				case 0, 1:
					camGame.flash(FlxColor.WHITE, 0.35);
				case 2, 3:
					camGame.flash(FlxColor.WHITE, 0.55);
			}
			if (ClientPrefs.photosensitive)
			{
				camGame._fxFlashAlpha *= .5;
				camGame._fxFlashDuration /= .5;
			}
		case 'Extra Cam Zoom':
			var _zoom:Float = Std.parseFloat(value1);
			if (Math.isNaN(_zoom)) _zoom = 0;
			defaultCamZoomAdd = _zoom;
		case 'Camera Twist':
			camTwist = true;
			var _intensity:Float = Std.parseFloat(value1);
			if (Math.isNaN(_intensity)) _intensity = 0;
			var _intensity2:Float = Std.parseFloat(value2);
			if (Math.isNaN(_intensity2)) _intensity2 = 0;
			camTwistIntensity = _intensity;
			camTwistIntensity2 = _intensity2;
			if (_intensity2 == 0)
			{
				camTwist = false;
				FlxTween.tween(camHUD, {scrollAngle: 0}, 1, {ease: FlxEase.sineInOut});
				FlxTween.tween(camGame, {scrollAngle: 0}, 1, {ease: FlxEase.sineInOut});
			}
			
		case 'Alter Camera Bop':
			var _intensity:Float = Std.parseFloat(value1);
			if (Math.isNaN(_intensity)) _intensity = 1;
			var _interval:Int = Std.parseInt(value2);
			if (Math.isNaN(_interval)) _interval = 4;
			
			camZoomingMult = _intensity;
			// gamez = _intensity;
			beatsPerZoom = _interval;
	}
}

function onStepHit()
{
	if (camTwist)
	{
		if (curStep % 4 == 0) FlxTween.tween(camHUD, {y: -6 * camTwistIntensity2}, Conductor.stepCrotchet * 0.002, {ease: FlxEase.circOut});
		else if (curStep % 4 == 2) FlxTween.tween(camHUD, {y: 0}, Conductor.stepCrotchet * 0.002, {ease: FlxEase.sineIn});
	}
}

function onBeatHit()
{
	if (camTwist) // && ClientPrefs.flashing
	{
		var twist:Float = (curBeat % 2 == 0 ? twistAmount : -twistAmount);
		
		camHUD.scrollAngle = camGame.scrollAngle = (twist * camTwistIntensity2);
		
		FlxTween.tween(camGame, {scrollAngle: twist * camTwistIntensity}, Conductor.stepCrotchet * 0.002, {ease: FlxEase.circOut});
		FlxTween.tween(camHUD, {scrollAngle: twist * camTwistIntensity}, Conductor.stepCrotchet * 0.002, {ease: FlxEase.circOut});
		FlxTween.tween(camGame, {x: -twist * camTwistIntensity}, Conductor.crochet * 0.001, {ease: FlxEase.linear});
		FlxTween.tween(camHUD, {x: -twist * camTwistIntensity}, Conductor.crochet * 0.001, {ease: FlxEase.linear});
	}
}
