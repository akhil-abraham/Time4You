package kalakuh.time4you.game;

import kalakuh.time4you.gui.Screen;
import kalakuh.time4you.Main;
import kalakuh.time4you.gui.EScreen;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.filters.GlowFilter;
import openfl.geom.Point;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import openfl.utils.Timer;
import openfl.events.TimerEvent;
import openfl.media.Sound;
import kalakuh.time4you.upgrades.EUpgrade;

/**
 * ...
 * @author Kalakuh
 */

class GameManager extends Screen
{
	private var background : Bitmap;
	
	private var player : Player;
	private var deathSound : Sound;
	
	private var score : Counter;
	private var rush : Counter;
	private var rushTimer : Timer;
	
	private var keysDown : Array<UInt> = new Array();
	
	private var pixelsMoved : Float = 0;
	
	private var enemySpawnCounter : Float;
	private var enemies : Array<Enemy>;
	
	private var powerSpawnCounter : Float = 3000 - (Saving.getUpgradeLevel(EUpgrade.Spawn) * 100);
	private var powers : Array<PowerUp>;
	
	private var collectedCoins : UInt = 0;
	private var coin : Coin;
	private var oldCoin : Coin;
	
	private var stamina : StaminaBar;
	
	private var glow : SlowMotionGlow;
	
	private static var gamemode : EGameMode = EGameMode.Classic;
	
	private var slowmoSound : Sound;
	private var coinSound : Sound;
	private var powerSound : Sound;
	
	private var doubleCounter : UInt = 0;
	
	private var alive : Bool = false;
	
	private var scoreNumb : Float = 0;
	
	private var volume : Volume;
	
	public function new() 
	{
		super(0);
		
		addEventListener(Event.ADDED_TO_STAGE, init);
	}
	
	private function init (e : Event) : Void {
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		background = new Bitmap(Assets.getBitmapData("img/In-Game/GameBackground.png"));
		addChild(background);
		
		coin = new Coin();
		addChild(coin);
		
		enemies = new Array();
		
		powers = new Array();
		
		player = new Player();
		addChild(player);
		
		deathSound = Assets.getSound("sound/death.mp3");
		slowmoSound = Assets.getSound("sound/slowmo.mp3");
		coinSound = Assets.getSound("sound/coin.mp3");
		powerSound = Assets.getSound("sound/power.mp3");
		
		stamina = new StaminaBar();
		addChild(stamina);
		
		glow = new SlowMotionGlow();
		addChild(glow);
		
		volume = new Volume();
		addChild(volume);
		volume.x = stage.stageWidth - 50;
		volume.y = 50;
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}
	
	private function onKeyDown (e : KeyboardEvent) : Void {
		if (keysDown.indexOf(e.keyCode) == -1 && alive) {
			keysDown.push(e.keyCode);
			if (e.keyCode == Keyboard.SPACE && stamina.getStamina() > 0) {
				if (player.getSpeed() > 0.1) {
					slowmoSound.play();
				}
			}
		}
	}
	
	private function onKeyUp (e : KeyboardEvent) : Void {
		keysDown.remove(e.keyCode);
	}
	
	public function start (gm : EGameMode = null) : Void {
		player.x = stage.stageWidth / 2;
		player.y = stage.stageHeight / 2;
		player.resetSpeed();
		
		alive = true;
		
		if (oldCoin != null) {
			removeChild(oldCoin);
			oldCoin = null;
		}
		
		if (gm != null) {
			gamemode = gm;
		}
		
		if (gamemode == EGameMode.Rush) {
			rush = new Counter();
			addChild(rush);
			rush.setValue(30);
			rushTimer = new Timer(1000, 30);
			rushTimer.addEventListener(TimerEvent.TIMER, updateTimer);
			rushTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timerComplete);
			rushTimer.start();
		} else if (gamemode == EGameMode.Classic || gamemode == EGameMode.Storm) {
			score = new Counter();
			addChild(score);
			score.setValue(0);
		}
		
		coin.newPosition();
		
		stamina.reset();
		
		collectedCoins = 0;
		enemySpawnCounter = 400;
		pixelsMoved = 0;
		
		for (enemy in enemies) {
			removeChild(enemy);
			enemy = null;
		}
		enemies.splice(0, enemies.length);
		
