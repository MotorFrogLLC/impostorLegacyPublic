import funkin.objects.dialogue.AmongDialogue;

// Dialogue softcode!
public var hasDialogue:Bool = false;

/**
 * Debug cutscene testing.
**/
public var repeatedCutscenes:Bool = false;

/**
 * other thingies
**/
public var videoCheckStory:Bool = true;

public var skippableVideo:Bool = true;
public var video:FunkinVideoSprite;
public var skipText:FlxText; // skip video text

var vidPlaying:Bool = false;

var bg:flixel.system.FlxBGSprite;
public var dialogue:AmongDialogue;

function onLoad()
{
	final PADDING = 15;
	skipText = new FlxText(PADDING, 0, FlxG.width - PADDING * 2, Lang.str('video_skip'));
	skipText.setFormat(Paths.font("liberbold.ttf"), 25, FlxColor.WHITE, Lang.hasSpecial('rightToLeft') ? 'right' : 'left', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	skipText.borderSize = 2;
	skipText.y = FlxG.height - skipText.height - (PADDING * (3 / 4));
	skipText.zIndex = 12;
}

function onVidEnd()
{
	hideCaption();
	
	video?.destroy();
	inCutscene = false;
	vidPlaying = false;
	camGame.visible = true;
	skipText.visible = false;
	// ^ for windowed fullscreen
	if (hasDialogue && (PlayState.isStoryMode || !videoCheckStory))
	{
		readDialogue();
	}
	else
	{
		startCountdown();
	}
	
	if (blackYnot != null) FlxTween.tween(blackYnot, {alpha: 0}, 0.5, {onComplete: function() blackYnot.kill()});
}

function prepareDialogue(?dialogueName:String)
{
	if ((videoCheckStory && !isStoryMode) || PlayState.seenCutscene) return false;
	
	final data:Array<String> = AmongDialogue.getDialogueData(songName, dialogueName);
	if (data == null) return false;
	
	hasDialogue = true;
	
	dialogue = new AmongDialogue();
	dialogue.setPosition(Math.round((FlxG.width - dialogue.box.width) / 2), 430);
	dialogue.queueFromData(data);
	
	final dialoguePath:String = ('dialogue/' + Paths.sanitize(songName));
	
	if (funkin.FunkinAssets.exists(Paths.getPath('music/$dialoguePath.ogg', null, PathsTestMode.NORMAL)))
	{
		FlxG.sound.playMusic(Paths.music(dialoguePath));
		FlxG.sound.music.volume = 0;
	}
	else
	{
		FlxG.sound.music?.destroy();
		FlxG.sound.music = null;
	}
	
	return true;
}

/**
	* Loads a video cutscene basically.
	`vid` > what video
	`hold on a second`
**/
public function videoCutscene(?vid:String = 'sussus-moogus', ?dialogueName:Dynamic, canSkip:Bool = true, ?onEnd:Void->Void, ?onFormat:Void->Void)
{
	if ((videoCheckStory && !isStoryMode) || PlayState.seenCutscene) return;
	
	if (dialogue == null || dialogue.queue.length == 0) prepareDialogue(dialogueName is String ? dialogueName : null);
	
	songStartCallback = function() {}
	
	skippableVideo = canSkip; // fuck you hscript
	
	blackYnot = new FlxSprite().makeScaledGraphic(FlxG.width + 3, FlxG.height, FlxColor.BLACK);
	blackYnot.camera = camOther;
	add(blackYnot);
	
	#if VIDEOS_ALLOWED
	video = new FunkinVideoSprite();
	
	video.onFormat(() -> {
		inCutscene = true;
		vidPlaying = true;
		video.camera = camOther;
		video.setGraphicSize(0, FlxG.height);
		video.antialiasing = ClientPrefs.globalAntialiasing;
		video.updateHitbox();
		video.screenCenter();
		camGame.visible = false;
		// ^ for windowed fullscreen
		textFade();
	});
	
	add(video);
	
	if (onEnd != null) video.onEnd(onEnd);
	if (onFormat != null) video.onFormat(onFormat);
	video.onEnd(onVidEnd);
	
	if (video.load(Paths.video(Paths.sanitize(vid))))
	{
		video.delayAndStart();
	}
	else
	#end
	{
		if (onEnd != null) onEnd();
		onVidEnd();
	}
}

public function textFade()
{
	if (!skippableVideo) return;
	
	skipText.visible = true;
	skipText.alpha = 0;
	FlxTween.tween(skipText, {alpha: .5}, 2, {ease: FlxEase.sineInOut});
	FlxTween.tween(skipText, {alpha: 0}, 3, {startDelay: 4, ease: FlxEase.sineInOut});
	
	skipText.camera = camOther;
	add(skipText);
}

/** 
 * Run this function to read the songs/SONG_NAME/dialogue.txt file
**/
public function readDialogue()
{
	if ((videoCheckStory && !isStoryMode) || PlayState.seenCutscene) return;
	
	if (!repeatedCutscenes) PlayState.seenCutscene = true;
	
	if (dialogue == null || dialogue.queue.length == 0 && !prepareDialogue(dialogueName is Bool ? dialogueName : null)) return;
	
	songStartCallback = function() {}
	inCutscene = true;
	
	bg = new flixel.system.FlxBGSprite();
	bg.alpha = 0;
	
	bg.cameras = [camOther];
	dialogue.cameras = [camOther];
	
	dialogue.onFinish.add(closeDialogue);
	dialogue.onCancel.add(closeDialogue);
	
	add(bg);
	
	FlxTween.tween(bg, {alpha: .35}, .8, {ease: FlxEase.circIn});
	
	if (FlxG.sound.music != null)
	{
		FlxG.sound.music.fadeIn(1, 0, .8);
		FlxG.sound.music.play();
	}
	
	FlxTimer.wait(.5, function()
	{
		dialogue.advance();
		dialogue.y += 700;
		add(dialogue);
		
		FlxTween.tween(dialogue, {y: dialogue.y - 700}, .5, {ease: FlxEase.expoOut});
	});
}

function closeDialogue():Void
{
	FlxTween.tween(bg, {alpha: 0}, .25, {ease: FlxEase.circIn});
	FlxTween.tween(dialogue, {y: dialogue.y + 700}, .25, {ease: FlxEase.circIn, onComplete: function(_)
	{
		dialogue.destroy();
		dialogue = null;
	}});
	
	FlxG.sound.music?.stop();
	FlxG.sound.play(Paths.sound('panelDisappear'), .5);
	
	inCutscene = false;
	startCountdown();
}

function onUpdate(elapsed)
{
	if (vidPlaying)
	{
		if (ClientPrefs.inDevMode)
		{
			if (controls.UI_RIGHT_P) video.time = Math.min(video.time + 5, video.length);
			if (controls.UI_LEFT_P) video.time = Math.min(video.time - 5, 0);
		}
		
		if (controls.BACK && skippableVideo)
		{
			video.kill();
			video.bitmap.onEndReached.dispatch();
		}
	}
}
