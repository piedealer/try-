using System;
using System.Collections.Generic;
//using System.IO;
using System.Linq;
//using System.Text;
//using System.Runtime.Serialization.Formatters.Soap;
using System.Threading;
using System.Threading.Tasks;
//using System.Xml;
//using System.Xml.Serialization;
using Viper.Scripting.Core.Classes;
using Viper.Scripting.Core.Interfaces;
using System.Windows.Forms;
//using System.Text.RegularExpressions;
//using System.Diagnostics;
using System.Speech.Synthesis;
using System.Speech.AudioFormat;
//using System.Runtime.InteropServices;

namespace H202
{
    class PlayerDetect : IPlugin
    {
        private static bool debug1 = false;
		private static bool debug2 = false;
		public static void log2(IGame _log2Bot, String _log2Message, bool _log2DoDebug)
        {
			if(_log2DoDebug || debug1)
			{
				_log2Bot.Log.WriteLine(String.Format("{0} - {1} - {2} - {3} - {4}", System.DateTime.Now.ToString(), System.Threading.Thread.CurrentThread.ManagedThreadId, System.Threading.Thread.CurrentThread.Name, "PlayerDetect", _log2Message));
			}
        }

		public static void logDebug1(IGame _Debug1Bot, String _Debug1Message, bool _Debug1DoDebug)
        {
			if(_Debug1DoDebug || debug2)
			{
				_Debug1Bot.Log.WriteLine(String.Format("{0} - {1} - {2} - {3} - {4}", System.DateTime.Now.ToString(), System.Threading.Thread.CurrentThread.ManagedThreadId, System.Threading.Thread.CurrentThread.Name, "PlayerDetect", _Debug1Message));
			}
        }
		
		public static void PressKeyLog(IGame _bot, String _key, int _pressLenMs)
        {
			log2(_bot, _key, true);
			_bot.Input.PressKey(_key,_pressLenMs);
        }
        public string Name { get { return "PlayerDetect"; } }

        public string Author { get { return "H202"; } }

        public string Description { get { return "PlayerDetect detects nosy players."; } }

        public float Version { get { return 1.0f; } }

        public Panel Panel { get { return new Panel(); } }

        public List<string> Tasks { get { return new List<string>(); } }

        public string AutoUpdateWebPath { get { return ""; } }

        public string Url { get { return ""; } }

        public bool WantsButton { get { return false; } }

        public static IGame Bot = null;

        private volatile static bool botStarted = false;

		HighResTimer aTimer = new HighResTimer();
		
		private int anInt = -1;
		
		private static Random rnd = new Random();
		
		///////////////////////////////////////////////////////////////////////////////
		////////////		DETECTION VALUES BELOW, DONT CHANGE	  ///////////
		//////////////////////////////////////////////////////////////////////////////
		
		// The two values detectNosyCountTreshhold and detectNosyRangeTreshhold should be used in conjunction. 
		// The greater the detectNosyCountTreshhold tolerance the wider the detectNosyRangeTreshhold radius and vice versa, but neither value should ever go to extremes.
		// Higher detectNosyCountTreshhold means greater tolerance for detecting as nosy player. 35 should be a good default middle value.
		private static float detectNosyCountTreshhold = 70f; // Value to determine when a player becomes too nosy! Must be greater than 0 (o'rly.... duh!).
		
		// Higher detectNosyRangeTreshhold means larger radius within to begin detecting players as nosy. 
		// Too small radius could mean that a bothunter that observes you from a distance wont be detected. 
		// Too large radius mean too many false positives will be detected, ie. players that arent being nosy, but just happens to be in range.
		private static float detectNosyRangeTreshhold = 37f; // Distance in game units. Must be greater than 0 (duh!).
		
		// nosyCountCombatMod is multiplier modifier for nosy count during combat, set to 1f for same count as out of combat
		private static float nosyCountCombatMod = 0.6f; // 0f: no increase to nosy count during combat. <1f: increase to nosy count will be less during combat. >1f: increase to nosy count will be more during combat
		
		// nosyCountNoMoveMod is multiplier modifier for nosy count when bot is not moving
		private static float nosyCountBotNoMoveMod = 0.05f;
		
		// nosyCountNosyPlayerNoMoveMod is multiplier modifier for nosy count when potential nosy player is not moving
		private static float nosyCountNosyPlayerNoMoveMod = 0.2f;
		
