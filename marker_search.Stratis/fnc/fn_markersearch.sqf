scriptName "fn_markersearch:";
/*
	Author: 7erra

	Description:
	Internal function to handle the marker search on the map. Calling it yourself is only neccessary to initialize it, everything else is handled by the script.

	Parameter(s):
	0: STRING - Mode in which the script should run
	1: ARRAY - Parameters for the different modes

	Returns:
	Bool - True when done
*/
#define SELF TER_fnc_markerSearch//(compile preprocessfilelinenumbers "markersearch\fn_markersearch.sqf")
#define IDC_RSCMAP_MRKGROUP 7300
#define IDC_RSCMAP_MRKSEARCH 7301
#define IDC_RSCMAP_MRKLIST 7302
#define IDC_RSCMAP_MRKSHOW 7303
#define IDC_RSCMAP_MRKBACKGROUND 7304
#define IDC_RSCMAP_MRKENDSEARCH 7305
//--- GUI_GRID
#define X_GRID (safeZoneX + safeZoneW)
#define Y_GRID (safeZoneY)
#define W_GRID (((safezoneW / safezoneH) min 1.2) / 40)
#define H_GRID ((((safezoneW / safezoneH) min 1.2) / 1.2) / 25)

#define W_GRP (10 * W_GRID)
#define H_GRP (safezoneh - 1.5 * H_GRID)

#define COMMIT_TIME 0.25
if (!hasInterface) exitWith {}; // Only instances with interface can run this script
//--- Controls
_map = finddisplay 12;
_ctrlMap = _map displayctrl 51;
_grpSearch = _map displayctrl IDC_RSCMAP_MRKGROUP;
_edSearch = _grpSearch controlsgroupctrl IDC_RSCMAP_MRKSEARCH;
_lbMarker = _grpSearch controlsgroupctrl IDC_RSCMAP_MRKLIST;
_cbShow = _grpSearch controlsgroupctrl IDC_RSCMAP_MRKSHOW;
_background = _grpSearch controlsgroupctrl IDC_RSCMAP_MRKBACKGROUND;
_btnEndSearch = _grpSearch controlsGroupCtrl IDC_RSCMAP_MRKENDSEARCH;

