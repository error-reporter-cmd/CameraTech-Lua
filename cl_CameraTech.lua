
FixedANPRRadius = 28.0
FixedANPRAlertsToggle = false;
BlipsCreated = false;
FocusedPlate = nil;
RouteBlip = nil;
ANPRHitChance = 100;
lastFixedPlate = nil;
usingJsonFile = true;
currentANPRModelsJsonString = nil;
ForceFocusedAnpr = false;
VehicleANPRModels = {}
FixedANPRModels = {}
local ANPRCooldowns = {} -- [plate] = timestamp
local ANPR_COOLDOWN_TIME = 5000 -- 5 seconds

debug = false




-- helpful snippets
local ped = PlayerPedId()

-- Shapetest.cs was ignored

print("CameraTech by Albo1125. (recoded to lua)")
TriggerEvent('chat:addSuggestions', {
    { name = '/anpr', help = 'Toggles the ANPR interface' },
{ name = '/vehanpr', help = 'Toggles the vehicle ANPR system' },
    { name = '/fixedanpr', help = 'Toggles the fixed ANPR system' },
    { name = '/setplateinfo', help = 'Sets markers for the specified plate', params = { { name = 'param', help = 'Type the plate, followed by semicolon (;), followed by the ANPR markers (leave markers blank to remove). Ex: AB12CDE;Stolen' } }},
    { name = '/setvehinfo', help = "Sets markers for the plate of the vehicle you're currently in", params = { { name = "markers", help = "The markers for this vehicle's plate, leave blank to remove from the system. Ex: Stolen" } } } })


local function IsPlayerInValidVehicle()
    return DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false)
end


RegisterNetEvent("CameraTech:ClUpdateVehicleInfo")
AddEventHandler("CameraTech:ClUpdateVehicleInfo", function(plateinfo)
    if not IsPlayerInValidVehicle() then return end
    local plate = GetVehicleNumberPlateText(GetVehiclePedIsUsing(ped)):gsub("%s+", "")
    TriggerServerEvent("CameraTech:UpdateVehicleInfo", plate, plateinfo)
    local msg = "Plate: " .. plate .. (plateinfo and ". Info: " .. plateinfo or " No Info")
    TriggerEvent("chat:addMessage", { color = {0, 0, 0}, args = { "System", msg } })
end)


RegisterNetEvent("CameraTech:ClFixedANPRAlert")
AddEventHandler("CameraTech:ClFixedANPRAlert", function(colour, modelName, anprname, dir, plate)
    local veh = GetVehiclePedIsIn(ped, false)

    if MasterInterfaceToggle and FixedANPRAlertsToggle and IsPlayerInValidVehicle() then
        if FocusedPlate ~= nil and FocusedPlate == plate then
            TriggerEvent("chat:addMessage", { color = {0, 191, 255}, args = {"Fixed ANPR", colour .. " " .. modelName .. ". " .. plate .. ". " .. anprname .. " (" .. dir .. "). ^*Markers: ^r" .. (PlateInfo[plate] or "None")} })
            PlayANPRAlertSound(false)
            if BlipsCreated then
                local fixedanpr = nil
                for _, cam in ipairs(FixedANPRCameras) do
                    if cam.Name == anprname then
                        fixedanpr = cam
                        break
                    end
                end
                if fixedanpr and fixedanpr.blip and DoesBlipExist(fixedanpr.blip) then
                    SetBlipRoute(fixedanpr.blip, true)
                    RouteBlip = fixedanpr.blip
                end
            end
            ANPRInterface.FixedANPRHeaderString = anprname .. " (" .. dir .. ")"
            ANPRInterface.FixedANPRInfo = colour .. " " .. modelName .. ". " .. plate .. "."
            ANPRInterface.FixedANPRMarkers = "~r~" .. (PlateInfo[plate] or "")
            lastFixedPlate = plate
            ANPRInterface.FlashFixedANPR()
        elseif FocusedPlate == nil and not ForceFocusedAnpr then
            TriggerEvent("chat:addMessage", { color = {0, 191, 255}, args = {"Fixed ANPR", colour .. " " .. modelName .. ". " .. plate .. ". " .. anprname .. " (" .. dir .. "). ^*Markers: ^r" .. (PlateInfo[plate] or "None")} })
            PlayANPRAlertSound(false)
            ANPRInterface.FixedANPRHeaderString = anprname .. " (" .. dir .. ")"
            ANPRInterface.FixedANPRInfo = colour .. " " .. modelName .. ". " .. plate .. "."
            ANPRInterface.FixedANPRMarkers = "~r~" .. (PlateInfo[plate] or "")
            lastFixedPlate = plate
            ANPRInterface.FlashFixedANPR()
        end
    end
end)