		// nosyTickSleepMs is how often to run the nosy check routine. 
		// Too low and performance will take an unnecessary hit, too high and we may not detect nosy players properly or fast enough.
		private static int nosyTickSleepMs = 1000; // 1000 ms is probably a nice value. 
		
		private static float[] botPreviousXY_array = new float[] {9999999f,9999999f};
		
		///////////////////////////////////////////////////////////////////////////////
		////////////		DETECTION VALUES ABOVE, DONT CHANGE	  ///////////
		//////////////////////////////////////////////////////////////////////////////

		private static List<IMob> nosyPlayersMobList = new List<IMob>();
		// Dictionary nosyPlayersSuspiciousMobDict: string nosyPlayerName, array float[nosyPlayerX, nosyPlayerY, nosyCount, nosyNotMoveCount]
		private static Dictionary<string, float[]> nosyPlayersSuspiciousMobDict = new Dictionary<string, float[]>();							
		private static List<string> nosyPlayersNameList = new List<string>();
		private static int nosyPlayerNotMoveCount = 0;
		private static int botNoMoveCount = 0;
		private volatile static bool nosyPlayerDetectedTakeControl = false;
		private volatile static bool hasEncounteredErrorDoPause = false;

		public void checkForNosyPlayers()
		{
			log2(Bot, "Now scanning for nosy players!",  true);
			while(botStarted)
			{
				int iiii = 0;
				// log2(Bot, "DEBUG02.",  false);
				if(Bot != null)
				{
					// log2(Bot, "DEBUG03.",  false);
					// TODO filter off player names from an exclusion (for example your own bots). Make a blacklist file for this, like excludeBotNames.txt or excludePlayerNames.txt
					nosyPlayersMobList.Clear();
					// log2(Bot, "DEBUG04.",  false);
					nosyPlayersMobList = Bot.GetMobArray.Where(oo => oo != null && oo.isValid && oo.Type == 2 && oo.HP > 0 
						&& oo.Name != "unknown"
						&& oo.Name != "Unknown"
						&& oo.Name != "Object"
						&& oo.Name != "object"
						&& oo.Name != ""
						&& oo.Name != " ."
						&& oo.Name != Bot.Player.Name
						&& Bot.Player.DistanceTo(oo) < detectNosyRangeTreshhold)
						.ToList();
				}
				
				// log2(Bot, "DEBUG05.",  false);
				List<string> nosyPlayersMobNameList = new List<string>();
				foreach(IMob nosyPlayerMobz in nosyPlayersMobList)
				{
					// log2(Bot, "DEBUG06.",  false);
					nosyPlayersMobNameList.Add(nosyPlayerMobz.Name);
					Thread.Sleep(10);
				}
				// log2(Bot, "DEBUG07.",  false);
				
				List<string> nosyPlayersMobNamesToRemoveList = new List<string>();
				foreach( KeyValuePair<string, float[]> kvp in nosyPlayersSuspiciousMobDict )
				{
					// log2(Bot, "DEBUG08. iiii: "+iiii+".",  false);
					// The point of this block is to only reduce nosy count if player is out of range of the treshold, instead of outright removing them.
					// If the nosy player got outside the treshold for just one tick, but then came in range again in the next tick,
					// or a few ticks later, they may actually still be following us and if so we want to preserve some of their nosy count for a little while so we dont have to start from scratch
					if(!nosyPlayersMobNameList.Contains(kvp.Key))
					{
						// log2(Bot, "DEBUG09A. iiii: "+iiii+".",  false);
						// nosy player is not in range anymore, so reduce their nosy count some.
						
						float newNosyCountDueToNosyPlayerOutOfRange = (nosyPlayersSuspiciousMobDict[kvp.Key][2] * 0.92f)-(detectNosyCountTreshhold*0.04f);
						// logDebug1(Bot, "DEBUG09B. iiii: "+iiii+", kvp.Key: "+kvp.Key+".",  false);
						// logDebug1(Bot, "DEBUG09C. iiii: "+iiii+", nosyPlayersSuspiciousMobDict[kvp.Key][2]: "+nosyPlayersSuspiciousMobDict[kvp.Key][2]+".",  false);
						// logDebug1(Bot, "DEBUG09D. iiii: "+iiii+", newNosyCountDueToNosyPlayerOutOfRange: "+newNosyCountDueToNosyPlayerOutOfRange+".",  false);
						nosyPlayersSuspiciousMobDict[kvp.Key][2] = newNosyCountDueToNosyPlayerOutOfRange;
						if(nosyPlayersSuspiciousMobDict[kvp.Key][2] < 0)
						{
							// Nosy count for this player fell below 0, assume they are gone for now, so now we can safely remove the nosy player from the dictionary.
							// logDebug1(Bot, "#"+iiii+" Nosy count of player: "+kvp.Key+" fell below 0, assume they are gone for now.",  false);
							nosyPlayersMobNamesToRemoveList.Add(kvp.Key);
							
						}
					}
					iiii++;
					Thread.Sleep(10);
				}
				// log2(Bot, "DEBUG10A. iiii: "+iiii+".",  false);
				int numToRemove = 0;
				foreach( string nosyMobKeyToRemove in nosyPlayersMobNamesToRemoveList )
				{
					// log2(Bot, "DEBUG10B. iiii: "+iiii+". numToRemove: "+numToRemove+".",  false);
					numToRemove++;
					nosyPlayersSuspiciousMobDict.Remove(nosyMobKeyToRemove);
					Thread.Sleep(10);
				}
				// log2(Bot, "DEBUG10C. iiii: "+iiii+", "+numToRemove+ " players removed from dictionary.",  false);
				
				if(nosyPlayersMobList != null && nosyPlayersMobList.Count > 0)
				{
					// log2(Bot, "DEBUG11. iiii: "+iiii+".",  false);
					foreach(IMob nosyPlayerMob in nosyPlayersMobList)
					{
						// log2(Bot, "DEBUG12. iiii: "+iiii+".",  false);
						if(nosyPlayerMob == null || !nosyPlayerMob.isValid)
						{
							continue;
						}
						// log2(Bot, "DEBUG13A. iiii: "+iiii+".",  false);
						string nosyMobNameString = nosyPlayerMob.Name;
						// log2(Bot, "DEBUG13B. iiii: "+iiii+".",  false);
						float nosyMobX = nosyPlayerMob.X;
						// log2(Bot, "DEBUG13C. iiii: "+iiii+".",  false);
						float nosyMobY = nosyPlayerMob.Y;
						// log2(Bot, "DEBUG13D. iiii: "+iiii+".",  false);
						if (!nosyPlayersSuspiciousMobDict.ContainsKey(nosyMobNameString))
						{
							// log2(Bot, "DEBUG14. iiii: "+iiii+".",  false);
							// Nosy player was not in dictionary, so just add it and do nothing more this time.
							nosyPlayersSuspiciousMobDict.Add(nosyMobNameString, new float[] {nosyMobX, nosyMobY, 0f, 0f});
						}else
						{
							// log2(Bot, "DEBUG15. iiii: "+iiii+".",  false);
							float nosyCountAddMin = 0.7f;
							float nosyCountAddMax = 2f;
							float distToNosyPlayer = (float)distBetweenTwoPoints(Bot.Player.X, Bot.Player.Y, nosyMobX, nosyMobY);
							// The closer the nosy player is the more we shall increase the nosy count
							// log2(Bot, "DEBUG16A. iiii: "+iiii+".",  false);
							float nosyCountAdd = nosyCountAddMax + (distToNosyPlayer / detectNosyRangeTreshhold * (nosyCountAddMin - nosyCountAddMax));
							// logDebug1(Bot, "DEBUG16B. iiii: "+iiii+", initial value for nosyCountAdd: "+nosyCountAdd+".",  false);
							// log2(Bot, "DEBUG17. iiii: "+iiii+".",  false);
							if (!nosyPlayersSuspiciousMobDict.ContainsKey(nosyMobNameString))
							{
								Speak("A A Key "+nosyMobNameString+" does not exist in dictionary!", 2);
								Thread.Sleep(999999999);
							}
							if(distBetweenTwoPoints(nosyMobX,nosyMobY, nosyPlayersSuspiciousMobDict[nosyMobNameString][0], nosyPlayersSuspiciousMobDict[nosyMobNameString][1]) < 1f)
							{
								// log2(Bot, "DEBUG18. iiii: "+iiii+".",  false);
								// suspicious player had moved less than 1 game unit since last check (assume they are not moving, ie. less risk they are following us).
								if (!nosyPlayersSuspiciousMobDict.ContainsKey(nosyMobNameString))
								{
									// if(debug1 || debug2)
									// {
										hasEncounteredErrorDoPause = true;
										Bot.Navigation.Hardstop();
										Speak("A B ERROR! Key "+nosyMobNameString+" does not exist in dictionary! PLAYER DETECT PLUGIN WILL NOT CONTINUE!", 2);
										log2(Bot, "A B ERROR! Key "+nosyMobNameString+" does not exist in dictionary! PAUSING! This is unexpected behavior (should be impossible so something is wrong) :( Please stop bot and tell the plugin author of this error.",  true);
										nosyPlayersSuspiciousMobDict.Clear();
										Thread.Sleep(999999999);
										Thread.Sleep(999999999);
									// }
								}else
								{
									// log2(Bot, "DEBUG19A. iiii: "+iiii+", "+nosyMobNameString+" DOES exist in dictionary!",  false);
								}
								// log2(Bot, "DEBUG19B. iiii: "+iiii+".",  false);
								// logDebug1(Bot, "DEBUG19C1. iiii: "+iiii+", nosyMobNameString: "+nosyMobNameString+".",  false);
								// logDebug1(Bot, "DEBUG19C2. iiii: "+iiii+", nosyPlayerX: nosyPlayersSuspiciousMobDict[nosyMobNameString][0]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][0]+".",  false);
								// logDebug1(Bot, "DEBUG19D. iiii: "+iiii+", nosyPlayerY: nosyPlayersSuspiciousMobDict[nosyMobNameString][1]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][1]+".",  false);
								// logDebug1(Bot, "DEBUG19E. iiii: "+iiii+", nosyCount: nosyPlayersSuspiciousMobDict[nosyMobNameString][2]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][2]+".",  false);
								// logDebug1(Bot, "DEBUG19F. iiii: "+iiii+", nosyNotMoveCount: nosyPlayersSuspiciousMobDict[nosyMobNameString][3]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][3]+".",  false);
								nosyPlayersSuspiciousMobDict[nosyMobNameString][3] += 1f;
								// log2(Bot, "DEBUG19G. iiii: "+iiii+".",  false);
								if(nosyPlayersSuspiciousMobDict[nosyMobNameString][3] < 5f)
								{
									// dont modify count yet
								}else if(nosyPlayersSuspiciousMobDict[nosyMobNameString][3]  >= 5f)
								{
									// log2(Bot, "DEBUG20A. iiii: "+iiii+".",  false);
									// nosy player did not move for multiple times in a row, so subtract substantial value from the total nosy count (since we did not modify value the first 4 times nosy player did not move).
									// logDebug1(Bot, "DEBUG20B. iiii: "+iiii+", nosy count is now nosyPlayersSuspiciousMobDict[nosyMobNameString][2]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][2] +".",  false);
									if(nosyPlayersSuspiciousMobDict[nosyMobNameString][2] > 0)
									{
										// logDebug1(Bot, "DEBUG20C. iiii: "+iiii+", nosy player did not move for multiple times in a row, so subtract substantial value from the total nosy count, subtraction value of nosyCountAdd("+nosyCountAdd+") *3f: "+(nosyCountAdd *3f)+".",  false);
										nosyPlayersSuspiciousMobDict[nosyMobNameString][2] -= ((nosyCountAddMax-nosyCountAdd)*3f); // subtracting nosyCountAdd from nosyCountAddMax so that the value to subtract will be less the closer the nosy player is and more the further away the nosy player is
										//nosyPlayersSuspiciousMobDict[nosyMobNameString][2] = nosyPlayersSuspiciousMobDict[nosyMobNameString][2] - (nosyPlayersSuspiciousMobDict[nosyMobNameString][2] *0.7f); 
									}
									// logDebug1(Bot, "DEBUG20D. iiii: "+iiii+", nosy count is now nosyPlayersSuspiciousMobDict[nosyMobNameString][2]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][2] +".",  false);
									nosyPlayersSuspiciousMobDict[nosyMobNameString][3] = 0; // reset nosy not move count
								}else
								{
									// log2(Bot, "DEBUG21A. iiii: "+iiii+".",  false);
									// logDebug1(Bot, "DEBUG21B. iiii: "+iiii+", nosy count is now nosyPlayersSuspiciousMobDict[nosyMobNameString][2]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][2] +".",  false);
									nosyCountAdd=nosyCountAdd*nosyCountNosyPlayerNoMoveMod; // nosy player still not moving, less risky.
									// logDebug1(Bot, "DEBUG21C. iiii: "+iiii+", nosy player still not moving so less risky, nosyCountAdd: "+nosyCountAdd+".",  false);
									// logDebug1(Bot, "DEBUG21D. iiii: "+iiii+", nosy count is now nosyPlayersSuspiciousMobDict[nosyMobNameString][2]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][2] +".",  false);
								}
								
							}else
							{
								// log2(Bot, "DEBUG22A. iiii: "+iiii+".",  false);
								// log2(Bot, "DEBUG22B. iiii: "+iiii+".",  false);
								// suspicious player had moved 1 or more game unit(s) since last check. (ie. they are probably moving, so higher risk they may be following us).
								nosyPlayersSuspiciousMobDict[nosyMobNameString][3] = 0; // reset nosyNotMoveCount to 0 since the nosy player had moved.
							}
							// log2(Bot, "DEBUG23A. iiii: "+iiii+".",  false);
							// logDebug1(Bot, "DEBUG23B. iiii: "+iiii+", bot X: "+Bot.Player.X+", bot Y: "+Bot.Player.Y+", bot prev X: "+botPreviousXY_array[0]+", bot prev Y: "+botPreviousXY_array[1]+".",  false);
							// logDebug1(Bot, "DEBUG23B. iiii: "+iiii+", bot moved since last tick: "+distBetweenTwoPoints(Bot.Player.X,Bot.Player.Y, botPreviousXY_array[0], botPreviousXY_array[1])+".",  false);
							if(distBetweenTwoPoints(Bot.Player.X,Bot.Player.Y, botPreviousXY_array[0], botPreviousXY_array[1]) < 1f)
							{
								log2(Bot, "DEBUG24A. iiii: "+iiii+".",  false);
								// bot had moved less than 1 game unit since last check. Assume we are not moving (so less risk, because who suspects a player that just stands still?).
								botNoMoveCount++;
								if(botNoMoveCount > 4)
								{
									nosyCountAdd=nosyCountAdd*nosyCountBotNoMoveMod;
								}else
								{
									// dont yet modify nosyCountAdd due to bot not moving, bot needs to not move for more ticks before we consider it to not actually be moving. 
									// (for example when gathering bot will not move for a few seconds while collecting the node, but we still want to add full nosy count for nosy players during the gather time),
								}
								
								// logDebug1(Bot, "DEBUG24B. iiii: "+iiii+", bot had moved less than 1 game unit since last check so less risky, nosyCountAdd: "+nosyCountAdd+".",  false);
							}else
							{
								// bot had moved 1 or more game unit(s) since last check, (ie. we must be moving which means higher risk)
								// so reset the botNoMoveCount.
								botNoMoveCount = 0;
							}
								// log2(Bot, "DEBUG25. iiii: "+iiii+".",  false);
							if(Bot.GetAttackers != null && Bot.GetAttackers.Count() > 0)
							{
								// log2(Bot, "DEBUG26A. iiii: "+iiii+".",  false);
								// we are in combat. There should probably (perhaps?) be less risk while figthing, especially compared to when gathering (TODO: so do we need a gathering modifier also then?).
								// logDebug1(Bot, "DEBUG26B. iiii: "+iiii+", nosy count is now nosyPlayersSuspiciousMobDict[nosyMobNameString][2]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][2] +".",  false);
								// logDebug1(Bot, "DEBUG26C. iiii: "+iiii+", we are in combat so less risky, nosyCountAdd("+nosyCountAdd+") = nosyCountAdd("+nosyCountAdd+") * nosyCountCombatMod("+nosyCountCombatMod+": "+(nosyCountAdd*nosyCountCombatMod)+".",  false);
								nosyCountAdd=nosyCountAdd*nosyCountCombatMod;
								// logDebug1(Bot, "DEBUG26D. iiii: "+iiii+", we are in combat so less risky, nosyCountAdd: "+nosyCountAdd+".",  false);
								// logDebug1(Bot, "DEBUG26E. iiii: "+iiii+", nosy count is now nosyPlayersSuspiciousMobDict[nosyMobNameString][2]: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][2] +".",  false);
							}else
							{
								// we are not in combat, more risky because now we will just be moving allong to whatever destination, for example gathering.
							}
							// log2(Bot, "DEBUG27A. iiii: "+iiii+".",  false);
							// Add the calculated nosy count to our total nosy count for this nosy player.
							nosyPlayersSuspiciousMobDict[nosyMobNameString][2] += nosyCountAdd;
							// logDebug1(Bot, "DEBUG27B. iiii: "+iiii+", final calculated nosyCountAdd: "+nosyCountAdd+".",  false);
							// log2(Bot, "DEBUG28. iiii: "+iiii+".",  false);
							// Record the current X,Y position of the nosy player
							nosyPlayersSuspiciousMobDict[nosyMobNameString][0] = nosyMobX;
							// log2(Bot, "DEBUG29. iiii: "+iiii+".",  false);
							nosyPlayersSuspiciousMobDict[nosyMobNameString][1] = nosyMobY;
							// log2(Bot, "DEBUG30. iiii: "+iiii+".",  false);
							if(nosyPlayersSuspiciousMobDict[nosyMobNameString][2]  > detectNosyCountTreshhold)
							{
								nosyPlayerDetectedTakeControl = true;
								// log2(Bot, "DEBUG31. iiii: "+iiii+".",  false);
								log2(Bot, "1 Player "+nosyMobNameString+" is nosy! Nosy count "+nosyPlayersSuspiciousMobDict[nosyMobNameString][2]+" exceeded nosy treshold "+detectNosyCountTreshhold+", assume they are following us! Perform evasive actions!",  true);
								new Thread(() => Speak("Player "+nosyMobNameString+" is nosy!", 2)).Start();
								// log2(Bot, "DEBUG33. iiii: "+iiii+".",  false);
								Bot.Navigation.Hardstop();
								// log2(Bot, "DEBUG34. iiii: "+iiii+".",  false);
								// reset nosy value to a bit less of what it was (substantially lower tolerance for this player for a short while afterwards, preserving most of the nosy count)
								// (though currently not needed as the plugin logsout and pauses requiring restarting patrol, may be needed later if doing other evasive actions, or if implementing logging in again, in case the nosy player is still there?)
								nosyPlayersSuspiciousMobDict[nosyMobNameString][2] *= 0.8f; 
								// log2(Bot, "DEBUG35. iiii: "+iiii+".",  false);
								// logDebug1(Bot, "2 Nosy count after halving: "+nosyPlayersSuspiciousMobDict[nosyMobNameString][2]+".",  false);
								break;
							}
							// log2(Bot, "DEBUG37. iiii: "+iiii+".",  false);
							
						}
						// log2(Bot, "DEBUG38. iiii: "+iiii+".",  false);
						Thread.Sleep(25);
					}
					if(nosyPlayerDetectedTakeControl)
					{
						// logDebug1(Bot, "DEBUG27B. iiii: "+iiii+", nosyPlayerDetectedTakeControl: "+nosyPlayerDetectedTakeControl+", player detection breaking the while loop!",  false);
						break;
					}
					// log2(Bot, "DEBUG39. iiii: "+iiii+".",  false);
				}
				// log2(Bot, "DEBUG40. iiii: "+iiii+".",  false);
				botPreviousXY_array[0] = Bot.Player.X;
				// log2(Bot, "DEBUG41. iiii: "+iiii+".",  false);
				botPreviousXY_array[1] = Bot.Player.Y;
				int nosyTickSleepMsTemp = nosyTickSleepMs-(iiii*25);
				if(nosyTickSleepMsTemp < 250)
				{
					nosyTickSleepMsTemp = 250;
				}
				Thread.Sleep(nosyTickSleepMsTemp);
			}
			nosyPlayersSuspiciousMobDict.Clear();
			log2(Bot, "Player detection ended!",  true);
		}
		
		
        public bool NeedsToRun
        {

            get
            {
				log2(Bot, "NeedsToRun01 NeedsToRun.",  false);
				if(hasEncounteredErrorDoPause)
				{
					log2(Bot, "ERROR! Something went wrong with the Player Detect plugin :( PAUSING! Please stop patrol and inform the plugin author.",  true);
					Bot.Navigation.Hardstop();
					Thread.Sleep(999999999);
					Thread.Sleep(999999999);
				}
				if(nosyPlayerDetectedTakeControl)
				{
					if(Bot.GetAttackers.Count <= 0)
					{
						// nosy cont exceeded the treshold value, assume the nosy player is following us!
						// add actions to do here, for example: /logout, /quit, port away hotkeys, or mount, and/or set all nodes/mobs to invulnerable (so that bot will ignore them)
						// or maybe just take control and then do nothing?
						// and/or speak out a warning. Perhaps start a different patrol (would be nice but idk how to do that currently).
						Bot.Navigation.Hardstop();
						log2(Bot, "Nosy player detected, stop movement and press Escape to make sure we aren't prevented from entering chat correctly. Then sending /logout to chat (sending it twice with ~12 seconds and Escape press in between). Pausing bot. Please stop patrol and start it again when you are ready. Note if you are in combat game refuses to logout, in that case plugin should abort logout and release control so bot can fight, and THEN logout.",  true);
						Bot.Navigation.Hardstop();
						bool didAbortLogout = false;
						for(int i=0;i<2;i++)
						{
							PressKeyLog(Bot, "{ESCAPE}", rnd.Next(47,89)); // press escape to be sure we werent already in chat or to escape any screen that may prevent entering chat (for example announcements).
							Thread.Sleep(rnd.Next(1210,1345));
							if(!botStarted)
							{
								break;
							}
							Bot.Input.SetKeyDelay(rnd.Next(121,174)); // delay in milliseconds between each keypress when using SendCommand
							Bot.Input.SendCommand("/logout");
							Thread.Sleep(rnd.Next(10820,11078));
							if(!botStarted)
							{
								break;
							}
							if(Bot.GetAttackers.Count > 0)
							{
								Thread.Sleep(rnd.Next(3020,3278));
								if(Bot.GetAttackers.Count > 0)
								{
									// entered combat while logging out! Aborting logout! Will wait until not in combat and try again.
									didAbortLogout = true;
									log2(Bot, "LOUGOUTNOSY0A Nosy player detected, but entered combat while logging out! Aborting logout! Will wait until not in combat and try again.",  true);
									PressKeyLog(Bot, "{ESCAPE}", rnd.Next(72,98)); // press escape once more just to be sure we werent already in chat or to escape any screen that may prevent entering chat (for example announcements).
									Thread.Sleep(rnd.Next(1210,1345));
									PressKeyLog(Bot, "w", rnd.Next(63,84)); // move to auto-close any character window/main menu (this wont close announcements screen though, so the first first escape press is still necessary)
									Thread.Sleep(rnd.Next(1240,1372));
									PressKeyLog(Bot, "w", rnd.Next(52,79)); // move to auto-close any character window/main menu (this wont close announcements screen though, so the first first escape press is still necessary)
									Thread.Sleep(rnd.Next(1210,1345));
									break;
								}
							}
						}
						if(Bot.GetAttackers.Count > 0)
						{
							// entered combat while logging out! Aborting logout! Will wait until not in combat and try again.
							if(!didAbortLogout)
							{
								log2(Bot, "LOUGOUTNOSY0B Nosy player detected, but entered combat while logging out! Aborting logout! Will wait until not in combat and try again.",  true);
								PressKeyLog(Bot, "{ESCAPE}", rnd.Next(85,103)); // press escape once more just to be sure we werent already in chat or to escape any screen that may prevent entering chat (for example announcements).
								Thread.Sleep(rnd.Next(1218,1365));
								PressKeyLog(Bot, "w", rnd.Next(51,72)); // move to auto-close any character window/main menu (this wont close announcements screen though, so the first first escape press is still necessary)
								Thread.Sleep(rnd.Next(1210,1345));
								PressKeyLog(Bot, "w", rnd.Next(59,78)); // move to auto-close any character window/main menu (this wont close announcements screen though, so the first first escape press is still necessary)
								Thread.Sleep(rnd.Next(1226,1365));
							}
						}else
						{
							Bot.Navigation.Hardstop();
							nosyPlayerDetectedTakeControl = false;
							nosyPlayersSuspiciousMobDict.Clear();
							Thread.Sleep(999999999);
							Thread.Sleep(999999999);
							Thread.Sleep(999999999);
						}
					}else
					{
						// in combat, do not attempt logout yet.
					}
				}
				return false;
            }
        }