_fncUpdate = {
	//--- A function to search for new markers, due to performance concerns it is only updated when opening the map and when searching for something
	lbclear _lbMarker;
	_filter = ctrltext _edSearch;
	{
		_mrktext = markertext _x;
		_ind = _lbMarker lbAdd _mrktext;
		_lbMarker lbsettooltip [_ind,_mrktext];
		_lbMarker lbsetdata [_ind, _x];
		_mrkType = markertype _x;
		_icon = gettext (configfile >> "CfgMarkers" >> _mrkType >> "icon");
		_lbMarker lbsetpicture [_ind,_icon];
		//--- Get marker color
		_mrkColor = markercolor _x;
		_color = getarray(configfile >> "CfgMarkerColors" >> _mrkColor >> "color");
		if (_mrkColor == "Default") then {// Color has to be retrieved from the marker config itself
			_color = getarray(configfile >> "CfgMarkers" >> _mrkType >> "color");
		};
		_color = _color apply { // Some markers are dependent on user set colors which are saved as commands
			if (_x isequaltype "") then {call compile _x} else {_x};
		};
		_lbMarker lbsetpicturecolor [_ind,_color];
		_lbMarker lbsetpicturecolorselected [_ind,_color];
	} foreach (allmapmarkers select {
		tolower _filter in tolower markertext _x && // the filter from the search box
		count markertext _x > 0 && // has text
		markershape _x == "ICON" &&// text visible
		markeralpha _x > 0 // marker visible
	});
};
params ["_mode",["_this",[]]];
switch _mode do {
	case "init":{
		//--- Declare function for better performance
		TER_fnc_markerSearch = compileFinal preprocessfilelinenumbers "fnc\fn_markersearch.sqf";
		waituntil {!isnull finddisplay 12};
		_map = finddisplay 12;
		//--- Create controls
		// Controlsgroup as container for all other controls
		_grpSearch = _map ctrlcreate ["RscControlsGroupNoScrollbars",IDC_RSCMAP_MRKGROUP];
		_grpSearch ctrlsetposition [
			X_GRID - W_GRP,
			Y_GRID + 1.5 * H_GRID,
			W_GRP,
			H_GRP
		];
		_grpSearch ctrlcommit 0;
		_grpSearch ctrladdeventhandler ["MouseEnter",{
			systemchat str _this;
		}];
		// Black semi-transparent background
		_background = _map ctrlcreate ["RscText",IDC_RSCMAP_MRKBACKGROUND,_grpSearch];
		_background ctrlsetposition [0,0,W_GRP,H_GRP];
		_background ctrlsetbackgroundcolor [0,0,0,0.66];
		_background ctrlcommit 0;
		// Toggle visibility checkbox
		_cbShow = _map ctrlcreate ["RscCheckbox",IDC_RSCMAP_MRKSHOW,_grpSearch];
		_cbShow ctrlsetposition [
			0.1 * W_GRID,
			0,
			1 * W_GRID,
			1 * H_GRID
		];
		_cbShow ctrlcommit 0;
		_cbShow ctrlsettooltip "Toggle Marker Search";
		_cbShow cbsetchecked true;
		_cbShow ctrladdeventhandler ["CheckedChanged",{
			["toggleVisibility",_this] spawn SELF;
		}];
		// Button to clear the search field
		_btnEndSearch = _map ctrlCreate ["RscActivePicture",IDC_RSCMAP_MRKENDSEARCH,_grpSearch];
		_btnEndSearch ctrlSetPosition[
			W_GRP - 1 * W_GRID,
			0.1 * H_GRID,
			1 * W_GRID,
			1 * H_GRID
		];
		_btnEndSearch ctrlCommit 0;
		_btnEndSearch ctrlsettext "\a3\3den\data\Displays\Display3den\search_end_ca.paa";
		_btnEndSearch ctrlAddEventHandler ["ButtonClick",{
			["endSearch",_this] call SELF;
		}];
		// Textbox to search for marker names
		_edSearch = _map ctrlcreate ["RscEdit",IDC_RSCMAP_MRKSEARCH,_grpSearch];
		_edSearch ctrlsetposition [
			1.1 * W_GRID,
			0.1 * H_GRID,
			W_GRP - 2.3 * W_GRID,
			1 * H_GRID
		];
		_edSearch ctrlcommit 0;
		_edSearch ctrladdeventhandler ["KeyDown",{
			["keySearch",_this] spawn SELF;
		}];
		_edSearch ctrladdeventhandler ["SetFocus",{
			["focusSearch",_this] call SELF;
		}];
		// List with all markers
		_lbMarker = _map ctrlcreate ["RscListbox",IDC_RSCMAP_MRKLIST,_grpSearch];
		_lbMarker ctrlsetposition [
			0.1 * W_GRID,
			1.2 * H_GRID,
			W_GRP - 0.2 * W_GRID,
			H_GRP - 1.3 * H_GRID
		];
		_lbMarker ctrlcommit 0;
		addmissioneventhandler ["Map",{
			params ["_mapIsOpened", "_mapIsForced"];
			if (_mapIsOpened) then {
				["mapOpen",[]] call SELF;
			};
		}];
		_lbMarker ctrladdeventhandler ["LBSelChanged",{
			["mrkChanged",_this] call SELF;
		}];
	};
	//--- Map was opened, execute scripts
	case "mapOpen":{
		[] call _fncUpdate;
		["updateLoop"] spawn SELF;
	};
	//--- A marker is selected in the listbox
	case "mrkChanged":{
		params ["_lbMarker","_ind"];
		_mrk = _lbMarker lbdata _ind;
		//if (_mrk == _lbMarker getVariable ["selectedMarker",""]) exitWith {};
		mapanimadd [0.2, ctrlMapScale _ctrlMap, markerpos _mrk];
		mapanimcommit;
		_lbMarker setVariable ["selectedMarker",_mrk];
		//setMousePosition [0.5,0.5 + 1 * H_GRID];
	};
	//--- A button is pressed while the edit/searchbox is focused
	case "keySearch":{
		params ["_edSearch"];
		// No changes were made to the previous search, no need to update
		if (ctrltext _edSearch == _edSearch getvariable ["prevSearch",""]) exitwith {};
		_edSearch setvariable ["prevSearch",ctrltext _edSearch];
		[] call _fncUpdate;
	};
	//--- Let the list with markers appear/dissappear
	case "toggleVisibility":{
		params ["_cbShow","_checked"];
		_checked = _checked == 1;
		if (_checked) then {
			{
				_x ctrlsetpositionh (H_GRP);
				_x ctrlcommit COMMIT_TIME;
			} foreach [_grpSearch, _background];
			_lbMarker ctrlsetpositionh (H_GRP - 1.3 * H_GRID);
			_lbMarker ctrlcommit COMMIT_TIME;
			_lbMarker ctrlshow true;
		} else {
			{
				_x ctrlsetpositionh (1.2 * H_GRID);
				_x ctrlcommit COMMIT_TIME;
			} foreach [_grpSearch, _background];
			_lbMarker ctrlsetpositionh 0;
			_lbMarker ctrlcommit COMMIT_TIME;
			waituntil {ctrlcommitted _lbMarker};
			_lbMarker ctrlshow false;
		};
	};
	//--- Keep the list with markers up-to-date (distances, order)
	//--- TODO: Determine performance?
	case "updateLoop":{
		while {visibleMap} do {
			// Cyle through the listbox and update each entry
			for "_ind" from 0 to ((lbsize _lbMarker) -1) do {
				private _mrk = _lbMarker lbData _ind;
				private _d = player distance getMarkerPos _mrk;
				_lbMarker lbSetValue [_ind, _d];
				_lbMarker lbSetTextRight [_ind, format ["%1 m",round _d]];
			};
			lbSortByValue _lbMarker;
			/*
			// The following was meant to select the previously selected marker in the list but it doesn't work as nicely as expected. The listbox jumps to the entry making scrolling impossible

			for "_ind" from 0 to ((lbsize _lbMarker) -1) do {
				private _mrk = _lbMarker lbData _ind;
				if (_mrk == _lbMarker getVariable ["selectedMarker",""]) exitWith {
					_lbMarker lbSetCurSel _ind;
				};
			};
			*/
			private _frame = diag_frameno;
			//waitUntil {diag_frameno > _frame + 30};
			sleep 0.5;
		};
	};
	//--- The "X" next to the search field was pressed, clear and update search box
	case "endSearch":{
		params ["_btnEndSearch"];
		_edSearch ctrlSetText "";
		[] call _fncUpdate;
	};
};
true