RegisterNetEvent("CameraTech:FixedANPRToggle")
AddEventHandler("CameraTech:FixedANPRToggle", function()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if FixedANPRAlertsToggle then
        toggleFixedANPR(false)
        ShowNotification("Fixed ANPR alerts deactivated.")
    elseif vehicle and DoesEntityExist(vehicle) then
        local model = GetEntityModel(vehicle)

        if FixedANPRModels[model] then
            toggleFixedANPR(true)
            ShowNotification("Fixed ANPR alerts activated.")
            if not MasterInterfaceToggle then
                ANPRInterface.toggleMasterInterface(true)
            end
            if not VehicleANPRModels[model] then
                ToggleVehicleANPR(false)
            end
        else
            ShowNotification("This vehicle does not have Fixed ANPR technology.")
        end
    end
end)

RegisterNetEvent("CameraTech:SyncPlateInfo")
AddEventHandler("CameraTech:SyncPlateInfo", function(plateinfo)
    PlateInfo = {}
    if plateinfo then
        for key, value in pairs(plateinfo) do
            PlateInfo[key] = tostring(value)
        end
    end
end)
RegisterNetEvent("CameraTech:FocusANPR")

AddEventHandler("CameraTech:FocusANPR", function(plate)
    if not IsPlayerInValidVehicle() then return end
    if plate == nil then
        if FocusedPlate == bil then FocusedPlate = lastFixedPlate
        else FocusedPlate = nil
        end
    else FocusedPlate = plate
    end

    if FocusedPlate == nil then
        TriggerEvent("chat:addMessage", { color = {0, 0, 0}, args = {"Fixed ANPR", "Removed fixed ANPR plate focus."} })
        if RouteBlip and RouteBlip.Exists and RouteBlip:Exists() then
            RouteBlip.ShowRoute = false
            RouteBlip = nil
        end
    else
        TriggerEvent("chat:addMessage", { color = {0, 0, 0}, args = {"Fixed ANPR", "Fixed ANPR plate focus: " .. FocusedPlate} })
    end
end)


function populateANPRModels(jsonString)
    local allModels = json.decode(jsonString)

    for _, m in ipairs(allModels) do
        local modelName = m.ModelName or ""; local accessType = string.lower(m.ANPRAccessType or ""); local modelHash = GetHashKey(modelName)

        if accessType == "fixed only" or accessType == "full" then
            FixedANPRModels[modelHash] = true
        end

        if accessType == "vehicle only" or accessType == "full" then
            VehicleANPRModels[modelHash] = true
        end
    end
end

function RemoveANPRBlips()
    for _, anpr in ipairs(FixedANPRCameras) do
        if anpr.blip and DoesBlipExist(anpr.blip) then
            SetBlipRoute(anpr.blip, false)
            RemoveBlip(anpr.blip)
        end
        anpr.blip = nil
    end
    BlipsCreated = false
end



RegisterNetEvent("CameraTech:ANPRModelsJsonString")
AddEventHandler("ANPRModelsJsonString", function(jsonString, runAnprCommandEnable)
    if usingJsonFile then return end
    if currentANPRModelsJsonString ~= jsonString then
        populateANPRModels(jsonString)
        currentANPRModelsJsonString = jsonString
    end
    if Active and ANPRvehicle and not VehicleANPRModels[ANPRvehicle.Model] then ToggleVehicleANPR(false); end
    if FixedANPRAlertsToggle and ANPRvehicle and not FixedANPRModels[ANPRvehicle.Model] then toggleFixedANPR(false); end
end)


if (runAnprCommandEnable) then ANPRInterface.runAnprCommandEnable() end

resourceName = GetCurrentResourceName()
anprvehs = LoadResourceFile(resourceName, "anprvehicles.json")

if not anprvehs:match("^%s*$") then
    usingJsonFile = true
    print("Loading ANPR vehicles from anprvehicles.json file")
    populateANPRModels(anprvehs)
end

fixedanprjson = LoadResourceFile(resourceName, "fixedanprcameras.json")
FixedANPRCameras = json.decode(fixedanprjson)

ForceFocusedAnpr = GetResourceMetadata(resourceName, "ForceFocusedAnpr", 0) == "true"

function toggleFixedANPR(toggle)
    if (not toggle) then
        FixedANPRAlertsToggle = false
        RemoveANPRBlips()
    else if (toggle) then
        FixedANPRAlertsToggle = true
        CreateFixedANPRBlips()
    end
end
end

function DegreesToCardinal(degrees)
    local cardinals = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
    local index = math.floor((degrees % 360) / 45 + 0.5) % 8 + 1
    return cardinals[index]
end