        public void DoRun()
        {

        }

        public void OnBotStart(IGame PluginHelper)
        {
			//aTimer.Reset();
			botStarted = true;
            Bot = PluginHelper;
			nosyPlayersSuspiciousMobDict.Clear();
			new Thread(() => checkForNosyPlayers()).Start();
        }

        public void OnBotStop()
        {
            botStarted = false;
        }

        public void OnConfigure()
        {
        }

        public void OnDisabled()
        {
        }

        public void OnEnabled(IGame PluginHelper)
        {
            Bot = PluginHelper;
        }

        public void OnIdle()
        {
        }

        public void OnSendMessage(IPlugin fromPlugin, string text)
        {
        }

        public void OnSendObject(IPlugin fromPlugin, object o)
        {
        }

        public void SendMessage(IPlugin p, string text)
        {
        }

        public void SendObject(IPlugin p, object o)
        {
        }
		
		
		
		
		
		
		
		
		
		
		public sealed class Singleton
		{
			private static readonly Singleton instance = new Singleton();

			// Explicit static constructor to tell C# compiler
			// not to mark type as beforefieldinit
			static Singleton()
			{
			}

			private Singleton()
			{
			}

			public static Singleton Instance
			{
				get
				{
					return instance;
				}
			}
		}
		
		public double distBetweenTwoPoints(float x1, float y1, float x2, float y2)
        {
			//double distFromStartPos = Math.Abs( Math.Sqrt( Math.Pow(MyHelper.Player.X-startCoordX, 2) + Math.Pow(MyHelper.Player.Y-startCoordY, 2) ) );
			double dist = Math.Abs(Math.Sqrt(Math.Pow((x1-x2), 2)+Math.Pow((y1-y2), 2)));
			return dist;			
		}
		
		
		
