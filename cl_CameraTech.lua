
FixedANPRRadius = 28.0
FixedANPRAlertsToggle = false;
BlipsCreated = false;
FocusedPlate = nil;
RouteBlip = nil;
ANPRHitChance = 95;
lastFixedPlate = nil;
usingJsonFile = true;
currentANPRModelsJsonString = nil;
ForceFocusedAnpr = false;
VehicleANPRModels = {}
FixedANPRModels = {}


--Variables
--Notes
-- Shapetest.cs was ignored

--dfhgbdfhbgdfhbgdfhgbdfhbgdfhbgdfbgdgbdgbjhafsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss



print("CameraTech by Albo1125. (recoded to lua)")
TriggerEvent('chat:addSuggestions', {
    { name = '/anpr', help = 'Toggles the ANPR interface' },
    { name = '/vehanpr', help = 'Toggles the vehicle ANPR system' },
    { name = '/fixedanpr', help = 'Toggles the fixed ANPR system' },
    { name = '/setplateinfo', help = 'Sets markers for the specified plate', params = { { name = 'param', help = 'Type the plate, followed by semicolon (;), followed by the ANPR markers (leave markers blank to remove). Ex: AB12CDE;Stolen' } }},
    { name = '/setvehinfo', help = "Sets markers for the plate of the vehicle you're currently in", params = { { name = "markers", help = "The markers for this vehicle's plate, leave blank to remove from the system. Ex: Stolen" } } } })

RegisterNetEvent("ClUpdateVehicleInfo")
AddEventHandler("ClUpdateVehicleInfo", function(plateinfo) 
    if (IsPlayerInValidVehicle) then -- Verify later
        plate = GetVehicleNumberPlateText(GetVehiclePedIsUsing(source)):gsub("%s+", "")
        TriggerServerEvent("UpdateVehicleInfo", plate, plateinfo)
        if (plateinfo ~= nil) then
            TriggerEvent("chat:addMessage", { color = {0, 0, 0}, args = {"System", "Plate: " .. plate .. ". Info: " .. plateinfo} })
        else
            TriggerEvent("chat:addMessage", { color = {0, 0, 0}, args = {"System", "Plate: " .. plate .. " No Info"} })
        end
    end
end)

RegisterNetEvent("CameraTech:ClFixedANPRAlert")
AddEventHandler("ClFixedANPRAlert", function(colour, modelName, anprname, dir, plate)
    if (IsPlayerInValidVehicle) then
        if (FocusedPlate == false and FocusedPlate == plate) then
            TriggerEvent("chat:addMessage", {color={0,0,0}, args={"Fixed ANPR", colour + " " + modelName + ". " + plate + ". " + anprname + " (" + dir + "). ^*Markers: ^r" + PlateInfo[plate]}})
            PlayANPRAlertSound(false)
            if (BlipsCreated) then
                fixedanpr = 1 --todo find anpr camera logic
                if (fixedanpr and fixedanpr.blip.exists()) then
                    fixedanpr.blip.ShowRoute = true
                    RouteBlip = fixedanpr.blip
                end
            end
            ANPRInterface.FixedANPRHeaderString = anprname + " (" + dir + ")"
            ANPRInterface.FixedANPRInfo = colour + " " + modelName + ". " + plate + "."
            ANPRInterface.FixedANPRMarkers = "~r~" + PlateInfo[plate]
            lastFixedPlate = plate
            ANPRInterface.FlashFixedANPR()
        else if (FocusedPlate == null and not ForceFocusedAnpr) then
            TriggerEvent("chat:addMessage", {color={0,0,0}, args={"Fixed ANPR", colour + " " + modelName + ". " + plate + ". " + anprname + " (" + dir + "). ^*Markers: ^r" + PlateInfo[plate]}})
            PlayANPRAlertSound(false)
            ANPRInterface.FixedANPRHeaderString = anprname + " (" + dir + ")"
            ANPRInterface.FixedANPRInfo = colour + " " + modelName + ". " + plate + "."
            ANPRInterface.FixedANPRMarkers = "~r~" + PlateInfo[plate]
            lastFixedPlate = plate
            ANPRInterface.FlashFixedANPR()
        end
    end
end
end)

