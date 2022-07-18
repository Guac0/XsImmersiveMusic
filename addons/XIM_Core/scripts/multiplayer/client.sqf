// ======================================== Init ========================================

XIM_bMusicPlaying = false;		//Not synchronized over network

// ======================================== FUNCTIONS ========================================

XIM_fncPlayNext = // submits the provided unit's group to the server plus the unit's combat state, which triggers the publicVariable event handler
{
	params["_oPlayer",["_bXIMUseTimeOut",true]]; // defines the parameter _aPlayerMachineIDs in position zero
	XIM_aPlayNext = []; // defines XIM_aStateChange, which is an empty array
	XIM_aPlayNext pushBack group _oPlayer; // adds the player's group to XIM_aStateChange at position zero
	XIM_aPlayNext pushBack _oPlayer;
	XIM_aPlayNext pushBack _bXIMUseTimeOut; // Don't use timeout when user skips, instead it will call statechange on server for nice fadeout/in
	publicVariableServer "XIM_aPlayNext"; // sends the XIM_aStateChange variable to the server via its namespace
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

// ======================================== EVENT HANDLERS ========================================

addMusicEventHandler ["MusicStart", // once the currently playing track has finished playing
{
	XIM_bMusicPlaying = true;		//Not synchronized over network
}];

addMusicEventHandler ["MusicStop", // once the currently playing track has finished playing
{
	XIM_bMusicPlaying = false;		//Not synchronized over network
	if ((leader (group player)) == player) then
	{
		[player] call XIM_fncPlayNext;
	};
}];

"XIM_bSystemEnabled" addPublicVariableEventHandler {	//Automatically resumes music when system is re-enabled. Doesn't seem to work in local MP (on the host's machine, untested with multiple players)
	
	if !(XIM_bSystemEnabled) exitWith {};	//If the system was changed to disabled, then there's no need to resume music, so cancel.

	if (XIM_bMusicPlaying) exitWith {};		//XIM will automatically play music after current song ends, so if there's a song playing then there's no need to manually resume music playing

	if ((leader (group player)) == player) then
	{
		[player] call XIM_fncPlayNext;		//Start XIM's chain of functions to play music 
	};
};