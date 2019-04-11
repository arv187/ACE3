#include "script_component.hpp"
/*
 * Author: Glowbal, KoffeinFlummi, mharis001
 * Starts the treatment process.
 *
 * Arguments:
 * 0: Medic <OBJECT>
 * 1: Patient <OBJECT>
 * 2: Body Part <STRING>
 * 3: Treatment <STRING>
 *
 * Return Value:
 * Treatment Started <BOOL>
 *
 * Example:
 * [player, cursorObject, "Head", "BasicBandage"] call ace_medical_treatment_fnc_treatment
 *
 * Public: No
 */

params ["_medic", "_patient", "_bodyPart", "_classname"];

// Delay by a frame if cursor menu is open to prevent progress bar failing
if (uiNamespace getVariable [QEGVAR(interact_menu,cursorMenuOpened), false]) exitWith {
    [FUNC(treatment), _this] call CBA_fnc_execNextFrame;
};

if !(_this call FUNC(canTreat)) exitWith {false};

private _config = configFile >> QGVAR(actions) >> _classname;

// Get treatment time from config, exit if treatment time is zero
// Supports number config entries and string entries of code or missionNamespace variables
private _treatmentTime = 0;

if (isText (_config >> "treatmentTime")) then {
    _treatmentTime = getText (_config >> "treatmentTime");

    if (isNil _treatmentTime) then {
        _treatmentTime = compile _treatmentTime;
    } else {
        _treatmentTime = missionNamespace getVariable _treatmentTime;
    };

    if (_treatmentTime isEqualType {}) then {
        _treatmentTime = call _treatmentTime;
    };
} else {
    _treatmentTime = getNumber (_config >> "treatmentTime");
};

if (_treatmentTime == 0) exitWith {false};

// Consume one of the treatment items if needed
// Store item user so that used item can be returned on failure
private _userAndItem = if (GET_NUMBER_ENTRY(_config >> "consumeItem") == 1) then {
    [_medic, _patient, getArray (_config >> "items")] call FUNC(useItem);
} else {
    [objNull, ""]; // Treatment does not require items to be consumed
};

_userAndItem params ["_itemUser", "_usedItem"];

// Get treatment animation for the medic
private _medicAnim = if (_medic isEqualTo _patient) then {
    getText (_config >> ["animationMedicSelf", "animationMedicSelfProne"] select (stance _medic == "PRONE"));
} else {
    getText (_config >> ["animationMedic", "animationMedicProne"] select (stance _medic == "PRONE"));
};

_medic setVariable [QGVAR(selectedWeaponOnTreatment), weaponState _medic];

// Adjust animation based on the current weapon of the medic
private _wpn = ["non", "rfl", "lnr", "pst"] param [["", primaryWeapon _medic, secondaryWeapon _medic, handgunWeapon _medic] find currentWeapon _medic, "non"];
_medicAnim = [_medicAnim, "[wpn]", _wpn] call CBA_fnc_replace;

// This animation is missing, use alternative
if (_medicAnim == "AinvPknlMstpSlayWlnrDnon_medic") then {
    _medicAnim = "AinvPknlMstpSlayWlnrDnon_medicOther";
};

// Determine the animation length
private _animDuration = GVAR(animDurations) getVariable _medicAnim;

// These animations have transitions that take a bit longer...
if (weaponLowered _medic) then {
    _animDuration = _animDuration + 0.5;

    // Fix problems with lowered weapon transitions by raising the weapon first
    if (currentWeapon _medic != "" && {_medicAnim != ""}) then {
        _medic action ["WeaponInHand", _medic];
    };
};

if (binocular _medic != "" && {binocular _medic == currentWeapon _medic}) then {
    _animDuration = _animDuration + 1;
};

// Play treatment animation for medic and determine the ending animation
if (vehicle _medic == _medic && {_medicAnim != ""}) then {
    private _endInAnim = "AmovP[pos]MstpS[stn]W[wpn]Dnon";

    private _pos = ["knl", "pne"] select (stance _medic == "PRONE");
    private _stn = "non";

    if (_wpn != "non") then {
        _stn = ["ras", "low"] select (weaponLowered _medic);
    };

    _endInAnim = [_endInAnim, "[pos]", _pos] call CBA_fnc_replace;
    _endInAnim = [_endInAnim, "[stn]", _stn] call CBA_fnc_replace;
    _endInAnim = [_endInAnim, "[wpn]", _wpn] call CBA_fnc_replace;

    [_medic, _medicAnim] call EFUNC(common,doAnimation);
    [_medic, _endInAnim] call EFUNC(common,doAnimation);
    _medic setVariable [QGVAR(endInAnim), _endInAnim];

    // Speed up animation based on treatment time
    [QEGVAR(common,setAnimSpeedCoef), [_medic, _animDuration / _treatmentTime]] call CBA_fnc_globalEvent;
};

// Play a random treatment sound globally if defined
if (isArray (_config >> "sounds")) then {
    selectRandom getArray (_config >> "sounds") params ["_file", ["_volume", 1], ["_pitch", 1], ["_distance", 10]];
    playSound3D [_file, objNull, false, getPosASL _medic, _volume, _pitch, _distance];
};

GET_FUNCTION(_callbackStart,_config >> "callbackStart");
GET_FUNCTION(_callbackProgress,_config >> "callbackProgress");

if (_callbackProgress isEqualTo {}) then {
    _callbackProgress = {true};
};

[_medic, _patient, _bodyPart, _classname, _itemUser, _usedItem] call _callbackStart;

[
    _treatmentTime,
    [_medic, _patient, _bodyPart, _classname, _itemUser, _usedItem],
    FUNC(treatmentSuccess),
    FUNC(treatmentFailure),
    getText (_config >> "displayNameProgress"),
    _callbackProgress,
    ["isNotInside"]
] call EFUNC(common,progressBar);

true