RegisterNetEvent("CameraTech:FixedANPRToggle")
AddEventHandler("CameraTech:FixedANPRToggle", function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if FixedANPRAlertsToggle then
        toggleFixedANPR(false)
        ShowNotification("Fixed ANPR alerts deactivated.")
    elseif vehicle and DoesEntityExist(vehicle) then
        local model = GetEntityModel(vehicle)

        if FixedANPRModels[model] then
            toggleFixedANPR(true)
            ShowNotification("Fixed ANPR alerts activated.")
            if not ANPRInterface.MasterInterfaceToggle then
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

RegisterNetEvent("CameraTech:SetPlateInfo")
AddEventHandler("SyncPlateInfo", function(plateinfo)
    PlateInfo = {}

    if plateinfo ~= nil then
        for key, value in pairs(plateinfo) do
            PlateInfo[key] = tostring(value)
        end
    end
end)

AddEventHandler("FocusANPR", function(plate)
    if (IsPlayerInValidVehicle) then
        if plate == nil then
            if (FocusedPlate == bil) then
                FocusedPlate = lastFixedPlate
            else
                FocusedPlate = nil
            end
        else
            FocusedPlate = plate
        end

        if (FocusedPlate == nil) then
            TriggerEvent("chat:addMessage", {color={0,0,0}, args={"Fixed ANPR", "Removed fixed ANPR plate focus."}})
            if (RouteBlip ~= nil and RouteBlip.Exists()) then
                RouteBlip.ShowRoute = false
                RouteBlip = nil
            end
        else
            TriggerEvent("chat:addMessage", {color={0,0,0}, args={"Fixed ANPR", "Fixed ANPR plate focus: " + FocusedPlate}})
        end
    end
end)
function populateANPRModels(jsonString)
    local allModels = json.decode(jsonString)

    for _, m in ipairs(allModels) do
        local modelName = m.ModelName or ""
        local accessType = string.lower(m.ANPRAccessType or "")
        local modelHash = GetHashKey(modelName)

        if accessType == "fixed only" or accessType == "full" then
            print("Adding to FixedANPRModels: " .. modelName)
            FixedANPRModels[modelHash] = true
        end

        if accessType == "vehicle only" or accessType == "full" then
            print("Adding to VehicleANPRModels: " .. modelName)
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
AddEventHandler("ANPRModelsJsonString", function(Jsonstring, runAnprCommandEnable)
    if (not usingJsonFile) then
        if (currentANPRModelsJsonString ~= Jsonstring) then
            populateANPRModels(Jsonstring)
            currentANPRModelsJsonString = Jsonstring
        end
        if Active and ANPRInterface.ANPRvehicle ~= nil and not VehicleANPRModels[ANPRInterface.ANPRvehicle.Model] then
            ToggleVehicleANPR(false)
        end
        if FixedANPRAlertsToggle and ANPRInterface.ANPRvehicle ~= nil and not FixedANPRModels[ANPRInterface.ANPRvehicle.Model] then
            toggleFixedANPR(false)
        end
    end
end)

if (runAnprCommandEnable) then
    ANPRInterface.runAnprCommandEnable()
end

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

function Main()
    local lastTriggeredANPRCamera = nil
    local timeLastTriggeredANPRCamera = os.time()
    local lastTriggeredDir = ""

    local lastBlockedFixedANPR = nil
    local timeLastBlockedANPR = os.time()

    while true do
        Citizen.Wait(5)

        local playerPed = PlayerPedId()
        if playerPed and IsPedInAnyVehicle(playerPed, false) then
            local veh = GetVehiclePedIsIn(playerPed, false)

            -- Handle ANPR Interface state
            if not ANPRInterface.MasterInterfaceToggle and ANPRInterface.ANPRvehicle and veh == ANPRInterface.ANPRvehicle then
                ANPRInterface.toggleMasterInterface(true)
                ShowNotification("ANPR Activated")
            elseif ANPRInterface.MasterInterfaceToggle and veh ~= ANPRInterface.ANPRvehicle then
                ANPRInterface.MasterInterfaceToggle = false
            end

            -- Handle ANPR Blips
            if BlipsCreated and (not FixedANPRAlertsToggle or not ANPRInterface.MasterInterfaceToggle) then
                RemoveANPRBlips()
            elseif FixedANPRAlertsToggle and ANPRInterface.MasterInterfaceToggle and not BlipsCreated then
                CreateFixedANPRBlips()
            end

            -- Clear route if close
            if RouteBlip and DoesBlipExist(RouteBlip) and #(GetEntityCoords(veh) - GetBlipCoords(RouteBlip)) < 140.0 then
                SetBlipRoute(RouteBlip, false)
                RemoveBlip(RouteBlip)
                RouteBlip = nil
            end

            -- Fixed ANPR Detection
            if GetPedInVehicleSeat(veh, -1) == playerPed and GetEntitySpeed(veh) > 0.2 then
                local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
                
                if PlateInfo[plate] then
                    local vehPos = GetEntityCoords(veh)
                    local closest = nil
                    local minDist = math.huge

                    for _, anpr in ipairs(FixedANPRCameras) do
                        local dist = #(anpr.Location - vehPos)
                        if dist < minDist then
                            closest = anpr
                            minDist = dist
                        end
                    end

                    if closest then
                        local zDiff = math.abs(closest.Z - vehPos.z)
                        local dir = getCardinalDirection(GetEntityHeading(veh))

                        if minDist <= FixedANPRRadius and zDiff < 3.5 and 
                           (lastTriggeredANPRCamera ~= closest or os.difftime(os.time(), timeLastTriggeredANPRCamera) > 20 or lastTriggeredDir ~= dir) then

                            if (lastBlockedFixedANPR ~= closest or os.difftime(os.time(), timeLastTriggeredANPRCamera) > 120)
                                and math.random(0, 100) < ANPRHitChance then

                                Citizen.Wait(1300)
                                dir = getCardinalDirection(GetEntityHeading(veh))

                                local model = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                                local colour = GetVehicleColour(veh)

                                TriggerServerEvent("FixedANPRAlert", colour, model, closest.Name, dir, plate, closest.X, closest.Y, closest.Z)
                                lastTriggeredANPRCamera = closest
                                timeLastTriggeredANPRCamera = os.time()
                                lastTriggeredDir = dir
                                lastBlockedFixedANPR = nil
                            else
                                if lastBlockedFixedANPR ~= closest then
                                    timeLastBlockedANPR = os.time()
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

            if ANPRInterface.MasterInterfaceToggle then
                ANPRInterface.MasterInterfaceToggle = false
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
        SetBlipSprite(blip, 43)            -- 43 is Camera
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

SimpleColours = { "Black", "Graphite", "Steel", "Silver", "Red", "Pink", "Orange", "Yellow", "Green", "Blue", "Brown", "Purple", "White", "Gray", "Gold", "Steel", "Aluminium", "Beige" }

function GetVehicleColour(handle) -- presumed broken
    local primary, secondary = GetVehicleColours(veh)
    PrimaryColour = EPaint[tostring(primary)]
    SecondaryColour = EPaint[tostring(secondary)]
    print (PrimaryColour .. " " .. SecondaryColour)

    return {
        PrimaryColour = PrimaryColour,
        SecondaryColour = SecondaryColour,
        PrimarySimpleColourName = GetSimpleColourName(PrimaryColour),
        SecondarySimpleColourName = GetSimpleColourName(SecondaryColour)
    }

end

function GetSimpleColourName(paint)
    print("Paint value is: ", paint, "Type: ", type(paint))
    for _, simpleColour in ipairs(SimpleColours) do
        if paint:lower():find(simpleColour:lower(), 1, true) then
            return simpleColour
        end
    end
    return paint
end
EPaint = {
    Unknown = -1,
    Black = 0,
    Carbon_Black = 147,
    Graphite = 1,
    Anhracite_Black = 11,
    Black_Steel = 2,
    Dark_Steel = 3,
    Silver = 4,
    Bluish_Silver = 5,
    Rolled_Steel = 6,
    Shadow_Silver = 7,
    Stone_Silver = 8,
    Midnight_Silver = 9,
    Cast_Iron_Silver = 10,
    Red = 27,
    Torino_Red = 28,
    Formula_Red = 29,
    Lava_Red = 150,
    Blaze_Red = 30,
    Grace_Red = 31,
    Garnet_Red = 32,
    Sunset_Red = 33,
    Cabernet_Red = 34,
    Wine_Red = 143,
    Candy_Red = 35,
    Hot_Pink = 135,
    Pfister_Pink = 137,
    Salmon_Pink = 136,
    Sunrise_Orange = 36,
    Orange = 38,
    Bright_Orange = 138,
    Gold = 37,
    Bronze = 90,
    Yellow = 88,
    Race_Yellow = 89,
    Dew_Yellow = 91,
    Green = 139,
    Dark_Green = 49,
    Racing_Green = 50,
    Sea_Green = 51,
    Olive_Green = 52,
    Bright_Green = 53,
    Gasoline_Green = 54,
    Lime_Green = 92,
    Hunter_Green = 144,
    Securiror_Green = 125,
    Midnight_Blue = 141,
    Galaxy_Blue = 61,
    Dark_Blue = 62,
    Saxon_Blue = 63,
    Blue = 64,
    Bright_Blue = 140,
    Mariner_Blue = 65,
    Harbor_Blue = 66,
    Diamond_Blue = 67,
    Surf_Blue = 68,
    Nautical_Blue = 69,
    Racing_Blue = 73,
    Ultra_Blue = 70,
    Light_Blue = 74,
    Police_Car_Blue = 127,
    Epsilon_Blue = 157,
    Chocolate_Brown = 96,
    Bison_Brown = 101,
    Creek_Brown = 95,
    Feltzer_Brown = 94,
    Maple_Brown = 97,
    Beechwood_Brown = 103,
    Sienna_Brown = 104,
    Saddle_Brown = 98,
    Moss_Brown = 100,
    Woodbeech_Brown = 102,
    Straw_Brown = 99,
    Sandy_Brown = 105,
    Bleached_Brown = 106,
    Schafter_Purple = 71,
    Spinnaker_Purple = 72,
    Midnight_Purple = 142,
    Metallic_Midnight_Purple = 146,
    Bright_Purple = 145,
    Cream = 107,
    Ice_White = 111,
    Frost_White = 112,
    Pure_White = 134,
    Default_Alloy = 156,
    Champagne = 93,
    Matte_Black = 12,
    Matte_Gray = 13,
    Matte_Light_Gray = 14,
    Matte_Ice_White = 131,
    Matte_Blue = 83,
    Matte_Dark_Blue = 82,
    Matte_Midnight_Blue = 84,
    Matte_Midnight_Purple = 149,
    Matte_Schafter_Purple = 148,
    Matte_Red = 39,
    Matte_Dark_Red = 40,
    Matte_Orange = 41,
    Matte_Yellow = 42,
    Matte_Lime_Green = 55,
    Matte_Green = 128,
    Matte_Forest_Green = 151,
    Matte_Foliage_Green = 155,
    Matte_Brown = 129,
    Matte_Olive_Darb = 152,
    Matte_Dark_Earth = 153,
    Matte_Desert_Tan = 154,
    Util_Black = 15,
    Util_Black_Poly = 16,
    Util_Dark_Silver = 17,
    Util_Silver = 18,
    Util_Gun_Metal = 19,
    Util_Shadow_Silver = 20,
    Util_Red = 43,
    Util_Bright_Red = 44,
    Util_Garnet_Red = 45,
    Util_Dark_Green = 56,
    Util_Green = 57,
    Util_Dark_Blue = 75,
    Util_Midnight_Blue = 76,
    Util_Blue = 77,
    Util_Sea_Foam_Blue = 78,
    Util_Lightning_Blue = 79,
    Util_Maui_Blue_Poly = 80,
    Util_Bright_Blue = 81,
    Util_Brown = 108,
    Util_Medium_Brown = 109,
    Util_Light_Brown = 110,
    Util_Off_White = 122,
    Worn_Black = 21,
    Worn_Graphite = 22,
    Worn_Silver_Gray = 23,
    Worn_Silver = 24,
    Worn_Blue_Silver = 25,
    Worn_Shadow_Silver = 26,
    Worn_Red = 46,
    Worn_Golden_Red = 47,
    Worn_Dark_Red = 48,
    Worn_Dark_Green = 58,
    Worn_Green = 59,
    Worn_Sea_Wash = 60,
    Worn_Dark_Blue = 85,
    Worn_Blue = 86,
    Worn_Light_Blue = 87,
    Worn_Honey_Beige = 113,
    Worn_Brown = 114,
    Worn_Dark_Brown = 115,
    Worn_Straw_Beige = 116,
    Worn_Off_White = 121,
    Worn_Yellow = 123,
    Worn_Light_Orange = 124,
    Worn_Taxi_Yellow = 126,
    Worn_Orange = 130,
    Worn_White = 132,
    Worn_Olive_Army_Green = 133,

    Brushed_Steel = 117,
    Brushed_Black_Steel = 118,
    Brushed_Aluminum = 119,
    Pure_Gold = 158,
    Brushed_Gold = 159,
    Secret_Gold = 160,

    Chrome = 120,
    }
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
    else
        model = GetEntityModel(vehicle)
        if VehicleANPRModels[model] then
            print ("Vehicle ANPR activated for model: " .. model)
            ToggleVehicleANPR(true)
            ShowNotification("Vehicle ANPR activated.")
            if (not ANPRInterface.MasterInterfaceToggle) then 
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

function RunChecks()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5)

            local playerPed = PlayerPedId()
            if (IsPlayerInValidVehicle) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)

                if ANPRInterface.MasterInterfaceToggle and Active and vehicle == ANPRInterface.ANPRvehicle then
                    -- FRONT
                    local frontCoord = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, raycastRadius - 0.5, 0.0)

                    local frontCoordC = GetOffsetFromEntityInWorldCoords(vehicle, -raycastRadius + 0.1, frontRange, 0.0)
                    CheckANPRShapeTest("Front ANPR (L)", StartShapeTest(frontCoord, frontCoordC, raycastRadius, vehicle), vehicle, true)

                    local frontCoordD = GetOffsetFromEntityInWorldCoords(vehicle, raycastRadius - 0.1, frontRange, 0.0)
                    CheckANPRShapeTest("Front ANPR (R)", StartShapeTest(frontCoord, frontCoordD, raycastRadius, vehicle), vehicle, false)

                    -- REAR
                    local backCoord = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -raycastRadius + 0.5, 0.0)

                    local backCoordA = GetOffsetFromEntityInWorldCoords(vehicle, -raycastRadius + 0.1, backRange, 0.0)
                    CheckANPRShapeTest("Rear ANPR (L)", StartShapeTest(backCoord, backCoordA, raycastRadius, vehicle), vehicle, true)

                    local backCoordB = GetOffsetFromEntityInWorldCoords(vehicle, raycastRadius - 0.1, backRange, 0.0)
                    CheckANPRShapeTest("Rear ANPR (R)", StartShapeTest(backCoord, backCoordB, raycastRadius, vehicle), vehicle, false)
                end
            end
        end
    end)
end


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

        if (left and positionedRight) or (positionedRight and not positionedRight) then
            return
        end

        local modelHash = GetEntityModel(hitVeh)
        local modelName = GetDisplayNameFromVehicleModel(modelHash)
        local plate = GetVehicleNumberPlateText(hitVeh):gsub(" ", "")

        if not checkedPlates[plate] then
            checkedPlates[plate] = true

            if PlateInfo and PlateInfo[plate] then
                local from = stest.from or GetEntityCoords(originVeh) -- fallback if 'from' isn't provided
                local distance = #(from - hitVehPos)
                local colour = VehicleColour.GetVehicleColour(hitVeh).PrimarySimpleColourName
                TriggerEvent("chat:addMessage", { color={0,0,0}, args={cameraname, colour + " " + modelName + ". " + plate + ". Dist: " + Math.Round(distance) + ". ^*Markers: ^r" + PlateInfo[plate]} })

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

local scale = 0.345

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

    local function IsPlayerInValidVehicle()
    local ped = PlayerPedId()
    if DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        return DoesEntityExist(vehicle)
    end
    return false
    end
end