if debug then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)

            --if IsControlJustReleased(1, 120) then -- or try 38 for E key
                --if type(PlateInfo) == "table" then
                    --exports['bs-tableviewer']:debugTable(PlateInfo)
                --else
                    --print("PlateInfo is invalid:", PlateInfo)
                --end
            --end
        end
    end)
end


function Main()
    local lastTriggeredANPRCamera = nil
    local timeLastTriggeredANPRCamera = GetGameTimer()
    local lastTriggeredDir = ""

    local lastBlockedFixedANPR = nil
    local timeLastBlockedANPR = GetGameTimer()

    while true do
        Citizen.Wait(5)

        local veh = GetVehiclePedIsIn(ped, false)
        if ped and veh then

            -- Handle ANPR Interface state
            if not MasterInterfaceToggle and ANPRvehicle and veh == ANPRvehicle then
                ANPRInterface.toggleMasterInterface(true)
                ShowNotification("ANPR Activated")
            elseif MasterInterfaceToggle and veh ~= ANPRvehicle then
                MasterInterfaceToggle = false
            end

            -- Handle ANPR Blips
            if BlipsCreated and (not FixedANPRAlertsToggle or not MasterInterfaceToggle) then
                RemoveANPRBlips()
            elseif FixedANPRAlertsToggle and MasterInterfaceToggle and not BlipsCreated then
                CreateFixedANPRBlips()
            end

            -- Clear route if close
            if RouteBlip and DoesBlipExist(RouteBlip) and #(GetEntityCoords(veh) - GetBlipCoords(RouteBlip)) < 140.0 then
                SetBlipRoute(RouteBlip, false)
                RemoveBlip(RouteBlip)
                RouteBlip = nil
            end

            -- Fixed ANPR Detection
            if GetPedInVehicleSeat(veh, -1) == ped and GetEntitySpeed(veh) > 1 then
                local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
                
                if PlateInfo[plate] then
                    local vehPos = GetEntityCoords(veh)
                    local closest = nil
                    local minDist = math.huge
                    

                    for _, anpr in ipairs(FixedANPRCameras) do
                        local dist = #(vector3(anpr.X, anpr.Y, anpr.Z) - vehPos)
                        if dist < minDist then
                            closest = anpr
                            minDist = dist
                        end
                    end

                    local currenttime = GetGameTimer()

                    if closest then
                        local zDiff = math.abs(closest.Z - vehPos.z)
                        local dir = DegreesToCardinal(GetEntityHeading(veh))

                        if minDist <= FixedANPRRadius and zDiff < 3.5 and 
                           (lastTriggeredANPRCamera ~= closest or (currenttime - timeLastTriggeredANPRCamera) > 20000 or lastTriggeredDir ~= dir) then

                            if (lastBlockedFixedANPR ~= closest or os.difftime(currenttime - timeLastBlockedANPR) > 120000)
                                and math.random(0, 100) < ANPRHitChance then

                                Citizen.Wait(1300)
                                dir = DegreesToCardinal(GetEntityHeading(veh))

                                local model = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                                local colour = GetVehicleColour(veh)

                                TriggerServerEvent("CameraTech:FixedANPRAlert", colour.PrimarySimple, model, closest.Name, dir, plate, closest.X, closest.Y, closest.Z)
                                lastTriggeredANPRCamera = closest
                                timeLastTriggeredANPRCamera = GetGameTimer()
                                lastTriggeredDir = dir
                                lastBlockedFixedANPR = nil
                            else
                                if lastBlockedFixedANPR ~= closest then
                                    timeLastBlockedANPR = GetGameTimer()
                                end
                                lastBlockedFixedANPR = closest
                            end
                        end
                    end
                end
            end
        else
            if BlipsCreated then
                RemoveANPRBlips()
            end

            if MasterInterfaceToggle then
                MasterInterfaceToggle = false
            end
        end
    end
end





function PlayANPRAlertSound(inVehicle)
    if (inVehicle) then
        PlayInteractSound("VehicleANPR", 0.7)
    else
        PlayInteractSound("VehicleANPR", 0.7)
    end
end

function CreateFixedANPRBlips()
    RemoveANPRBlips()

    for _, anpr in ipairs(FixedANPRCameras) do
        local blip = AddBlipForCoord(anpr.X, anpr.Y, anpr.Z)
        SetBlipSprite(blip, 744)            -- 43 is Camera
        SetBlipColour(blip, 0)             -- 0 = White
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("ANPR")
        EndTextCommandSetBlipName(blip)
        anpr.blip = blip
    end

    BlipsCreated = true
end



function PlayInteractSound(soundname, volume)
    TriggerEvent("InteractSound_CL:PlayOnOne", soundname, volume)
end

