include("GameCapabilities");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_VIEW = View;
BASE_CQUI_Refresh = Refresh;
BASE_CQUI_GetUnitActionsTable = GetUnitActionsTable;
BASE_CQUI_OnInterfaceModeChanged = OnInterfaceModeChanged;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_ShowImprovementsRecommendations :boolean = false;
function CQUI_OnSettingsUpdate()
    CQUI_ShowImprovementsRecommendations = GameConfiguration.GetValue("CQUI_ShowImprovementsRecommendations") == 1
end
LuaEvents.CQUI_SettingsUpdate.Add(CQUI_OnSettingsUpdate);
LuaEvents.CQUI_SettingsInitialized.Add(CQUI_OnSettingsUpdate);

-- ===========================================================================
--  CQUI modified View functiton : check if we should show the recommanded action
-- ===========================================================================
function View(data)
    BASE_CQUI_VIEW(data);

    if ( data.Actions["BUILD"] ~= nil and #data.Actions["BUILD"] > 0 ) then
        local BUILD_PANEL_ART_PADDING_Y = 20;
        local buildStackHeight :number = Controls.BuildActionsStack:GetSizeY();

        if not CQUI_ShowImprovementsRecommendations then
            Controls.RecommendedActionButton:SetHide(true);
            Controls.BuildActionsPanel:SetSizeY( buildStackHeight + BUILD_PANEL_ART_PADDING_Y);
            Controls.BuildActionsStack:SetOffsetY(0);
        end
    end

    -- CQUI (Azurency) : instead of changing the xml, it's easier to do it in code here (bigger XP bar)
    Controls.XPArea:SetSizeY(15);
    Controls.XPBar:SetSizeY(10);
    Controls.XPLabel:SetFontSize(12);
end

-- ===========================================================================
--  CQUI modified Refresh functiton : AutoExpand
-- ===========================================================================
function Refresh(player, unitId)
    BASE_CQUI_Refresh(player, unitId);

    if (player ~= nil and player ~= -1 and unitId ~= nil and unitId ~= -1) then
        local units = Players[player]:GetUnits();
        local unit = units:FindID(unitId);
        if (unit ~= nil) then
            --CQUI auto-expando
            if (GameConfiguration.GetValue("CQUI_AutoExpandUnitActions")) then
                local isHidden:boolean = Controls.SecondaryActionsStack:IsHidden();
                if isHidden then
                    Controls.SecondaryActionsStack:SetHide(false);
                    Controls.ExpandSecondaryActionsButton:SetTextureOffsetVal(0,29);
                    OnSecondaryActionStackMouseEnter();
                    Controls.ExpandSecondaryActionStack:CalculateSize();
                    Controls.ExpandSecondaryActionStack:ReprocessAnchoring();
                end

                -- AZURENCY : fix for the size not updating correcly (fall 2017), we calculate the size manually, 4 is the StackPadding
                Controls.ExpandSecondaryActionStack:SetSizeX(Controls.ExpandSecondaryActionsButton:GetSizeX() + Controls.SecondaryActionsStack:GetSizeX() + 4);
                ResizeUnitPanelToFitActionButtons();
            end
        end
    end
end

-- ===========================================================================
--  CQUI modified Refresh functiton : GetUnitActionsTable
--  Update the Housing tool tip to show Farm Provides 1.5 Housing when Player is Maya
--  This is fixing a bug in the unmodified game, as it still shows 0.5 Housing on the tool tip
-- ===========================================================================
function GetUnitActionsTable( pUnit )
    local actionsTable = BASE_CQUI_GetUnitActionsTable(pUnit);

    -- Update the Farm Tool Tip to show 1.5 Housing if the player is Maya
    if HasTrait("TRAIT_CIVILIZATION_MAYAB", Game.GetLocalPlayer()) then
        local iconCount = #actionsTable["BUILD"];
        for i = 1, iconCount do
            if (actionsTable["BUILD"][i]["IconId"] == "ICON_IMPROVEMENT_FARM") then
                if housingStr ~= "" then
                    local housingStrBefore = Locale.Lookup("LOC_OPERATION_BUILD_IMPROVEMENT_HOUSING", 0.5);
                    -- print_debug isn't working in this file, so for now just comment out the print statements
                    -- print("housingStrBefore is (before adding escape chars): "..housingStrBefore);
                    -- Lua parses characters that are found in regex ([],+, etc) so we need to escape those in our string we're looking to replace
                    -- Using gsub("%p", "%%%1") will replace all of the punctuation characters (which includes [], +, )
                    -- See https://www.lua.org/pil/20.2.html
                    housingStrBefore = housingStrBefore:gsub("%p", "%%%1")
                    local housingStrAfter = Locale.Lookup("LOC_OPERATION_BUILD_IMPROVEMENT_HOUSING", 1.5);
                    local updatedHelpString, replacedCount = actionsTable["BUILD"][i]["helpString"]:gsub(housingStrBefore, housingStrAfter);

                    -- print("housingStrBefore is (after adding escape chars): "..housingStrBefore);
                    -- print("housingStrAfter is: "..housingStrAfter);
                    -- print("updatedHelpString is: "..updatedHelpString);
                    -- print("replacedCount is: "..tostring(replacedCount));

                    if replacedCount == 1 then
                        actionsTable["BUILD"][i]["helpString"] = updatedHelpString;
                    end
                end

                break -- Only the farm icon needs updating, break from the for loop
            end
        end
    end

    return actionsTable;
end

-- ===========================================================================
--  CQUI modified ModifierStrings on combat preview
--  If there are identical ModifierStrings except for the number value, they are combined as a single string with
--  all the numbers combined.
-- ===========================================================================
function GetCombatModifierList(combatantHash)
    local m_combatResults = GetCombatPreviewResults()
    if (m_combatResults == nil) then return; end

    local baseStrengthValue = 0;
    local combatantResults = m_combatResults[combatantHash];

    baseStrengthValue = combatantResults[CombatResultParameters.COMBAT_STRENGTH];

    local baseStrengthText = baseStrengthValue .. " " .. Locale.Lookup("LOC_COMBAT_PREVIEW_BASE_STRENGTH");
    local interceptorModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_INTERCEPTOR];
    local antiAirModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_ANTI_AIR];
    local healthModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_HEALTH];
    local terrainModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_TERRAIN];
    local opponentModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_OPPONENT];
    local modifierModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_MODIFIER];
    local flankingModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_ASSIST];
    local promotionModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_PROMOTION];
    local defenseModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_DEFENSES];
    local resourceModifierText = combatantResults[CombatResultParameters.PREVIEW_TEXT_RESOURCES];

    local modifierList:table = {};
    local modifierListSize:number = 0;
    if ( baseStrengthText ~= nil) then
        modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, baseStrengthText, "ICON_STRENGTH");
    end
    if (interceptorModifierText ~= nil) then
    for i, item in ipairs(interceptorModifierText) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_STATS_INTERCEPTOR");
        end
    end
    if (antiAirModifierText ~= nil) then
        for i, item in ipairs(antiAirModifierText) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_STATS_ANTIAIR");
        end
    end
    if (healthModifierText ~= nil) then
        for i, item in ipairs(healthModifierText) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_DAMAGE");
        end
    end
    if (terrainModifierText ~= nil) then
        for i, item in ipairs(terrainModifierText) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_STATS_TERRAIN");
        end
    end
    if (opponentModifierText ~= nil) then
        for i, item in ipairs(opponentModifierText) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_STRENGTH");
        end
    end
    if (modifierModifierText ~= nil) then             -- MODDED CHANGES BEGIN
    local REPLACE_TAG = '{{PLACEHOLDER}}'
        local tModifierUniques = {}
        local tNumStrippedUniques = {}
        local tNumStrippedUniquesAmounts = {}
        local sStrippedItem
        local sNewItem
        local iStrippedAmount
        for i, item in ipairs(modifierModifierText) do
            iStrippedAmount = item:match("%d+")
            if iStrippedAmount then
                sStrippedItem = item:gsub(iStrippedAmount, REPLACE_TAG, 1)
                if tNumStrippedUniques[sStrippedItem] then
                    tNumStrippedUniques[sStrippedItem] = tNumStrippedUniques[sStrippedItem] + iStrippedAmount
                else
                    tNumStrippedUniques[sStrippedItem] = iStrippedAmount
                end
            else
                tModifierUniques[item] = 1
            end
        end
        for item, amount in pairs(tNumStrippedUniques) do
            sNewItem = item:gsub(REPLACE_TAG, tostring(amount), 1)
            item = sNewItem
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_STRENGTH");
        end
        for item, amount in pairs(tModifierUniques) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_STRENGTH");
        end
    end                                                           -- MODDED CHANGES END
    if (flankingModifierText ~= nil) then
        for i, item in ipairs(flankingModifierText) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_POSITION");
        end
    end
    if (promotionModifierText ~= nil) then
        for i, item in ipairs(promotionModifierText) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_PROMOTION");
        end
    end
    if (defenseModifierText ~= nil) then
        for i, item in ipairs(defenseModifierText) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_DEFENSE");
        end
    end
    if (resourceModifierText ~= nil) then
        for i, item in ipairs(resourceModifierText) do
            modifierList, modifierListSize = AddModifierToList(modifierList, modifierListSize, Locale.Lookup(item), "ICON_RESOURCES");
        end
    end

    return modifierList, modifierListSize;