		player.setAlive(true);
		
		if (gamemode == EGameMode.Storm) {
			enemySpawnCounter = 100;
		}
		
		addEventListener(Event.ENTER_FRAME, update);
	}
	
	private function updateTimer (e : TimerEvent) : Void {
		rush.setValue(rush.getValue() - 1);
	}
	
	private function timerComplete (e : TimerEvent) : Void {
		if (alive) {
			super.setTargetAlpha(0);
			var main : Main = cast parent;
			main.gameOver(scoreNumb, gamemode);
			player.setAlive(false);
			alive = false;
			deathSound.play();
			removeEventListener(Event.ENTER_FRAME, update);
			super.setToBeDestroyed();
		}
	}
	
	private function update (e : Event) : Void {
		if (gamemode == EGameMode.Classic || gamemode == EGameMode.Storm) {
			score.setTargetAlpha(1);
		} else if (gamemode == EGameMode.Rush) {
			rush.setTargetAlpha(1);
		}
		
		if (doubleCounter > 0) {
			doubleCounter--;
			if (coin != null) coin.filters = [new GlowFilter(0x7788FF, 1, 6, 6, 3, 3)];
			if (oldCoin != null) oldCoin.filters = [new GlowFilter(0x7788FF, 1, 6, 6, 3, 3)];
		} else {
			if (coin != null) coin.filters = [];
			if (oldCoin != null) oldCoin.filters = [];
		}
		
		stamina.setTargetAlpha(0.8);
		volume.setTargetAlpha(1);
		
		// update player's speed
		if (keysDown.indexOf(Keyboard.UP) != -1 || keysDown.indexOf(Keyboard.W) != -1) {
			player.addSpeed(0, -0.4);
		}
		if (keysDown.indexOf(Keyboard.DOWN) != -1 || keysDown.indexOf(Keyboard.S) != -1) {
			player.addSpeed(0, 0.4);
		}
		if (keysDown.indexOf(Keyboard.LEFT) != -1 || keysDown.indexOf(Keyboard.A) != -1) {
			player.addSpeed(-0.4, 0);
		}
		if (keysDown.indexOf(Keyboard.RIGHT) != -1 || keysDown.indexOf(Keyboard.D) != -1) {
			player.addSpeed(0.4, 0);
		}
		
		var pSpeed : Float = player.getSpeed();
		// slow mo'
		var slowmo : Bool = false;
		
		if (keysDown.indexOf(Keyboard.SPACE) != -1) {
			if (stamina.getStamina() > 0) {
				if (pSpeed > 1) {
					slowmo = true;
					stamina.setStamina(stamina.getStamina() - 1);
				}
			}
		}
		
		if (slowmo) {
			glow.setTargetAlpha(1);
		} else {
			glow.setTargetAlpha(0);
		}
		
		pixelsMoved += pSpeed * (slowmo ? 0.5 - (0.03 * Saving.getUpgradeLevel(EUpgrade.SlowMo)) : 1);
		powerSpawnCounter -= pSpeed * (slowmo ? 0.5 - (0.03 * Saving.getUpgradeLevel(EUpgrade.SlowMo)) : 1);
		if (powerSpawnCounter <= 0) {
			powerSpawnCounter = 2500 + Math.random() * 1000 - (Saving.getUpgradeLevel(EUpgrade.Spawn) * 100);
			var power : PowerUp;
			// TODO
			if (Math.random() < 1.0 / 3.0) {
				power = new PowerUp(EPowerUp.Shrink);
			} else if (Math.random() < 1.0 / 2.0) {
				power = new PowerUp(EPowerUp.Invincibility);
			} else {
				power = new PowerUp(EPowerUp.Double);
			}
			
			addChild(power);
			powers.push(power);
		}
		
		// update enemy spawn counter & spawn enemies
		if (pixelsMoved >= enemySpawnCounter) {
			pixelsMoved %= enemySpawnCounter;
			
			if (gamemode != EGameMode.Storm) {
				enemySpawnCounter -= enemySpawnCounter / 40;
			} else {
				enemySpawnCounter -= 0.2;
			}
			
			var enemy : Enemy;
			if (scoreNumb < 3 && gamemode != EGameMode.Storm) { 
				enemy = new Enemy(EEnemy.Triangle);
			} else if (scoreNumb < 9 && gamemode != EGameMode.Storm) {
				if (Math.random() < 0.5) {
					enemy = new Enemy(EEnemy.Triangle);
				} else {
					if (Math.random() < 0.5) {
						enemy = new Enemy(EEnemy.Pentagon);
					} else {
						enemy = new Enemy(EEnemy.Star);
					}
				}
			} else {
				if (Math.random() < 1.0 / 7.0) {
					enemy = new Enemy(EEnemy.Triangle);
				} else if (Math.random() < 1.0 / 6.0) {
					enemy = new Enemy(EEnemy.Star);
				} else if (Math.random() < 1.0 / 5.0) {
					enemy = new Enemy(EEnemy.Pentagon);
				} else if (Math.random() < 1.0 / 4.0) {
					enemy = new Enemy(EEnemy.Missile);
				} else if (Math.random() < 1.0 / 3.0) {
					enemy = new Enemy(EEnemy.Hexagon);
				} else if (Math.random() < 1.0 / 2.0) {
					enemy = new Enemy(EEnemy.Ghost);
				} else {
					enemy = new Enemy(EEnemy.Sine);
				}
			}
			
			addChildAt(enemy, 1);
			enemies.push(enemy);
		}
		
		// update enemies
		var removed : UInt = 0;
		for (e in 0...enemies.length) {
			enemies[e - removed].update(pSpeed * (slowmo ? 0.5 - (0.03 * Saving.getUpgradeLevel(EUpgrade.SlowMo)) : 1), player);
			if (enemies[e - removed].getType() == EEnemy.Hexagon) {
				if (enemies[e - removed].getLifetime() <= 0 && enemies[e - removed].getExplode()) {
					for (iter in 0...6) {
						var en : Enemy = new Enemy(EEnemy.HexagonSmall, true, enemies[e - removed].x, enemies[e - removed].y, enemies[e - removed].rotation + (60 * iter));
						addChildAt(en, 1);
						enemies.push(en);
						enemies[e - removed].setExplode(false);
					}
				}
			}
			
			if (enemies[e - removed].alpha <= 0.01 || enemies[e - removed].x < -50 || enemies[e - removed].y < -50 || enemies[e - removed].x > stage.stageWidth + 50 || enemies[e - removed].y > stage.stageHeight + 50) {
				removeChild(enemies[e - removed]);
				enemies.remove(enemies[e - removed]);
				removed++;
			}
		}
		
		// check collisions
			// enemies
		for (enemy in enemies) {
			if (enemy.isDeadly() && enemy.getHitbox().intersects(player.getHitbox()) && !player.isInvincible()) {
				super.setTargetAlpha(0);
				deathSound.play();
				removeEventListener(Event.ENTER_FRAME, update);
				var main : Main = cast parent;
				main.gameOver(scoreNumb, gamemode);
				player.setAlive(false);
				alive = false;
				if (gamemode == EGameMode.Rush) rushTimer.stop();
				super.setToBeDestroyed();
			}
			if ((gamemode == EGameMode.Classic || gamemode == EGameMode.Storm) && enemy.getHitbox().intersects(score.getHitbox())) {
				score.setTargetAlpha(0.5);
			} else if (gamemode == EGameMode.Rush && enemy.getHitbox().intersects(rush.getHitbox())) {
				rush.setTargetAlpha(0.5);
			}
			if (enemy.getHitbox().intersects(stamina.getHitbox())) {
				stamina.setTargetAlpha(0.5);
			}
			if (enemy.getHitbox().intersects(volume.getHitbox())) {
				volume.setTargetAlpha(0.5);
			}
		}
		
			// power ups
		var pi : Int = 0;
		while (pi < powers.length) {
			var power : PowerUp = powers[pi];
			if (!power.getCollected() && power.getHitbox().intersects(player.getHitbox())) {
				switch (power.getType()) {
					case EPowerUp.Shrink:
						player.shrink();
					case EPowerUp.Invincibility:
						player.beInvincible();
					case EPowerUp.Double:
						doubleCounter = 300;
					default:
						throw new Error("Power " + power.getType() + " not implemented yet!");
				}
				powerSound.play();
				power.setTargetAlpha(0);
				power.setCollected(true);
			} else if (power.getCollected() && power.alpha <= 0.05) {
				removeChild(powers[pi]);
				powers[pi] = null;
				powers.splice(pi, 1);
				pi--;
			} else {
				if ((gamemode == EGameMode.Classic || gamemode == EGameMode.Storm) && power.getHitbox().intersects(score.getHitbox())) {
					score.setTargetAlpha(0.5);
				} else if (gamemode == EGameMode.Rush && power.getHitbox().intersects(rush.getHitbox())) {
					rush.setTargetAlpha(0.5);
				}
				if (power.getHitbox().intersects(stamina.getHitbox())) {
					stamina.setTargetAlpha(0.5);
				}
				if (power.getHitbox().intersects(volume.getHitbox())) {
					volume.setTargetAlpha(0.5);
				}
			}
			pi++;
		}
		
			// coin
		if (player.getHitbox().intersects(coin.getHitbox())) {
			collectedCoins++;
			
			if (oldCoin != null) removeChild(oldCoin);
			oldCoin = new Coin(coin.x, coin.y);
			oldCoin.setTargetAlpha(0);
			addChildAt(oldCoin, 1);
			
			coin.alpha = 0;
			
			// make sure that coin doesn't immediately touch player
			while (Math.sqrt(Math.pow(coin.x - player.x, 2) + Math.pow(coin.y - player.y, 2)) < 100) {
				coin.newPosition();
			}
			
			stamina.increase(10 + Saving.getUpgradeLevel(EUpgrade.Stamina));
			
			coinSound.play();
			
			if (gamemode != EGameMode.Rush) score.setValue(score.getValue() + 1);
			scoreNumb++;
			// such repeating, do this in a better way
			if (doubleCounter > 0) {
				if (gamemode != EGameMode.Rush) score.setValue(score.getValue() + 1);
				scoreNumb++;
			}
		}
		
		// score & timer
		if (gamemode == EGameMode.Classic || gamemode == EGameMode.Storm) {
			if (coin.getHitbox().intersects(score.getHitbox())) {
				score.setTargetAlpha(0.5);
			}
			if (player.getHitbox().intersects(score.getHitbox())) {
				score.setTargetAlpha(0.5);
			}
		} else if (gamemode == EGameMode.Rush) {
			if (coin.getHitbox().intersects(rush.getHitbox())) {
				rush.setTargetAlpha(0.5);
			}
			if (player.getHitbox().intersects(rush.getHitbox())) {
				rush.setTargetAlpha(0.5);
			}
		}
		
		// stamina
		if (coin.getHitbox().intersects(stamina.getHitbox())) {
			stamina.setTargetAlpha(0.5);
		}
		if (player.getHitbox().intersects(stamina.getHitbox())) {
			stamina.setTargetAlpha(0.5);
		}
		
		// volume
		if (player.getHitbox().intersects(volume.getHitbox())) {
			volume.setTargetAlpha(0.5);
		}
		if (coin.getHitbox().intersects(volume.getHitbox())) {
			volume.setTargetAlpha(0.5);
		}
	}
	
    override public function onDestroy () : Void {
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		
		if (gamemode == EGameMode.Rush) {
			rushTimer.removeEventListener(TimerEvent.TIMER, updateTimer);
			rushTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerComplete);
			rushTimer = null;
		}
		
		removeChild(background);
		background = null;
		
		removeChild(player);
		player = null;
		
		if (gamemode == EGameMode.Classic || gamemode == EGameMode.Storm) {
			removeChild(score);
			score = null;
		} else {
			removeChild(rush);
			rush = null;
		}
		
		removeChild(coin);
		coin = null;
		
		if (oldCoin != null) {
			if (oldCoin.stage != null) {
				removeChild(oldCoin);
				oldCoin = null;
			}
		}
		
		removeChild(stamina);
		stamina = null;
		
		for (enemy in enemies) {
			removeChild(enemy);
			enemy = null;
		}
		enemies.splice(0, enemies.length);
		
		for (power in powers) {
			removeChild(power);
			power = null;
		}
		powers.splice(0, powers.length);
		
		removeChild(volume);
		volume = null;
	}
}