----------------------------
PrimaryColour = -1
SecondaryColour = -1

SimpleMap = {
    [-1] = "Unknown",

    [0] = "Black", [1] = "Black", [2] = "Steel", [3] = "Silver",
    [4] = "Silver", [5] = "Silver", [6] = "Steel", [7] = "Silver",
    [8] = "Silver", [9] = "Silver", [10] = "Steel", [11] = "Black",

    [12] = "Black", [13] = "Gray", [14] = "Gray", [15] = "Black",
    [16] = "Black", [17] = "Gray", [18] = "Silver", [19] = "Steel",
    [20] = "Gray", [21] = "Black", [22] = "Gray", [23] = "Silver",
    [24] = "Silver", [25] = "Silver", [26] = "Silver",

     [27] = "Red", [28] = "Red", [29] = "Red", [30] = "Red",
    [31] = "Red", [32] = "Red", [33] = "Red", [34] = "Red",
    [35] = "Red", [36] = "Orange", [37] = "Gold", [38] = "Orange",
    [39] = "Red", [40] = "Red", [41] = "Orange", [42] = "Yellow",
    [43] = "Red", [44] = "Red", [45] = "Red", [46] = "Red",
    [47] = "Red", [48] = "Red",

    [49] = "Green", [50] = "Green", [51] = "Green", [52] = "Green",
    [53] = "Green", [54] = "Green", [55] = "Green",
    [56] = "Green", [57] = "Green", [58] = "Green", [59] = "Green",
    [60] = "Green",

    [61] = "Blue", [62] = "Blue", [63] = "Blue", [64] = "Blue",
    [65] = "Blue", [66] = "Blue", [67] = "Blue", [68] = "Blue",
    [69] = "Blue", [70] = "Blue", [71] = "Blue", [72] = "Blue",
    [73] = "Blue", [74] = "Blue", [75] = "Blue", [76] = "Blue",
    [77] = "Blue", [78] = "Blue", [79] = "Blue", [80] = "Blue",
    [81] = "Blue", [82] = "Blue", [83] = "Blue", [84] = "Blue",
    [85] = "Blue", [86] = "Blue", [87] = "Blue",

    [88] = "Yellow", [89] = "Yellow", [90] = "Brown", [91] = "Yellow",
    [92] = "Green", [93] = "Beige", [94] = "Beige", [95] = "Beige",
    [96] = "Brown", [97] = "Brown", [98] = "Brown", [99] = "Beige",
    [100] = "Brown", [101] = "Brown", [102] = "Brown", [103] = "Brown",
    [104] = "Brown", [105] = "Beige", [106] = "Beige", [107] = "Beige",
    [108] = "Brown", [109] = "Beige",

    [110] = "White", [111] = "White", [112] = "Beige", [113] = "Brown",
    [114] = "Brown", [115] = "Beige", [116] = "Steel", [117] = "Steel",
    [118] = "Aluminium", [119] = "Aluminium", [120] = "White",
    [121] = "White", [122] = "Orange", [123] = "Orange",
    [124] = "Green", [125] = "Yellow", [126] = "Blue", [127] = "Green",
    [128] = "Brown", [129] = "Orange", [130] = "White",
    [131] = "White", [132] = "Green", [133] = "White",

    [134] = "Pink", [135] = "Pink", [136] = "Pink",
    [137] = "Orange", [138] = "Green", [139] = "Blue",
    [140] = "Blue", [141] = "Purple", [142] = "Red",
    [143] = "Green", [144] = "Purple", [145] = "Blue",
    [146] = "Black", [147] = "Purple", [148] = "Purple",
    [149] = "Red", [150] = "Green", [151] = "Green",
    [152] = "Brown", [153] = "Brown", [154] = "Green",
    [155] = "Steel", [156] = "Blue", [157] = "Gold", [158] = "Gold",
    [159] = "Gray"
}