end

-- ===========================================================================
--  CQUI modified OnInterfaceModeChanged
--  Don't always hide the ContextPtr when leaving City/District Range Attack
-- ===========================================================================
function OnInterfaceModeChanged( eOldMode:number, eNewMode:number )
    -- Base function call
    BASE_CQUI_OnInterfaceModeChanged(eOldMode, eNewMode);

    -- The ContextPtr is always set to hide when the old mode is CITY_RANGE_ATTACK or DISTRICT_RANGE_ATTACK
    -- Unhide it if the new mode is also one of these, or if a unit was selected
    -- Fixes basegame bug with the UnitPanel being hidden when it's not supposed to be
    if ((eOldMode == InterfaceModeTypes.CITY_RANGE_ATTACK or eOldMode == InterfaceModeTypes.DISTRICT_RANGE_ATTACK)
        and ((eNewMode == InterfaceModeTypes.CITY_RANGE_ATTACK or eNewMode == InterfaceModeTypes.DISTRICT_RANGE_ATTACK)
        or (eNewMode == InterfaceModeTypes.SELECTION and UI.GetHeadSelectedUnit()))) then
            ContextPtr:SetHide(false);
    end
end

-- ===========================================================================
--  Initialize the context
-- ===========================================================================
function Initialize_UnitPanel_CQUI()
    Events.InterfaceModeChanged.Remove(BASE_CQUI_OnInterfaceModeChanged);
    Events.InterfaceModeChanged.Add(OnInterfaceModeChanged);
end
Initialize_UnitPanel_CQUI();