		public static void Speak(string _textToSpeak, int _numToRepeatSpeak)
		{
			SpeechSynthesizer synth = new SpeechSynthesizer();
			// Output information about all of the installed voices.   
			Bot.Log.WriteLine("Installed voices -");
			foreach (InstalledVoice voice in synth.GetInstalledVoices())  
			{
				VoiceInfo info = voice.VoiceInfo;  
				string AudioFormats = "";  
				foreach (SpeechAudioFormatInfo fmt in info.SupportedAudioFormats)  
				{ 
					AudioFormats += String.Format("{0}\n", fmt.EncodingFormat.ToString());  
				}

				Bot.Log.WriteLine(" Name:          " + info.Name);  
				Bot.Log.WriteLine(" Culture:       " + info.Culture);  
				Bot.Log.WriteLine(" Age:           " + info.Age);  
				Bot.Log.WriteLine(" Gender:        " + info.Gender);  
				Bot.Log.WriteLine(" Description:   " + info.Description);  
				Bot.Log.WriteLine(" ID:            " + info.Id);  
				Bot.Log.WriteLine(" Enabled:       " + voice.Enabled);  
				if (info.SupportedAudioFormats.Count != 0)  
				{
					Bot.Log.WriteLine(" Audio formats: " + AudioFormats);
				}
				else  
				{  
					Bot.Log.WriteLine(" No supported audio formats found");
				}  

				string AdditionalInfo = "";  
				foreach (string key in info.AdditionalInfo.Keys)  
				{  
					AdditionalInfo += String.Format("  {0}: {1}\n", key, info.AdditionalInfo[key]);
				}  
				Bot.Log.WriteLine(" Additional Info - " + AdditionalInfo);  
			}   
			// }
			
			var syn = new System.Speech.Synthesis.SpeechSynthesizer();
			syn.SelectVoice("Microsoft Zira Desktop");
			for(int i=0;i< _numToRepeatSpeak;i++)
			{
				syn.Speak(_textToSpeak);
				Thread.Sleep(100);
			}
		}
		//