EPaint = {
  [-1] = "Unknown",
  [0] = "Metallic Black",
  [1] = "Metallic Graphite Black",
  [2] = "Metallic Black Steel",
  [3] = "Metallic Dark Silver",
  [4] = "Metallic Silver",
  [5] = "Metallic Bluish Silver",
  [6] = "Metallic Rolled Steel",
  [7] = "Metallic Shadow Silver",
  [8] = "Metallic Stone Silver",
  [9] = "Metallic Midnight Silver",
  [10] = "Metallic Cast Iron Silver",
  [11] = "Metallic Anhracite Black",

  [12] = "Matte Black",
  [13] = "Matte Gray",
  [14] = "Matte Light Grey",
  [15] = "Util Black",
  [16] = "Util Black Poly",
  [17] = "Util Dark Silver",
  [18] = "Util Silver",
  [19] = "Util Gun Metal",
  [20] = "Util Shadow Silver",

  [21] = "Worn Black",
  [22] = "Worn Graphite",
  [23] = "Worn Silver Grey",
  [24] = "Worn Silver",
  [25] = "Worn Blue Silver",
  [26] = "Worn Shadow Silver",

  [27] = "Metallic Red",
  [28] = "Metallic Torino Red",
  [29] = "Metallic Formula Red",
  [30] = "Metallic Blaze Red",
  [31] = "Metallic Grace Red",
  [32] = "Metallic Garnet Red",
  [33] = "Metallic Desert Red",
  [34] = "Metallic Cabernet Red",
  [35] = "Metallic Candy Red",
  [36] = "Metallic Sunrise Orange",
  [37] = "Metallic Classic Gold",
  [38] = "Metallic Orange",

  [39] = "Matte Red",
  [40] = "Matte Dark Red",
  [41] = "Matte Orange",
  [42] = "Matte Yellow",

  [43] = "Util Red",
  [44] = "Util Bright Red",
  [45] = "Util Garnet Red",

  [46] = "Worn Red",
  [47] = "Worn Golden Red",
  [48] = "Worn Dark Red",

  [49] = "Metallic Dark Green",
  [50] = "Metallic Racing Green",
  [51] = "Metallic Sea Green",
  [52] = "Metallic Olive Green",
  [53] = "Metallic Green",
  [54] = "Metallic Gasoline Blue Green",
  [55] = "Matte Lime Green",
  [56] = "Util Dark Green",
  [57] = "Util Green",
  [58] = "Worn Dark Green",
  [59] = "Worn Green",
  [60] = "Worn Sea Wash",

  [61] = "Metallic Midnight Blue",
  [62] = "Metallic Dark Blue",
  [63] = "Metallic Saxony Blue",
  [64] = "Metallic Blue",
  [65] = "Metallic Mariner Blue",
  [66] = "Metallic Harbor Blue",
  [67] = "Metallic Diamond Blue",
  [68] = "Metallic Surf Blue",
  [69] = "Metallic Nautical Blue",
  [70] = "Metallic Bright Blue",
  [71] = "Metallic Purple Blue",
  [72] = "Metallic Spinnaker Blue",
  [73] = "Metallic Ultra Blue",

  [74] = "Metallic Bright Blue",  -- duplicated names occasionally
  [75] = "Util Dark Blue",
  [76] = "Util Midnight Blue",
  [77] = "Util Blue",
  [78] = "Util Sea Foam Blue",
  [79] = "Util Lightning Blue",
  [80] = "Util Maui Blue Poly",
  [81] = "Util Bright Blue",
  [82] = "Matte Dark Blue",
  [83] = "Matte Blue",
  [84] = "Matte Midnight Blue",
  [85] = "Worn Dark Blue",
  [86] = "Worn Blue",
  [87] = "Worn Light Blue",

  [88] = "Metallic Taxi Yellow",
  [89] = "Metallic Race Yellow",
  [90] = "Metallic Bronze",
  [91] = "Metallic Yellow Bird",
  [92] = "Metallic Lime",
  [93] = "Metallic Champagne",
  [94] = "Metallic Pueblo Beige",
  [95] = "Metallic Dark Ivory",
  [96] = "Metallic Choco Brown",
  [97] = "Metallic Golden Brown",
  [98] = "Metallic Light Brown",
  [99] = "Metallic Straw Beige",
  [100] = "Metallic Moss Brown",
  
  [101] = "Metallic Biston Brown",
  [102] = "Metallic Beechwood Brown",
  [103] = "Metallic Dark Beechwood",
  [104] = "Metallic Choco Orange",
  [105] = "Metallic Beach Sand",
  [106] = "Metallic Sun Bleeched Sand",
  [107] = "Metallic Cream",
  [108] = "Util Brown",
  [109] = "Util Light Brown",
  [110] = "Metallic White",
  
  [111] = "Metallic Frost White",
  [112] = "Worn Honey Beige",
  [113] = "Worn Brown",
  [114] = "Worn Dark Brown",
  [115] = "Worn Straw Beige",
  [116] = "Brushed Steel",
  [117] = "Brushed Black Steel",
  [118] = "Brushed Aluminium",
  [119] = "Chrome",
  [120] = "Worn Off White",
  [121] = "Util Off White",
  [122] = "Worn Orange",
  [123] = "Worn Light Orange",
  [124] = "Metallic Securicor Green",
  [125] = "Worn Taxi Yellow",
  [126] = "Police Car Blue",
  [127] = "Matte Green",
  [128] = "Matte Brown",
  [129] = "Worn Orange",
  [130] = "Matte White",
  [131] = "Worn White",
  [132] = "Worn Olive Army Green",
  [133] = "Pure White",
  [134] = "Hot Pink",
  [135] = "Salmon Pink",
  [136] = "Metallic Vermillion Pink",
  [137] = "Orange",
  [138] = "Green",
  [139] = "Blue",
  [140] = "Metallic Black Blue",
  [141] = "Metallic Black Purple",
  [142] = "Metallic Black Red",
  [143] = "Hunter Green",
  [144] = "Metallic Purple",
  [145] = "Metallic Very Dark Blue",
  [146] = "Modshop Black",
  [147] = "Matte Purple",
  [148] = "Matte Dark Purple",
  [149] = "Metallic Lava Red",
  [150] = "Matte Forest Green",
  [151] = "Matte Olive Drab",
  [152] = "Matte Desert Brown",
  [153] = "Matte Desert Tan",
  [154] = "Matte Foliage Green",
  [155] = "Default Alloy",
  [156] = "Epsilon Blue",
  [157] = "Pure Gold",
  [158] = "Brushed Gold",
  [159] = "??? Unlisted/Future"
}





