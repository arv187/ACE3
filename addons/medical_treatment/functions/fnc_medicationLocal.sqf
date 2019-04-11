#include "script_component.hpp"
/*
 * Author: Glowbal, mharis001
 * Local callback for administering medication to a patient.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Body Part <STRING>
 * 2: Treatment <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "RightArm", "Morphine"] call ace_medical_treatment_fnc_medicationLocal
 *
 * Public: No
 */

// todo: move this macro to script_macros_medical.hpp?
#define MORPHINE_PAIN_SUPPRESSION 0.6

params ["_patient", "_bodyPart", "_classname"];

// Medication has no effects on dead units
if (!alive _patient) exitWith {};

// Exit with basic medication handling if advanced medication not enabled
if (!GVAR(advancedMedication)) exitWith {
    switch (_classname) do {
        case "Morphine": {
            private _painSuppress = GET_PAIN_SUPPRESS(_patient);
            _patient setVariable [VAR_PAIN_SUPP, (_painSuppress + MORPHINE_PAIN_SUPPRESSION) min 1, true];
        };
        case "Epinephrine": {
            [QEGVAR(medical,WakeUp), _patient] call CBA_fnc_localEvent;
        };
    };
};

// Handle tourniquet on body part blocking blood flow at injection site
private _partIndex = ALL_BODY_PARTS find toLower _bodyPart;

if (HAS_TOURNIQUET_APPLIED_ON(_patient,_partIndex)) exitWith {
    private _occludedMedications = _patient getVariable [QEGVAR(medical,occludedMedications), []];
    _occludedMedications pushBack [_partIndex, _classname];
    _patient setVariable [QEGVAR(medical,occludedMedications), _occludedMedications, true];
};

// Get adjustment attributes for used medication
private _defaultConfig = configFile >> QUOTE(ADDON) >> "Medication";
private _medicationConfig = _defaultConfig >> _classname;

private _painReduce             = GET_NUMBER(_medicationConfig >> "painReduce",getNumber (_defaultConfig >> "painReduce"));
private _timeInSystem           = GET_NUMBER(_medicationConfig >> "timeInSystem",getNumber (_defaultConfig >> "timeInSystem"));
private _timeTillMaxEffect      = GET_NUMBER(_medicationConfig >> "timeTillMaxEffect",getNumber (_defaultConfig >> "timeTillMaxEffect"));
private _maxDose                = GET_NUMBER(_medicationConfig >> "maxDose",getNumber (_defaultConfig >> "maxDose"));
private _viscosityChange        = GET_NUMBER(_medicationConfig >> "viscosityChange",getNumber (_defaultConfig >> "viscosityChange"));
private _hrIncreaseLow          = GET_ARRAY(_medicationConfig >> "hrIncreaseLow",getArray (_defaultConfig >> "hrIncreaseLow"));
private _hrIncreaseNormal       = GET_ARRAY(_medicationConfig >> "hrIncreaseNormal",getArray (_defaultConfig >> "hrIncreaseNormal"));
private _hrIncreaseHigh         = GET_ARRAY(_medicationConfig >> "hrIncreaseHigh",getArray (_defaultConfig >> "hrIncreaseHigh"));
private _incompatableMedication = GET_ARRAY(_medicationConfig >> "incompatableMedication",getArray (_defaultConfig >> "incompatableMedication"));

private _heartRate = GET_HEART_RATE(_patient);
private _hrIncrease = [_hrIncreaseLow, _hrIncreaseNorm, _hrIncreaseHigh] select (floor ((0 max _heartRate min 110) / 55));
_hrIncrease params ["_minIncrease", "_maxIncrease"];
private _heartRateChange = _minIncrease + random (_maxIncrease - _minIncrease);

// todo: finish when medication rework PR is complete
