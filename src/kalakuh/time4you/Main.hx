package kalakuh.time4you;

import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import kalakuh.time4you.game.EGameMode;
import kalakuh.time4you.game.GameManager;
import kalakuh.time4you.upgrades.Shop;
import openfl.media.SoundChannel;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.Assets;
import openfl.events.Event;
import kalakuh.time4you.menus.*;
import kalakuh.time4you.gui.*;
import openfl.media.Sound;

#if flash
	import kalakuh.time4you.gui.GameContextMenu;
#end

/**
 * ...
 * @author Kalakuh
 */

class Main extends Sprite 
{
	private var inited : Bool;
	private var mainMenu : MainMenu;
	private var credits : Credits;
	private var help : Help;
	private var mSelection : ModeSelection;
	private var game : GameManager;
	private var gOver : GameOver;
	private var shop : Shop;
	private static var menuSound : Sound;
	private static var gameSound : Sound;
	private static var channel : SoundChannel;
	private static var songID : UInt = 0;
	
	#if flash
		private static var kongregate : KongregateAPI;
	#end	
	
	/* ENTRY POINT */
	
	function resize(e) 
	{
		if (!inited) init();
		// else (resize or orientation change)
	}
	
	function init() 
	{
		if (inited) return;
		inited = true;
		
		// (your code here)
		mainMenu = new MainMenu();
		addChild(mainMenu);
		
		menuSound = Assets.getSound("sound/DarknessOfForever.mp3");
		gameSound = Assets.getSound("sound/Test-Taker's Nightmare.mp3");
		channel = menuSound.play(0, 9999); // ... me iz too lazy to do better system
		songID = 0;
		
		Saving.init();
		
		#if flash
			contextMenu = GameContextMenu.getContextMenu();
			kongregate = new KongregateAPI();
		#end
		
		addEventListener(Event.ENTER_FRAME, update);
	}
	
	private function update (e : Event) : Void {
		// Q: Could the function be inlined?
		// A: Obviously not :(
		
		// main menu
		if (mainMenu != null) {
			if (mainMenu.isDestroyable()) {
				if (mainMenu.alpha < 0.1) {
					mainMenu.onDestroy();
					removeChild(mainMenu);
					mainMenu = null;
				}
			}
		}
		
		// credits
		if (credits != null) {
			if (credits.isDestroyable()) {
				if (credits.alpha < 0.1) {
					credits.onDestroy();
					removeChild(credits);
					credits = null;
				}
			}
		}
		
		// help
		if (help != null) {
			if (help.isDestroyable()) {
				if (help.alpha < 0.1) {
					help.onDestroy();
					removeChild(help);
					help = null;
				}
			}
		}
		
		// mode selection
		if (mSelection != null) {
			if (mSelection.isDestroyable()) {
				if (mSelection.alpha < 0.1) {
					mSelection.onDestroy();
					removeChild(mSelection);
					mSelection = null;
				}
			}
		}
		
		// game over
		if (gOver != null) {
			if (gOver.isDestroyable()) {
				if (gOver.alpha < 0.1) {
					gOver.onDestroy();
					removeChild(gOver);
					gOver = null;
				}
			}
		}
		
		// game
		if (game != null) {
			if (game.isDestroyable()) {
				if (game.alpha < 0.1) {
					game.onDestroy();
					removeChild(game);
					game = null;
				}
			}
		}
		
		// shop
		if (shop != null) {
			if (shop.isDestroyable()) {
				if (shop.alpha < 0.1) {
					shop.onDestroy();
					removeChild(shop);
					shop = null;
				}
			}
		}
	}
	
	public function openMenu (menu : EScreen) : Void {
		switch (menu) {
			case EScreen.S_MainMenu:
				if (songID != 0) {
					channel.stop();
					channel = menuSound.play(0, 9999);
					songID = 0;
				}
				mainMenu = new MainMenu();
				mainMenu.alpha = 0;
				addChild(mainMenu);
			case EScreen.S_Credits:
				credits = new Credits();
				credits.setTargetAlpha(1);
				addChild(credits);
			case EScreen.S_Help:
				help = new Help();
				help.setTargetAlpha(1);
				addChild(help);
			case EScreen.S_ModeSelection:
				mSelection = new ModeSelection();
				mSelection.setTargetAlpha(1);
				addChild(mSelection);
			case EScreen.S_Shop:
				shop = new Shop();
				shop.setTargetAlpha(1);
				addChild(shop);
			default:
		}
	}
	
	public function gameOver (score : Float, gamemode : EGameMode) : Void {
		Saving.setCoins(Saving.getCoins() + cast(score, UInt));
		gOver = new GameOver();
		addChild(gOver);
		gOver.setTargetAlpha(1);
		gOver.setScore(score, gamemode);
	}
	
	public function startGame (gamemode : EGameMode) : Void {
		if (songID != 1) {
			channel.stop();
			channel = gameSound.play(0, 9999);
			songID = 1;
		}
		game = new GameManager();
		addChild(game);
		game.setTargetAlpha(1);
		game.start(gamemode);
	}
	
	public function restart () : Void {
		game = new GameManager();
		addChild(game);
		game.setTargetAlpha(1);
		game.start();
	}

	/* SETUP */

	public function new() 
	{
		super();	
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	function added(e) 
	{
		removeEventListener(Event.ADDED_TO_STAGE, added);
		stage.addEventListener(Event.RESIZE, resize);
		
		#if ios
			haxe.Timer.delay(init, 100); // iOS 6
		#else
			init();
		#end
	}
	
	public static function main() 
	{
		// static entry point
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}
	
	#if flash
	public static function getAPI () : KongregateAPI {
		return kongregate;
	}
	#end
	
	public static function mute () : Void {
		channel.stop();
	}
	
	public static function unmute () : Void {
		channel = songID == 0 ? menuSound.play(0, 9999) : gameSound.play(0, 9999);
	}
}