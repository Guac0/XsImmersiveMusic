// This executes on the client when they are playing singleplayer
// A lot of this code is simply copied and pasted from multiplayer, performance is pretty much the same so there's no reason to rewrite it

// Below is the creation of arrays, that contain classnames of music tracks defined in config.cpp, randomized to make it fresh each time;
aCombatMusicClassnames = "'intense' in getArray (_x >> 'moods') " configClasses (configFile >> "CfgMusic") apply {configName _x} call BIS_fnc_arrayShuffle;
aDarkMusicClassnames = "'dark' in getArray (_x >> 'moods') " configClasses (configFile >> "CfgMusic") apply {configName _x} call BIS_fnc_arrayShuffle;
aCalmMusicClassnames = "'calm' in getArray (_x >> 'moods') " configClasses (configFile >> "CfgMusic") apply {configName _x} call BIS_fnc_arrayShuffle;

[{missionNameSpace setVariable ["ace_common_allowFadeMusic",false];}, [], 5] call CBA_fnc_waitAndExecute; // disabled allowFadeMusic in ace options, fixes lots
																										  // of problems with fadeMusic and ACE

// ======================================== LOGIC FUNCTIONS ========================================

XIM_fncMain = 
{
	params["_oFiringAI"];
	[_oFiringAI, player] call XIM_fncIteratePlayerCombat;
};

XIM_fncCombatTimeout = // this function determines whether the player has not had an AI fire near them in the past 5 mins, and if they have not, sets XIM_bCombat to
					   // false
{
	params["_oPlayer"]; // defines the parameter _oPlayer
	[_oPlayer] spawn // adds the following code to the scheduler
	{
		params["_oPlayer"]; // defines the parameter _oPlayer
		waitUntil // repeats the following code once every frame (ish)
		{
			private _bTimedOut = false; // declares _bTimedOut, which is false by default
			if (_oPlayer getVariable "XIM_bCombatMaster") then // if the player is the combat master for that group
			{
				_oPlayer setVariable ["XIM_bRecentCombat", false]; // set the player's recent combat variable to false
				sleep XIM_iCombatRefreshTime; // sleep for the value of XIM_iCombatRefreshTime, which is 120 seconds by default
				if (!(_oPlayer getVariable "XIM_bRecentCombat")) then // if XIM_bRecentCombat is still false after 2 minutes
				{
					_bTimedOut = true; // then set _bTimedOut to true
				};
			};
			if (_bTimedOut) then // if _bTimedOut is true
			{
				_oPlayer setVariable ["XIM_bCombatMaster", false]; // sets the player's combat master variable to false
				_oPlayer setVariable ["XIM_bCombat", false]; // sets the player's combat state to false
				[_oPlayer] call XIM_fncSendGroup; // calls the XIM_fncSendGroup function with the argument of _oPlayer
			};
			false; // makes the loop start all over again
		};
	};
};

XIM_fncSendGroup = // submits the provided unit's group to the server plus the unit's combat state, which triggers the publicVariable event handler
{
	params["_oPlayer"]; // defines the parameter _aPlayerMachineIDs in position zero
	[group _oPlayer,_oPlayer getVariable ["XIM_bCombat", false],"statechange"] call fncXIM_MusicRemote;
};

XIM_fncPlayNext = // submits the provided unit's group to the server plus the unit's combat state, which triggers the publicVariable event handler
{
	params["_oPlayer",["_bXIMuseTimeout",true]]; // defines the parameter _aPlayerMachineIDs in position zero
	if (_bXIMuseTimeout) then {
		[group _oPlayer,_oPlayer getVariable ["XIM_bCombat", false],"next"] call fncXIM_MusicRemote;
	} else {

		[group _oPlayer,_oPlayer getVariable ["XIM_bCombat", false],"statechange"] call fncXIM_MusicRemote;
	};

	
};

XIM_fncStopMusic =  // stops music playing on all clients in the group
{
	[""] remoteExecCall ["playMusic", group player, false]; // stops music playing on all clients in the group
	group player setVariable ["XIM_bMusicStopped", true]; // set the XIM_bMusicStopped variable to true in the group's namespace
};

XIM_fncStartMusic = // starts playing music for all clients in the group
{
	group player setVariable ["XIM_bMusicStopped", false]; // set the XIM_bMusicStopped variable to true in the group's namespace
	[player] call XIM_fncPlayNext;
};