function GetVehicleColour(handle)
    local primary, secondary = GetVehicleColours(handle)
    return {
        PrimaryColour      = EPaint[primary] or "Unknown",
        SecondaryColour    = EPaint[secondary] or "Unknown",
        PrimarySimple      = SimpleMap[primary] or "Unknown",
        SecondarySimple    = SimpleMap[secondary] or "Unknown",
    }
end

------------------------ cs

Active = false;
frontRange = 75
backRange = -75
raycastRadius = 6.2
checkedPlates = {}





AddEventHandler("fivemskillsreset", function(dynamic)
    ANPRInterface.toggleMasterInterface(false)
    ToggleVehicleANPR(false)
    toggleFixedANPR(false)
end)

RegisterNetEvent("CameraTech:ToggleVehicleANPR")
AddEventHandler("CameraTech:ToggleVehicleANPR", function(dynamic)

    if (active) then
        ToggleVehicleANPR(false)
        ShowNotification("Vehicle ANPR deactivated.")
        active = false
    else
        local vehicle = GetVehiclePedIsIn(ped, false)
        local model = GetEntityModel(vehicle)
        if VehicleANPRModels[model] then
            active = true
            ToggleVehicleANPR(true)
            ShowNotification("Vehicle ANPR activated.")
            if (not MasterInterfaceToggle) then 
                ANPRInterface.toggleMasterInterface(true)
            end
            if (not FixedANPRModels[model]) then
                toggleFixedANPR(false)
            end
        else
            ShowNotification("This vehicle does not have Vehicle ANPR technology.")
        end
    end
end)

RegisterNetEvent("CameraTech:ReadPlateInFront")
AddEventHandler("CameraTech:ReadPlateInFront", function(dynamic)
    ReadPlateFront()
end)

RegisterNetEvent("CameraTech:SyncPlateInfo")
AddEventHandler("CameraTech:SyncPlateInfo", function(plateinfo)
    for k in pairs(checkedPlates) do
        checkedPlates[k] = nil
    end
end)


function doShapeTest(cameraname, startCoords, endCoords, vehicle, left)
    local rayHandle = StartShapeTestRay(startCoords, endCoords, 2, vehicle, 0)
    local result, hit, endPos, normal, hitEntity = GetShapeTestResult(rayHandle)

    local stest = {
        hit = hit == 1,
        hitEntity = hitEntity,
        from = startCoords
    }

    CheckANPRShapeTest(cameraname, stest, vehicle, left)
end

function RunChecks()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10)
            ped = PlayerPedId()

            local vehicle = GetVehiclePedIsIn(ped, false)

            if IsPlayerInValidVehicle() then
                if debug then
                    if IsControlPressed(0, 38) then -- 'E' key
                        print("E pressed")
                        print(tostring(MasterInterfaceToggle) .. " <- interface Active -> " .. tostring(Active) .. " Vehicle -> " .. tostring(vehicle) .. " ANPRvehicle -> " .. tostring(ANPRvehicle))
                    end
                end

                if MasterInterfaceToggle and Active and vehicle == ANPRvehicle then
                    -- FRONT
                    local frontStart = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, raycastRadius - 0.5, 0.0)
                    local frontLeftEnd = GetOffsetFromEntityInWorldCoords(vehicle, -raycastRadius + 0.1, frontRange, 0.0)
                    local frontRightEnd = GetOffsetFromEntityInWorldCoords(vehicle, raycastRadius - 0.1, frontRange, 0.0)

                    doShapeTest("Front ANPR (L)", frontStart, frontLeftEnd, vehicle, true)
                    doShapeTest("Front ANPR (R)", frontStart, frontRightEnd, vehicle, false)

                    -- REAR
                    local backStart = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -raycastRadius + 0.5, 0.0)
                    local backLeftEnd = GetOffsetFromEntityInWorldCoords(vehicle, -raycastRadius + 0.1, backRange, 0.0)
                    local backRightEnd = GetOffsetFromEntityInWorldCoords(vehicle, raycastRadius - 0.1, backRange, 0.0)

                    doShapeTest("Rear ANPR (L)", backStart, backLeftEnd, vehicle, true)
                    doShapeTest("Rear ANPR (R)", backStart, backRightEnd, vehicle, false)
                end
            else
                if MasterInterfaceToggle then
                    ANPRInterface.toggleMasterInterface(false)
                end
                if Active then
                    ToggleVehicleANPR(false)
                end
                if FixedANPRAlertsToggle then
                    toggleFixedANPR(false)
                end
            end
        end
    end)