		public void dictTest()
		{
			nosyPlayersSuspiciousMobDict.Add("first", new float[] {1111110, 1111111f, 1111112f});
			nosyPlayersSuspiciousMobDict.Add("second", new float[] {2222220, 2222221f, 2222222f});
			nosyPlayersSuspiciousMobDict.Add("third", new float[] {3333330, 3333331f, 3333332f});
			nosyPlayersSuspiciousMobDict.Add("fourth", new float[] {4444440, 4444441f, 4444442f});
			float aFloatX = 99999999f;
			float aFloatY = 99999999f;
			float aFloatNosyCount = 99999999f;
			int iiii = 0;
			foreach( KeyValuePair<string, float[]> kvp in nosyPlayersSuspiciousMobDict )
			{
				Console.WriteLine("#"+iiii+ " Key = {0}, Value = {1}",
					kvp.Key, kvp.Value);
					
			
			
				aFloatX = nosyPlayersSuspiciousMobDict[kvp.Key][0];
				aFloatY = nosyPlayersSuspiciousMobDict[kvp.Key][1];
				aFloatNosyCount = nosyPlayersSuspiciousMobDict[kvp.Key][2];
				Bot.Log.WriteLine("LOSDICTTEST #"+iiii+" Key: "+kvp.Key+", aFloatX: "+aFloatX+", aFloatY: "+aFloatY+", aFloatNosyCount: "+aFloatNosyCount+".");
				iiii++;
			}

			Thread.Sleep(999999999);
			Thread.Sleep(999999999);
			//nosyPlayersSuspiciousMobDict[nosyPlayerMob.Name] = 
		}
		
    }
}