XIM_fncIteratePlayerCombat = // defines the XIM_fncIteratePlayers function, which iterates through each player and determines if they are in combat
{
	params ["_oFiringAI", "_oPlayer"]; // defines _oFiringAI, which is the object of the AI who fired

	if (alive _oPlayer) then // if the player is not dead
	{
		if (_oPlayer distance _oFiringAI <= XIM_iCombatRange) then // if the distance to the AI who is firing is less than or equal to the value of XIM_iCombatRange,
																   // which is 500 metres by default
		{
			if (!(_oPlayer getVariable "XIM_bCombat")) then // if the player is not already in combat
			{
				_oPlayer setVariable ["XIM_bCombat", true]; // set the player's combat variable to true
				_oPlayer setVariable ["XIM_bCombatMaster", true]; // set the player's combat master variable to true
				[_oPlayer] call XIM_fncSendGroup; // call XIM_fncSendGroup with the argument _oPlayer
			}
			else // if the player is in combat
			{
				_oPlayer setVariable ["XIM_bRecentCombat", true]; // set the player's recent combat variable to true
			};
		};
	};
};

// ======================================== MUSIC FUNCTIONS ========================================

fncXIM_MusicHandler = { // defines the fncXIM_MusicHandler function, which plays a certain type of music based on the parameter
	params ["_groupOwnerIDs","_musictype"];
	_trackname = [_musictype] call fncXIM_TrackSelect; // select a random track from the given music type
	[10,0] remoteExecCall ["fadeMusic",_groupOwnerIDs,false]; //Fades currently playing music
	[{params["_trackname", "_groupOwnerIDs"]; [_trackname] remoteExecCall ["playMusic", _groupOwnerIDs, false];[10,1] remoteExecCall ["fadeMusic",_groupOwnerIDs,false];},[_trackname, _groupOwnerIDs], 10] call CBA_fnc_waitAndExecute;

	
};

fncXIM_TrackSelect = {
	params ["_musictype"];
	private _trackclassname = ""; // declare _trackclassname, an empty string

	switch (_musictype) do { 
		case "combat" : { _trackclassname = selectRandom aCombatMusicClassnames; }; // select a random track from the aCombatMusicClassnames array
		case "dark" : { _trackclassname = selectRandom aDarkMusicClassnames;}; // select a random track from the aDarkMusicClassnames array
		case "calm" : { _trackclassname = selectRandom aCalmMusicClassnames; };  // select a random track from the aCalmMusicClassnames array
	};
	
	_trackclassname; //Return classname

};

fncXIM_Shuffler = {
	params ["_groupOwnerIDs","_musictype", "_bXIMCombatState", "_gXIMGroup"];
	_trackname = [_musictype] call fncXIM_TrackSelect; // select a random track from the given music type
	[0,0] remoteExecCall ["fadeMusic",_groupOwnerIDs,false]; // set music volume to zero for fade in later

	if (XIM_bMusicDelayEnabled) then // if the music delay is enabled
	{
		_iRandomDelay = random 1 * (XIM_iMaxMusicDelay - XIM_iMinMusicDelay) + XIM_iMinMusicDelay; // calculates a random delay value using the specified min and max values
																								   // specified by the server from the CBA settings and the calculated mean
		_oGroupLeader = leader _gXIMGroup; // finds the leader of the _gXIMGroup group

		[{params["_trackname","_oGroupLeader", "_bXIMCombatState", "_groupOwnerIDs"]; if (_bXIMCombatState == _oGroupLeader getVariable ["XIM_bCombat", false]) then {[_trackname] remoteExecCall ["playMusic", _groupOwnerIDs, false]; [10,1] remoteExecCall ["fadeMusic",_groupOwnerIDs,false];};},[_trackname, _oGroupLeader, _bXIMCombatState, _groupOwnerIDs], _iRandomDelay] call CBA_fnc_waitAndExecute;
		// if the combat state after the random delay is still the same, then play the next song. this is to prevent an edge case where a group leader requests a
		// new song and then goes into combat soon after, effectively being in combat with a calm category song.
	}
	else // if the music delay is disabled
	{
		[_trackname] remoteExecCall ["playMusic", _groupOwnerIDs, false]; // plays the selected song on all clients in the group
		[10,1] remoteExecCall ["fadeMusic",_groupOwnerIDs,false]; // fade in next track
	};

};