end

RunChecks()

function ReadPlateFront()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local frontCoordA = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 1.0, 0.0)
        local frontCoordB = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 30.0, 0.0)
        local rayHandle = StartShapeTestCapsule(frontCoordA.x, frontCoordA.y, frontCoordA.z, frontCoordB.x, frontCoordB.y, frontCoordB.z, 3.0, 10, vehicle, 7)
        local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

        if hit == 1 and IsEntityAVehicle(entityHit) then
            local plate = GetVehicleNumberPlateText(entityHit)
            local trimmedPlate = plate:gsub("^%s*(.-)%s*$", "%1")
            TriggerEvent("chat:addMessage", { color = {0, 191, 255}, args = {"Read Plate (Front)", trimmedPlate .. "."}})
        end
    end
end



function CheckANPRShapeTest(cameraname, stest, originVeh, left)    
    if stest.hit and IsEntityAVehicle(stest.hitEntity) then
        local hitVeh = stest.hitEntity
        local hitVehPos = GetEntityCoords(hitVeh)
        local originLeft = GetOffsetFromEntityInWorldCoords(originVeh, -1.0, 0.0, 0.0)
        local originRight = GetOffsetFromEntityInWorldCoords(originVeh, 1.0, 0.0, 0.0)

        local distLeft = #(originLeft - hitVehPos)
        local distRight = #(originRight - hitVehPos)
        local positionedRight = distLeft > distRight

        -- Ignore vehicle on the wrong side
        if (left and positionedRight) or (not left and not positionedRight) then
            return
        end

        local modelHash = GetEntityModel(hitVeh)
        local modelName = GetDisplayNameFromVehicleModel(modelHash)
        local plate = GetVehicleNumberPlateText(hitVeh):gsub(" ", "")

        
        local now = GetGameTimer()
        if ANPRCooldowns[plate] and now - ANPRCooldowns[plate] < ANPR_COOLDOWN_TIME then
            return 
        end
        ANPRCooldowns[plate] = now

        if PlateInfo and PlateInfo[plate] then
            local from = stest.from or GetEntityCoords(originVeh)
            local distance = #(from - hitVehPos)
            local colour = GetVehicleColour(hitVeh).PrimarySimple

            TriggerEvent("chat:addMessage", {
                color = {0, 0, 0},
                args = {
                    cameraname,
                    colour .. " " .. modelName .. ". " .. plate .. ". Dist: " .. math.floor(distance) .. ". ^*Markers: ^r" .. PlateInfo[plate]
                }
            })

            local originPos = GetEntityCoords(originVeh)
            TriggerServerEvent("CameraTech:VehicleANPRAlert", colour, modelName, cameraname, math.floor(distance), plate, originPos.x, originPos.y, originPos.z)

            PlayANPRAlertSound(true)
            ANPRInterface.VehicleANPRHeaderString = cameraname
            ANPRInterface.VehicleANPRInfo = colour .. " " .. modelName .. ". " .. plate .. "."
            ANPRInterface.VehicleANPRMarkers = "~r~" .. PlateInfo[plate]
            ANPRInterface.FlashVehicleANPR()
        else
            PlayANPRScanSound()
        end
    end
end




function PlayANPRScanSound()
    --No code found
end

--------------ANPRInterface.cs
ANPRInterface = {
    VehicleANPRHeaderString = "",
    FixedANPRHeaderString = "",
    VehicleANPRInfo = "~g~ACTIVATED",
    FixedANPRInfo = "~g~ACTIVATED",
    VehicleANPRMarkers = "",
    FixedANPRMarkers = "",
    MasterInterfaceToggle = false,
    ANPRvehicle = nil
}

local scale = 0.300