fncXIM_MusicRemote = {
	params ["_gXIMGroup", "_bXIMCombatState","_XIMMusicRemoteFunction"]; //Defining params
	private _groupOwnerIDs = [];
	(units _gXIMGroup) apply {_groupOwnerIDs pushBackUnique (owner _x)}; //Retrieving ID's for players in group
	private _sXIM_MusicType = "";

	if !(XIM_bSystemEnabled) exitWith {}; 	//don't play music if entire system is stopped. Only this function has this for maximum 
											//compatibility (i.e. able to start and stop system without restarting the mission), but consider doing this in all the functions for 
											//performance gains (so XIM scripts are barely running so resources aren't wasted on calculating what music to play even if that music
											//will never actually get played thanks to this line in fncXIM_MusicRemote)?

	if (_bXIMCombatState) then { // if _bXIMCombatState is true

		_sXIM_MusicType = "combat"; // then set the music type to combat
				
	} else {
		private _sunrisesunset = date call BIS_fnc_sunriseSunsetTime;
		private _sunrise = _sunrisesunset select 0;
		private _sunset = _sunrisesunset select 1;

		if ((rain > 0.2) or (fog > 0.2) or ((daytime > _sunset) and (daytime < _sunrise))) then { // if it is foggy, raining or night time

			_sXIM_MusicType = "dark"; // set the music to dark
	  	} else {

	  		_sXIM_MusicType = "calm"; // otherwise set it to calm
		};

	};	

	switch (_XIMMusicRemoteFunction) do { 
		case "next" : {  [_groupOwnerIDs,_sXIM_MusicType, _bXIMCombatState, _gXIMGroup] call fncXIM_Shuffler; }; 
		case "statechange" : { [_groupOwnerIDs,_sXIM_MusicType] call fncXIM_MusicHandler; }; 
	};

};

// ======================================== INIT ========================================

player setVariable ["XIM_bCombat", false]; // set the XIM_bCombat variable on the client, with the default value of false
player setVariable ["XIM_bCombatMaster", false]; // set the XIM_bCombatMaster variable on the client, with the default value of false
player setVariable ["XIM_bMusicStopped", false]; // set the XIM_bMusicStopped variable on the client, with the default value of false
[player] call XIM_fncSendGroup; // calls the XIM_fncSendGroup function with the argument player
[player] call XIM_fncCombatTimeout; // calls the XIM_fncCombatTimeout function with the argument player
XIM_bMusicPlaying = false;		//Not synchronized over network

// ======================================== EVENT HANDLERS ========================================

["ace_firedNonPlayer", XIM_fncMain] call CBA_fnc_addEventHandler; // adds event handler for when an AI fires

["ace_firedNonPlayerVehicle", XIM_fncMain] call CBA_fnc_addEventHandler; // adds event handler for when an AI fires inside a vehicle

addMusicEventHandler ["MusicStart", {
	
	XIM_bMusicPlaying = true;		//Not synchronized over network
	
	if !(XIM_bSystemEnabled) exitWith {}; 	//if mission has disabled XIM, they probably don't want the 'Now Playing' UI to pop up when Zeus/other script starts a song 
											//then again, the 'Now Playing' UI is kinda cool and Zeus/other might want it on. Consider removing this line and just adding a disclaimer to
											//'XIM_bSystemEnabled' in the CBA options that they also need to disable XIM_bNowPlayingEnabled if they want to hide the 'Now Playing' UI too.
											
	if (XIM_bNowPlayingEnabled) then
	{
		private _trackname = getText (configFile >> "CfgMusic" >> _this select 0 >> "name");
		private _artistname = getText (configFile >> "CfgMusic" >> _this select 0 >> "artist");
		[parseText format["Now playing<br/><t font='PuristaBold' size='1.6'>%1</t><br/><t font='PuristaBold' size='0.8'>%2</t>", _trackname,_artistname], true, nil, 5, 1, 0] spawn BIS_fnc_textTiles;
	};
}];

addMusicEventHandler ["MusicStop", // once the currently playing track has finished playing
{
	XIM_bMusicPlaying = false;		//Not synchronized over network
	[player] call XIM_fncPlayNext;
}];

"XIM_bSystemEnabled" addPublicVariableEventHandler {	//Automatically resumes music when system is re-enabled. Doesn't trigger in singleplayer.
	
	if !(XIM_bSystemEnabled) exitWith {};	//If the system was changed to disabled, then there's no need to resume music, so cancel.

	if (XIM_bMusicPlaying) exitWith {};		//XIM will automatically play music after current song ends, so if there's a song playing then there's no need to manually resume music playing

	if ((leader (group player)) == player) then
	{
		[player] call XIM_fncPlayNext;		//Start XIM's chain of functions to play music 
	};
};