function ToggleVehicleANPR(toggle)
    if toggle then
        Active = true
    else
        Active = false
    end
    checkedPlates = checkedPlates or {}
    for k in pairs(checkedPlates) do
        checkedPlates[k] = nil
    end
end

RegisterNetEvent("CameraTech:MasterInterfaceToggle")
AddEventHandler("CameraTech:MasterInterfaceToggle", function()
    if MasterInterfaceToggle == true then
        ANPRInterface.toggleMasterInterface(false)
        toggleFixedANPR(false)
        ToggleVehicleANPR(false)
        ShowNotification("ANPR deactivated.")
    else
        if not usingJsonFile and currentANPRModelsJsonString == nil then
            TriggerServerEvent("CameraTech:GetANPRModelsJsonString")
        else
            ANPRInterface.runAnprCommandEnable()
        end
    end
end)

function ANPRInterface.runAnprCommandEnable()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        local modelHash = GetEntityModel(veh)        
        local isVehicleANPRModel = VehicleANPRModels[modelHash]
        local isFixedANPRModel = FixedANPRModels[modelHash]

        if isVehicleANPRModel or isFixedANPRModel then
            ANPRInterface.toggleMasterInterface(true)
            ToggleVehicleANPR(isVehicleANPRModel)
            toggleFixedANPR(isFixedANPRModel)
            ShowNotification("ANPR activated.")
        else
            ShowNotification("This vehicle does not have ANPR technology.")
        end
    end
end

function ANPRInterface.toggleMasterInterface(toggle)
    MasterInterfaceToggle = toggle
    if toggle then
        MasterInterfaceToggle = true
        ANPRvehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    else
        MasterInterfaceToggle = false
        ANPRvehicle = nil
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if MasterInterfaceToggle and DoesEntityExist(ANPRvehicle) then
            local screenW, screenH = GetActiveScreenResolution()
            local midX = screenW * 0.08
            local drawY = screenH * 0.5

            -- Draw backgrounds (rectangles)
            DrawRect(0.08, 0.57, 0.16, 0.14, 0, 0, 0, 150)

            -- Vehicle ANPR Section
            drawCenterText("Vehicle ANPR - " .. ANPRInterface.VehicleANPRHeaderString, 0.501, scale, 0, 191, 255)
            local vehInfo = Active and ANPRInterface.VehicleANPRInfo or "~r~DISABLED"
            local vehMarkers = Active and ANPRInterface.VehicleANPRMarkers or ""
            drawCenterText(vehInfo, 0.519, scale, 255, 255, 255)
            drawCenterText(vehMarkers, 0.537, scale, 255, 255, 255)

            -- Fixed ANPR Section
            local focusedString = "Fixed ANPR"
            if FocusedPlate or ForceFocusedAnpr then
                focusedString = "Focused ANPR"
                if FocusedPlate then
                    focusedString = focusedString .. " (" .. FocusedPlate .. ")"
                else
                    focusedString = focusedString .. " (No Plate)"
                end
            end

            drawCenterText(focusedString, 0.555, scale, 0, 191, 255)
            drawCenterText(FixedANPRAlertsToggle and ANPRInterface.FixedANPRHeaderString or "", 0.573, scale, 0, 191, 255)
            local fixedInfo = FixedANPRAlertsToggle and ANPRInterface.FixedANPRInfo or "~r~DISABLED"
            local fixedMarkers = FixedANPRAlertsToggle and ANPRInterface.FixedANPRMarkers or ""
            drawCenterText(fixedInfo, 0.591, scale, 255, 255, 255)
            drawCenterText(fixedMarkers, 0.609, scale, 255, 255, 255)
        end
    end
end)

function drawCenterText(text, y, scale, r, g, b)
    SetTextFont(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.08, y)
end

function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, true)
end

function ANPRInterface.FlashVehicleANPR(count)
    count = count or 10
    CreateThread(function()
        for i = 1, count do
            ANPRInterface.VehicleANPRHeaderString = "~r~" .. ANPRInterface.VehicleANPRHeaderString
            Wait(200)
            ANPRInterface.VehicleANPRHeaderString = ANPRInterface.VehicleANPRHeaderString:gsub("~r~", "")
            Wait(200)
        end
    end)
end

function ANPRInterface.FlashFixedANPR(count)
    count = count or 10
    CreateThread(function()
        for i = 1, count do
            ANPRInterface.FixedANPRHeaderString = "~r~" .. ANPRInterface.FixedANPRHeaderString
            Wait(200)
            ANPRInterface.FixedANPRHeaderString = ANPRInterface.FixedANPRHeaderString:gsub("~r~", "")
            Wait(200)
        end
    end)
end




local function ShowNotification(input)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(input)
    DrawNotification(false, true)
end

Main()
