ObjectiveTracker = LibStub("AceAddon-3.0"):NewAddon("ObjectiveTracker", "AceConsole-3.0", "AceEvent-3.0")
DUNGEON_DIFFICULTY3 = "Challenge Mode"
UnitPopupButtons["DUNGEON_DIFFICULTY3"] = { text=DUNGEON_DIFFICULTY3, dist=0}
UnitPopupMenus["DUNGEON_DIFFICULTY"][3] = "DUNGEON_DIFFICULTY3"
--===========================
--        VARIABLES
--===========================
local timeLeft = 0;
local timeTotal = 0;
local enemiesLeft = 0;
local enemiesTotal = 0;
local OT = {};
local InstanceData = {};
Objectives = {}
TimerFrame = {}
ObjectiveTracker_HeaderText = {}
ObjectivePointer = {}
ObjectivePointerSheen = {}
ObjectiveLineGlow = {}
ToastFlash = {}
ObjectiveLineSheen = {}
ObjectiveTracker_Minimize_button = {}
local ChallengeCompleteFrame
local InstanceID;
local debuff = 81502;
local CMTimerRunning = false;
local AddonEnabled = false;
local Frame_Collapsed = false;
local instanceStatus = 0;
local prevIns;
local currIns;



local Addon = select(2, ...)
local setmetatable = setmetatable
local type = type
local tinsert = table.insert
local tremove = table.remove

C_Timer = C_Timer or {}
C_Timer._version = 2

local TickerPrototype = {}
local TickerMetatable = {__index = TickerPrototype, __metatable = true}

local waitTable = {}
local waitFrame = TimerFramex or CreateFrame("Frame", "TimerFramex", UIParent)

local timer = nil

local SoundThreshold = 5

local lastEvents = {
    [0] = {}, -- Timer Data
    [1] = {}, -- Objective Data
    [2] = {}  -- Enemy Data
}

ObjectiveTracker_Save = ObjectiveTracker_Save or lastEvents

db = {
    char = {
        timerData = {}
    }
};


--===========================
--        ARTWORK
--===========================
local CMHUD_BLP = "Interface\\OBJECTIVEFRAME\\ChallengeModeHud.BLP"
local CMHUD_GM_BLP = "Interface\\OBJECTIVEFRAME\\challenges-gold.BLP"
local CHMUD_PM_BLP = "Interface\\OBJECTIVEFRAME\\challenges-plat.BLP"
local CMHUD_MEDAL_GLOW = "Interface\\OBJECTIVEFRAME\\challenges-metalglow.BLP"
local CMHUD_MINIMAP_BLP = "Interface\\OBJECTIVEFRAME\\challenges-minimap-banner.BLP"
local OBJTR_BLP = "Interface\\OBJECTIVEFRAME\\ObjectiveTracker.BLP"

local ScenariosFailIcon = "Interface\\OBJECTIVEFRAME\\Fail.BLP"
local ScenariosCombatIcon = "Interface\\OBJECTIVEFRAME\\Combat.BLP"
local ScenariosCheckIcon = "Interface\\OBJECTIVEFRAME\\Check.BLP"
local ScenariosLineGlow = "Interface\\OBJECTIVEFRAME\\LineGlow.BLP"
local ScenariosIconSheen = "Interface\\OBJECTIVEFRAME\\Sheen.BLP"

--===========================
--     ARTWORK MATRIX
--===========================
local CMHUD = {
    [0] = { 0.000976562, 0.180664, 0.802734, 0.847656 },   -- challenges-timerborder
    [1] = { 0.714844, 0.952148, 0.431641, 0.546875 },      -- challenges-timerbg
    [2] = { 0.387695, 0.712891, 0.431641, 0.550781 },      -- challenges-blackfade
    [3] = { 0.387695, 0.604492, 0.220703, 0.427734 },      -- challenges-bannershine
    [4] = { 0.633789, 0.9375, 0.00195312, 0.154297 },      -- challenges-toast

}

local CMHUD_SZ = {
    [0] = { 184, 23 },
    [1] = { 243, 59 },
    [2] = { 0,0 },
    [3] = { 222, 106 },
    [4] = { 311, 78 }
}

local OBTracker = {
    [0] = { 0.455078, 0.904297, 0.476562, 0.519531 },     -- OBJFX_LineGlow
    [1] = { 0.00195312, 0.451172, 0.476562, 0.521484 },   -- OBJBonusBar-Top
    [2] = { 0.00195312, 0.582031, 0.00195312, 0.169922 }, -- Objective-Header
    [3] = { 0.949219, 0.980469, 0.00195312, 0.0332031 },  -- Objective-Fail
    [4] = { 0.878906, 0.910156, 0.00195312, 0.0332031 },     -- Tracker-Check
    [5] = { 0.655, 0.677, 0.26, 0.3 } -- Point


}

local OTPos = {
    [0] = { 0.00195312, 0.582031, 0.00195312, 0.169922 } -- Header
}

local DigitCoord = {
    [0] = { 0, 0.25, 0, 0.33203125 },
    [1] = { 0.25, 0.5, 0, 0.33203125 },
    [2] = { 0.5, 0.75, 0, 0.33203125 },
    [3] = { 0.75, 1, 0, 0.33203125 },
    [4] = { 0, 0.25, 0.33203125, 0.6640625 },
    [5] = { 0.25, 0.5, 0.33203125, 0.6640625 },
    [6] = { 0.5, 0.75, 0.33203125, 0.6640625 },
    [7] = { 0.75, 1, 0.33203125, 0.6640625 },
    [8] = { 0, 0.25, 0.6640625, 1 },
    [9] = { 0.25, 0.5, 0.6640625, 1 }
 }

 local DigitHalfWidth = {
    [0] = 35,
    [1] = 14,
    [2] = 33,
    [3] = 32,
    [4] = 36,
    [5] = 32,
    [6] = 33,
    [7] = 29,
    [8] = 31,
    [9] = 31
}

--===========================
--   INSTANCE DEFINITIONS
--===========================

Instances = {
        [521] = { "The Nexus", {
            [1] = {"Commander"},
            [2] = {"Grand Magus Telestra"},
            [3] = {"Anomalus"},
            [4] = {"Ormorok the Tree-Shaper"},
            [5] = {"Keristrasza"}
        }
    },
        [529] = { "The Oculus", {
            [1] = {"Drakos the Interrogator"},
            [2] = {"Varos Cloudstrider"},
            [3] = {"Mage-Lord Urom"},
            [4] = {"Ley-Guardian Eregos"},
        }
    },
        [523] = { "Ahn'kahet: The Old Kingdom", {
            [1] = {"Elder Nadox"},
            [2] = {"Prince Taldaram"},
            [3] = {"Amanitar"},
            [4] = {"Jedoga Shadowseeker"},
            [5] = {"Herald Volazj"}
        }
    },
        [534] = { "Azjol-Nerub", {
            [1] = {"Krik'thir the Gatekeeper"},
            [2] = {"Hadronox"},
            [3] = {"Anub'arak"},
            [4] = {"Anub'ar Primer Guards"}
        }
    },
        [535] = { "Drak'Tharon Keep", {
            [1] = {"Trollgore"},
            [2] = {"Novos the Summoner"},
            [3] = {"King Dred"},
            [4] = {"The Prophet Tharon'ja"}
        }
    },
        [531] = { "Gundrak", {
            [1] = {"Slad'ran"},
            [2] = {"Drakkari Colossus"},
            [3] = {"Moorabi"},
            [4] = {"Eck the Ferocious"},
            [5] = {"Gal'darah"}
        }
    },
        [526] = { "Halls of Lightning", {
            [1] = {"General Bjarngrim"},
            [2] = {"Volkhan"},
            [3] = {"Ionar"},
            [4] = {"Loken"}
        }
    },
        [527] = { "Halls of Stone", {
            [1] = {"Maiden of Grief"},
            [2] = {"Krystallus"},
            [3] = {"The Tribunal of Ages"},
            [4] = {"Sjonnir the Ironshaper"}
        }
    },
        [604] = { "Halls of Reflection", {
            [1] = {""}
        }
    },
        [603] = { "Pit of Saron", {
            [1] = {"Forgemaster Garfrost"},
            [2] = {"Krick and Ick"},
            [3] = {"Scourgelord Tyrannus"}
        }
    },
        [602] = { "The Forge of Souls", {
            [1] = {"Bronjahm"},
            [2] = {"Devourer of Souls"}
        }
    },
        [524] = { "Utgarde Keep", {
            [1] = {"Prince Keleseth"},
            [2] = {"Skarvald the Constructor"},
            [3] = {"Dalronn the Controller"},
            [4] = {"Ingvar the Plunderer"}
        }
    },
        [525] = { "Utgarde Pinnacle", {
            [1] = {"Svala Sorrowgrave"},
            [2] = {"Gortok Palehoof"},
            [3] = {"Skadi the Ruthless"},
            [4] = {"King Ymiron"}
        }
    },
}

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(frame, event, arg1, arg2, ...)
    if (arg2 == "Wrathrelay") then
        pflag = "|TInterface\\ICONS\\UI-ChatIcon-Discord.blp:20:25:-2:-3|t";
        arg2 = "";
        arg1 = format("%s\32"..arg1, pflag, arg2);


        return false, arg1, arg2, ...
    else
        return false
    end
end)



function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function ObjectiveTracker:Collapse()
	Frame_Collapsed = true;
	--ObjectiveTrackerFrame.BlocksFrame:Hide();

	ObjectiveTracker_Minimize_button:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5);
	ObjectiveTracker_Minimize_button:GetPushedTexture():SetTexCoord(0.5, 1, 0, 0.5);
    if (ObjectivesFrame) then
        ObjectivesFrame:Hide()
    end
    if (TimerFrame) then
        TimerFrame:Hide()
    end
    for i=0, 10 do
        if Objectives[i] then
            Objectives[i]:Hide()
        end
    end
	--ObjectiveTrackerFrame.HeaderMenu.Title:Show();
end

function ObjectiveTracker:Expand()
	Frame_Collapsed = false;
    SendAddonMessage("WCPM-ObtainObjectiveData", "", "WHISPER", UnitName("player"))
	--ObjectiveTrackerFrame.BlocksFrame:Show();
	ObjectiveTracker_Minimize_button:GetNormalTexture():SetTexCoord(0, 0.5, 0.5, 1);
	ObjectiveTracker_Minimize_button:GetPushedTexture():SetTexCoord(0.5, 1, 0.5, 1);
    if (ObjectivesFrame) then
        ObjectivesFrame:Show()
    end
    if (TimerFrame) then
        if (CMTimerRunning) then
        -- TODO : Minimize Mini Timer
            TimerFrame:Show()
        end
    end
    if not (tonumber(instanceStatus) > 1) then
        for i=0, 10 do
            if Objectives[i] then
                Objectives[i]:Show()
            end
        end
    end

	--ObjectiveTrackerFrame.HeaderMenu.Title:Hide();
end



function ObjectiveTracker:OnInitialize()

    MinimapBannerFrame = CreateFrame("Frame", "MiniMapInstanceDifficulty", UIParent)
    MinimapBannerFrame:RegisterEvent("PLAY")

    MinimapBannerFrame:SetPoint("BOTTOM", "MiniMapInstanceDifficulty", 0, -11)
    MinimapBannerFrame:SetSize(243, 59)

    MinimapBanner = MinimapBannerFrame:CreateTexture(nil, "BACKGROUND")
    MinimapBanner:SetTexture(CMHUD_MINIMAP_BLP)
    MinimapBanner:SetSize(64,74)
    MinimapBanner:SetPoint("CENTER")

    MinimapBannerFrame:Hide()
    ObjectiveTracker:ConstructObjectiveFrame()
    ObjectiveTracker:ConstructClockTemplate()
    ObjectiveTracker:DisableAddon()
end


function ObjectiveTracker:EnableAddon()
    AddonEnabled = true;
    CMTimerRunning = false;
    timeLeft = 0;
    timeTotal = 0;
    if (ObjectiveFrame) then
        ObjectiveTracker_HeaderText:SetText(select(1, GetInstanceInfo()))
        ObjectiveFrame:Show()

    end
    if (ObjectivesFrame) then
        if instanceStatus == 0 then
            ObjectivesFrame:SetPoint("BOTTOM", "ChallengeModeTimer", 50, 35)
        end
    end
    if instanceStatus ==(0 or 1) then
        if (ObjectiveFrames) then
            ObjectivesFrame:Show()
        end
    end
    if (TimerFrame) then
        if (timeLeft > 0) then
            TimerFrame:Show()
        end
    end
    if (ObjectiveFrame_HeaderFrame) then
        ObjectiveFrame_HeaderFrame:Show()
    end

    if not prevIns == currIns then
        ObjectiveTracker:ResetAddon()
        timeLeft = 0;
        timeTotal = 0;
    end
  
    prevIns = GetCurrentMapAreaID()
    if instanceStatus == (0 or 1) then
        for i=0, 10 do
            if Objectives[i] then
                Objectives[i]:Show()
            end
        end
    end

    ObjectiveTracker_Minimize_button:SetAlpha(1)

    if (MinimapBannerFrame) then
        MinimapBannerFrame:Show()
    end
    

end

function ObjectiveTracker:DisableAddon()
    AddonEnabled = false;
    if (TimerFrame) then
        TimerFrame:Hide()
        CMTimerRunning = false;
    end
    if (ObjectiveFrame) then
        ObjectiveTracker_HeaderText:SetText("Objectives")
        ObjectiveFrame:Hide()
    end
    if (ObjectiveFrames) then
        ObjectivesFrame:Hide()
    end

    if (ObjectiveFrame_HeaderFrame) then
        ObjectiveFrame_HeaderFrame:Hide()
    end

    ObjectiveTracker_Minimize_button:SetAlpha(-1)

    if (MinimapBannerFrame) then
        MinimapBannerFrame:Hide()
    end
    
    for i=0, 10 do
        if Objectives[i] then
            Objectives[i]:Hide()
        end
    end

    ObjectiveTracker:HideCompleteBanner()
end




function ObjectiveTracker:ConstructClockTemplate()
    TimerFrame = CreateFrame("Frame", "ChallengeModeTimer", UIParent)
    TimerFrame:RegisterEvent("PLAY")

    TimerFrame:SetPoint("BOTTOM", "ObjectiveFrame_HeaderFrame", 0, -56)
    TimerFrame:SetSize(243, 59)

    CM_Timer_Background = TimerFrame:CreateTexture(nil, "BACKGROUND")
    CM_Timer_Background:SetTexture(CMHUD_BLP)
    CM_Timer_Background:SetTexCoord(unpack(CMHUD[1]))
    CM_Timer_Background:SetSize(unpack(CMHUD_SZ[1]))
    CM_Timer_Background:SetPoint("CENTER")

    CM_Timer_Medal = TimerFrame:CreateTexture(nil, "ARTWORK")
    CM_Timer_Medal:SetTexture(CHMUD_PM_BLP)
    CM_Timer_Medal:SetBlendMode("BLEND")
    CM_Timer_Medal:SetVertexColor(1,1,1, 0.8)
    CM_Timer_Medal:SetSize(48,48)
    CM_Timer_Medal:SetPoint("LEFT",5 , 0)

    CM_Timer_Medal_Glow = TimerFrame:CreateTexture(nil, "OVERLAY")
    CM_Timer_Medal_Glow:SetTexture(CMHUD_MEDAL_GLOW)
    CM_Timer_Medal_Glow:SetBlendMode("BLEND")
    CM_Timer_Medal_Glow:SetVertexColor(1,1,1,1)
    CM_Timer_Medal_Glow:SetSize(150,150)
    CM_Timer_Medal_Glow:SetAlpha(0)
    CM_Timer_Medal_Glow:SetPoint("LEFT", -45, 0)

    CM_Timer_BarBorder = TimerFrame:CreateTexture(nil, "OVERLAY")
    CM_Timer_BarBorder:SetTexture(CMHUD_BLP)
    CM_Timer_BarBorder:SetTexCoord(unpack(CMHUD[0]))
    CM_Timer_BarBorder:SetSize(unpack(CMHUD_SZ[0]))
    CM_Timer_BarBorder:SetPoint("CENTER", 20, 0)

    CM_Timer_BarFill = TimerFrame:CreateTexture(nil, "ARTWORK")
    CM_Timer_BarFill:SetTexture(CMHUD_BLP)
    CM_Timer_BarFill:SetTexCoord(0.6045,0.835,0.391,0.425)
    CM_Timer_BarFill:SetBlendMode("BLEND")
    CM_Timer_BarFill:SetVertexColor(0.3, 0.4,  0.5)
    CM_Timer_BarFill:SetSize(184,20)
    CM_Timer_BarFill:SetPoint("LEFT", 53,0)

    CM_Timer_BarText = TimerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    CM_Timer_BarText:SetText("00:00:00")
    CM_Timer_BarText:SetSize(180,15)
    CM_Timer_BarText:SetPoint("CENTER", 20, 0)

    TimerFrame:Hide()

end

function ObjectiveTracker:ConstructObjectiveFrame()
    ObjectiveFrame = CreateFrame("Frame", "ObjectiveFrame", UIParent)
    ObjectiveFrame:RegisterEvent("PLAY")

    ObjectiveFrame:SetPoint("RIGHT",0,0)
    ObjectiveFrame:SetSize(297, 50)
    
    ObjectiveFrame_HeaderFrame = CreateFrame("Frame", "ObjectiveHeaderFrame", UIParent)
    ObjectiveFrame_HeaderFrame:SetPoint("TOP", "ObjectiveFrame", 0, 0)
    ObjectiveFrame_HeaderFrame:SetSize(297, 46)


    ObjectiveFrame_HeaderTexture = ObjectiveFrame_HeaderFrame:CreateTexture(nil, "BACKGROUND")
    ObjectiveFrame_HeaderTexture:SetTexture(OBJTR_BLP)
    ObjectiveFrame_HeaderTexture:SetTexCoord(unpack(OTPos[0]))
    ObjectiveFrame_HeaderTexture:SetSize(297, 46)
    ObjectiveFrame_HeaderTexture:SetPoint("TOP")

    ObjectiveFrame_HeaderFrame:SetMovable(true)
    ObjectiveFrame_HeaderFrame:EnableMouse(true)
    ObjectiveFrame_HeaderFrame:SetScript("OnMouseDown", function(self, button)
      if button == "LeftButton" and not self.isMoving then
        self:StartMoving();
        self.isMoving = true;
      end
    end)
    ObjectiveFrame_HeaderFrame:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing();
        self.isMoving = false;
      end
    end)
    ObjectiveFrame_HeaderFrame:SetScript("OnHide", function(self)
      if ( self.isMoving ) then
        self:StopMovingOrSizing();
        self.isMoving = false;
      end
    end)    

    ObjectiveTracker_HeaderText = ObjectiveFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeLeft")
    ObjectiveTracker_HeaderText:SetText(select(1, GetInstanceInfo()))
    ObjectiveTracker_HeaderText:SetSize(180,15)
    ObjectiveTracker_HeaderText:SetVertexColor(0.75,0.61,0)
    ObjectiveTracker_HeaderText:SetPoint("LEFT", "ObjectiveFrame_HeaderFrame", 30, -5)

    ObjectiveTracker_HeaderButton = CreateFrame("Button", "ObjectiveHeaderFrame", UIParent)

	ObjectiveTracker_Minimize_button = CreateFrame("Button", nil, UIParent)
    ObjectiveTracker_Minimize_button:SetScript("OnClick", function(self, arg1)

        if ( Frame_Collapsed ) then
            ObjectiveTracker:Expand();
        else
            ObjectiveTracker:Collapse();
        end
    end)

	ObjectiveTracker_Minimize_button:SetPoint("RIGHT", "ObjectiveHeaderFrame", "RIGHT", -35, -5)
	ObjectiveTracker_Minimize_button:SetWidth(16)
	ObjectiveTracker_Minimize_button:SetHeight(16)

	
	local ntex = ObjectiveTracker_Minimize_button:CreateTexture()
	ntex:SetTexture("Interface\\Buttons\\UI-Panel-QuestHideButton")
	ntex:SetTexCoord(0,0.5,0.5,1)
	ntex:SetAllPoints()	
	ObjectiveTracker_Minimize_button:SetNormalTexture(ntex)
	
	local htex = ObjectiveTracker_Minimize_button:CreateTexture()
	htex:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    htex:SetBlendMode("ADD")
	htex:SetAllPoints()
	ObjectiveTracker_Minimize_button:SetHighlightTexture(htex)
	
	local ptex = ObjectiveTracker_Minimize_button:CreateTexture()
	ptex:SetTexture("Interface\\Buttons\\UI-Panel-QuestHideButton")
	ptex:SetTexCoord(0.5,1,0.5,1)
	ptex:SetAllPoints()
	ObjectiveTracker_Minimize_button:SetPushedTexture(ptex)

    ObjectiveFrame:Hide()
    ObjectiveFrame_HeaderFrame:Hide()

end





function num(var)
    return var and 1 or 0
  end

function ObjectiveTracker:UpdateEnemyStates(packet)
    if not (instanceStatus == 1 or instanceStatus == 0) then return end
    EnemyData = JSONDecode(packet)
    enemiesLeft = EnemyData["enemiesLeft"]
    enemiesTotal = EnemyData["enemiesTotal"]
    if (ObjectivesFrame) then
        if (enemiesTotal > 0 and enemiesLeft >= enemiesTotal) then
            ObjectiveTracker_EnemyText:SetText(enemiesTotal.." / "..enemiesTotal.." Enemies")
            ObjectivePointer_Enemy:SetTexture(ScenariosCheckIcon)
        else
            ObjectiveTracker_EnemyText:SetText(enemiesLeft.." / "..enemiesTotal.." Enemies")
            ObjectivePointer_Enemy:SetTexture(ScenariosCombatIcon)
        end
    end
end

function ObjectiveTracker:UpdateBossState(packet)
    if not (instanceStatus == 1 or instanceStatus == 0) then return end
    InstanceData = JSONDecode(packet)
    BossData = InstanceData["Boss"]
    BossOrder = tonumber(InstanceData["Boss"]["Order"])

    ObjectiveTracker:CompleteObjective(BossOrder)
end

local function delay(tick)
    local th = coroutine.running()
    C_Timer.After(tick, function() coroutine.resume(th) end)
    coroutine.yield()
end
 
function ObjectiveTracker:HandleComplete(packet)
    CompleteData = JSONDecode(packet)
    instanceStatus = CompleteData["instanceStatus"]
    timerStatus = CompleteData["timerStatus"]
    flawlessStatus = CompleteData["flawlessStatus"]

    if instanceStatus == 2 then
        ObjectiveTracker:ShowCompleteBanner()
        ChallengeCompleteFrame:Show()

        if (TimerFrame) then
            TimerFrame:Hide()
            CMTimerRunning = false;
        end
        
        if(ObjectivesFrame) then
            ObjectivesFrame:Hide()
        end
        
        for i=0, 10 do
            if Objectives[i] then
                Objectives[i]:Hide()
            end
        end
    elseif instanceStatus == 3 then
        ObjectiveTracker:ShowCompleteBanner()
        ChallengeCompleteFrame:Show()

        if (TimerFrame) then
            TimerFrame:Hide()
            CMTimerRunning = false;
        end
        
        if(ObjectivesFrame) then
            ObjectivesFrame:Hide()
        end
        
        for i=0, 10 do
            if Objectives[i] then
                Objectives[i]:Hide()
            end
        end
    elseif instanceStatus == 0 then
        ChallengeCompleteFrame:Hide()

        if (TimerFrame) then
            TimerFrame:Hide()
            CMTimerRunning = false;
        end
        
        if(ObjectivesFrame) then
            ObjectivesFrame:Show()
        end
        
        for i=0, 10 do
            if Objectives[i] then
                Objectives[i]:Show()
            end
        end
    end
end

function ObjectiveTracker:CompleteObjective(bossOrder)
    

--[[
    local ag = ObjectivePointerSheen[bossOrder]:CreateAnimationGroup()  

    local a1 = ag:CreateAnimation("Translation")
    a1:SetStartDelay(1.06)
    a1:SetOffset(68, 0)    
    a1:SetDuration(0.48)
    a1:SetSmoothing("OUT")

    local a2 = ag:CreateAnimation("Alpha")
    a2:SetStartDelay(1.09)  
    a2:SetDuration(0.1)
    a2:SetChange(1)
    --a1:SetSmoothing("OUT")
    ag:Play()

    local a3 = ag:CreateAnimation("Alpha")
    a3:SetStartDelay(1.34)  
    a3:SetDuration(0.05)
    a3:SetChange(0)
    --a1:SetSmoothing("OUT")
    ag:Play()
]]

    local LineGlowAnim = ObjectiveLineGlow[bossOrder]:CreateAnimationGroup()  
    local LineSheenAnim = ObjectiveLineSheen[bossOrder]:CreateAnimationGroup()  
    -- Objective Glow
    local a1 = LineGlowAnim:CreateAnimation("Alpha")
    a1:SetStartDelay(0)  
    a1:SetDuration(0.05)
    a1:SetChange(1)

    a1:SetSmoothing("OUT")

    local a2 = LineGlowAnim:CreateAnimation("Scale")
    a2:SetStartDelay(0.067)
    a2:SetScale(220, 1)
    a2:SetDuration(0.333)
    a2:SetOrigin("LEFT", 0, 0)

    a2:SetSmoothing("OUT")

    local a3 = LineGlowAnim:CreateAnimation("Alpha")
    a3:SetStartDelay(0.444)  
    a3:SetDuration(0.3)
    a3:SetChange(-1)

    a3:SetSmoothing("OUT")

    -- Objective Sheen
    local a4 = LineSheenAnim:CreateAnimation("Alpha")
    a4:SetStartDelay(0)  
    a4:SetDuration(0.05)
    a4:SetChange(0.9)
    local a5 = LineSheenAnim:CreateAnimation("Translation")
    a5:SetStartDelay(0.167)
    a5:SetOffset(ObjectiveTracker_HeaderText[bossOrder]:GetStringWidth() / 1.5, 0)  
    a5:SetDuration(0.24)

    local a6 = LineSheenAnim:CreateAnimation("Alpha")
    a6:SetStartDelay(0.2)  
    a6:SetDuration(0.25)
    a6:SetChange(-1)

    LineGlowAnim:Play()

    LineSheenAnim:Play()


    ObjectiveTracker_HeaderText[bossOrder]:SetText("1 / 1 " .. Instances[GetCurrentMapAreaID()][2][bossOrder][1])
    ObjectivePointer[bossOrder]:SetTexture(ScenariosCombatIcon)
    local fadeInfo = {};
    fadeInfo.mode = "OUT";
    fadeInfo.timeToFade = 1;
    fadeInfo.startAlpha = 1;
    fadeInfo.endAlpha = 0;
    UIFrameFade(ObjectivePointer[bossOrder], fadeInfo);
    ObjectivePointer[bossOrder]:SetTexture(ScenariosCheckIcon)
    local fadeInfo = {};
    fadeInfo.mode = "IN";
    fadeInfo.timeToFade = 0.5;
    fadeInfo.startAlpha = 0;
    fadeInfo.endAlpha = 1;
    UIFrameFade(ObjectivePointer[bossOrder], fadeInfo);
end

function ObjectiveTracker:FillWorldStates(packet)
    if not (instanceStatus == 1 or instanceStatus == 0) then return end
    InstanceData = JSONDecode(packet)
    InstanceID = InstanceData["InstanceID"]

    if not (ObjectivesFrame) then
        -- Create Parent
        ObjectivesFrame = CreateFrame("Frame", "ObjectivesFrame", UIParent)
        ObjectivesFrame:RegisterEvent("PLAY")
        if CMTimerRunning == true then
            ObjectivesFrame:SetPoint("BOTTOM", "ObjectiveFrame_HeaderFrame", 50, -70)
        else
            ObjectivesFrame:SetPoint("BOTTOM", "ObjectiveFrame_HeaderFrame", 50, -18)
        end
        ObjectivesFrame:SetSize(400, 100)
        ChallengeCompleteFrame = CreateFrame("Frame","ChallengeComplete",UIParent)
        ChallengeCompleteFrame:SetFrameStrata("BACKGROUND")
        ChallengeCompleteFrame:SetWidth(235) -- Set these to whatever height/width is needed 
        ChallengeCompleteFrame:SetHeight(69) -- for your Texture
        ChallengeCompleteFrame:SetPoint("BOTTOM", "ObjectiveFrame_HeaderFrame", 0, -70)
        ChallengeCompleteFrame:RegisterEvent("PLAY")
        for i=1, 10 do
            Objectives[i] = CreateFrame("Frame", "ObjectiveFrame_"..i, UIParent)
            Objectives[i]:SetSize(297, 24)
            Objectives[i]:RegisterEvent("PLAY")

            if (i == 1) then
                Objectives[i]:SetPoint("CENTER", "ObjectivesFrame",0, -50)
            else
                point, relativeTo, relativePoint, xOfs, yOfs = Objectives[i - 1]:GetPoint()
                Objectives[i]:SetPoint("CENTER","ObjectivesFrame" , 0, yOfs - 25)

            end
            ObjectiveTracker_HeaderText[i] = Objectives[i]:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
            ObjectiveTracker_HeaderText[i]:SetText("")
            ObjectiveTracker_HeaderText[i]:SetSize(300,15)
            ObjectiveTracker_HeaderText[i]:SetVertexColor(1,1,1,0.8)
            ObjectiveTracker_HeaderText[i]:SetPoint("LEFT", 0, 0)

            ObjectivePointer[i] = Objectives[i]:CreateTexture(nil, "OVERLAY")
            ObjectivePointer[i]:SetTexture(ScenariosCombatIcon)
            ObjectivePointer[i]:SetSize(14,14)
            ObjectivePointer[i]:SetPoint("LEFT", -18, -1)

            ObjectiveLineSheen[i] = Objectives[i]:CreateTexture(nil, "OVERLAY")
            ObjectiveLineSheen[i]:SetTexture(ScenariosIconSheen)
            ObjectiveLineSheen[i]:SetSize(20,20)
            ObjectiveLineSheen[i]:SetVertexColor(1,1,1,0)
            ObjectiveLineSheen[i]:SetPoint("LEFT", 0, -3)

            ObjectiveLineGlow[i] = Objectives[i]:CreateTexture(nil, "OVERLAY")
            ObjectiveLineGlow[i]:SetTexture(ScenariosLineGlow)
            ObjectiveLineGlow[i]:SetSize(1,16)
            ObjectiveLineGlow[i]:SetVertexColor(1,1,1,0)
            ObjectiveLineGlow[i]:SetPoint("LEFT", 0, -2)
        end
        -- Create Childs
        for i = 1, #InstanceData["Boss"] do
            if(i == #InstanceData["Boss"]) then
                ObjectiveTracker_EnemyText = Objectives[i]:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
                ObjectiveTracker_EnemyText:SetText("")
                ObjectiveTracker_EnemyText:SetSize(300,15)
                ObjectiveTracker_EnemyText:SetVertexColor(1,1,1,0.8)
                ObjectiveTracker_EnemyText:SetPoint("LEFT", "ObjectiveFrame_"..i, 0 , -25)

                ObjectivePointer_Enemy = Objectives[i]:CreateTexture(nil, "ARTWORK")
                ObjectivePointer_Enemy:SetTexture(ScenariosCombatIcon)
                ObjectivePointer_Enemy:SetSize(14,14)
                ObjectivePointer_Enemy:SetPoint("LEFT", -18, -25)
            end       
        end
    end
    for i = 1, #InstanceData["Boss"] do
        if (InstanceData["Boss"][i]["Done"]) then
            if ObjectiveTracker_HeaderText[i] then
                ObjectiveTracker_HeaderText[i]:SetText("1 / 1 " .. Instances[GetCurrentMapAreaID()][2][i][1])
                ObjectiveTracker_HeaderText[i]:Show()
            end
            if ObjectivePointer[i] then
                ObjectivePointer[i]:SetTexture(ScenariosCheckIcon)
                ObjectivePointer[i]:Show()
            end   
        else
            if ObjectiveTracker_HeaderText[i] then
                ObjectiveTracker_HeaderText[i]:SetText("0 / 1 " .. Instances[GetCurrentMapAreaID()][2][i][1])
                ObjectiveTracker_HeaderText[i]:Show()
            end
            if ObjectivePointer[i] then
                ObjectivePointer[i]:SetTexture(ScenariosCombatIcon)
                ObjectivePointer[i]:Show()
            end
        end
        if (i == #InstanceData["Boss"]) then
            if(ObjectiveTracker_EnemyText) then
                ObjectiveTracker_EnemyText:SetPoint("LEFT", "ObjectiveFrame_".. i, 0 , -25)
            end
            if(ObjectivePointer_Enemy) then

                ObjectivePointer_Enemy:SetPoint("LEFT", "ObjectiveFrame_".. i, -18, -25)
            end
            for x = i + 1, 10 do
                if ObjectiveTracker_HeaderText[x] then
                    ObjectiveTracker_HeaderText[x]:Hide()
                end
                if ObjectivePointer[x] then
                    ObjectivePointer[x]:Hide()
                end
            end
        end
    end

    if (enemiesTotal > 0 and enemiesLeft >= enemiesTotal) then
        ObjectiveTracker_EnemyText:SetText(enemiesTotal.." / "..enemiesTotal.." Enemies")
        ObjectivePointer_Enemy:SetTexture(ScenariosCheckIcon)
    else
        ObjectiveTracker_EnemyText:SetText(enemiesLeft.." / "..enemiesTotal.." Enemies")
        ObjectivePointer_Enemy:SetTexture(ScenariosCombatIcon)
    end

end

local floor = math.floor

function UpdateBarClock(timeLeft, timeTotal, timerStatus, flawless)
    inInstance, instanceType = IsInInstance()
    if inInstance == 0 then
        if TimerFrame then
            TimerFrame:Hide()
        end
        if (ObjectivesFrame) then
            ObjectivesFrame:SetPoint("BOTTOM", "ChallengeModeTimer", 50, -20)
        end
        return
    end
    -- if not AddonEnabled then return end
    local seconds = tonumber(timeLeft)
    local frame = BarText
    if timerStatus == 0 then

    elseif timerStatus == 1 then

    elseif timerStatus ==(2 or 3) then
        if (ObjectivesFrame) then
            ObjectivesFrame:Hide()
        end
        if (TimerFrame) then
            -- TODO : Maximize Mini Timer
            TimerFrame:Hide()
        end
        for i=0, 10 do
            if Objectives[i] then
                Objectives[i]:Hide()
            end
        end
        ObjectiveTracker:ShowCompleteBanner()
    end
    if seconds == 0 then
        if not Frame_Collapsed then
            CMTimerRunning = false;
            local fadeInfo = {};
            fadeInfo.mode = "OUT";
            fadeInfo.timeToFade = 1;
            fadeInfo.startAlpha = 1;
            fadeInfo.endAlpha = 0;
            UIFrameFade(TimerFrame, fadeInfo);
            CM_Timer_BarText:SetText("00:00:00")

            if (ObjectivesFrame) then
                ObjectivesFrame:SetPoint("BOTTOM", "ChallengeModeTimer", 50, 40)
            end
        end
    else
        if not TimerFrame:IsVisible() then
            if not Frame_Collapsed then
                CMTimerRunning = true;
                local fadeInfo = {};
                fadeInfo.mode = "OUT";
                fadeInfo.timeToFade = 1;
                fadeInfo.startAlpha = 0;
                fadeInfo.endAlpha = 1;
                UIFrameFade(TimerFrame, fadeInfo);
                TimerFrame:Show()
                if (ObjectivesFrame) then
                    ObjectivesFrame:SetPoint("BOTTOM", "ChallengeModeTimer", 50, -18)
                end
            end
        end

      hours = string.format("%02.f", math.floor(seconds/3600));
      mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
      secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
      CM_Timer_BarText:SetText(hours..":"..mins..":"..secs)
    end

    -- Update bar length
    CM_Timer_BarFill:SetSize(((timeLeft / timeTotal ) * 184), 20)


end

  local flawless = false;
  function ObjectiveTracker:UpdateTimerData(data)
    if data == nil then return end
    local arr = JSONDecode(data)
    db.char.timerData = data
    timeLeft = arr["timeLeft"]
    timeTotal = arr["timeTotal"]
    timerStatus = arr["timerStatus"]
    flawlessStatus = arr["flawless"]

    if timeLeft == -1 then
        timeLeft = 0
    end

    if flawlessStatus == 0 then
        if flawless == false then
        flawless = true;
            -- Change medal from platinum to gold

            local fadeInfo = {};
            fadeInfo.mode = "OUT";
            fadeInfo.startDelay = 3;
            fadeInfo.timeToFade = 0.5;
            fadeInfo.startAlpha = 1;
            fadeInfo.endAlpha = 0;
            UIFrameFade(CM_Timer_Medal, fadeInfo);
            CM_Timer_Medal:SetTexture(CMHUD_GM_BLP)
            local fadeInfo = {};
            fadeInfo.mode = "IN";
            fadeInfo.startDelay = 3;
            fadeInfo.timeToFade = 0.5;
            fadeInfo.startAlpha = 0;
            fadeInfo.endAlpha = 1;
            UIFrameFade(CM_Timer_Medal, fadeInfo);

            local GlowAnim = CM_Timer_Medal_Glow:CreateAnimationGroup()

            local a1 = GlowAnim:CreateAnimation("Alpha") 
            a1:SetStartDelay(0.3)
            a1:SetChange(0.8)
            a1:SetDuration(0.4)
            a1:SetSmoothing("OUT")

            local a2 = GlowAnim:CreateAnimation("Alpha") 
            a2:SetStartDelay(0.8)
            a2:SetChange(-1)
            a2:SetDuration(0.66)
            a2:SetSmoothing("OUT")

            GlowAnim:Play()
        end
    end

    if(arr["timerStatus"] == 1) then
        if timeLeft > 0 then
            UpdateBarClock(timeLeft, timeTotal, timerStatus, flawlessStatus)
        else
            CM_Timer_BarText:SetText("00:00:00")
            CM_Timer_BarFill:SetSize(((0.01 / timeTotal ) * 184), 20)
        end
        if (ObjectivesFrame) then 
          ObjectivesFrame:SetPoint("BOTTOM", "ObjectiveFrame_HeaderFrame", 50, -70)
        end
    elseif(timerStatus == 2) then
        CMTimerRunning = false
        local MoveAnim = ObjectivesFrame:CreateAnimationGroup()  

        local ax1 = MoveAnim:CreateAnimation("Translation")
        ax1:SetStartDelay(3)
        ax1:SetOffset(100, 20)  
        ax1:SetDuration(0.44)
    
        MoveAnim:Play()


        if (TimerFrame) then
            local fadeInfo = {};
            fadeInfo.mode = "OUT";
            fadeInfo.timeToFade = 0.5;
            fadeInfo.startAlpha = 1;
            fadeInfo.endAlpha = 0;
            UIFrameFade(TimerFrame, fadeInfo);
        end
        if (ObjectivesFrame) then 
            ObjectivesFrame:SetPoint("BOTTOM", "ObjectiveFrame_HeaderFrame", 50, -18)

        end
    elseif(timerStatus == 3) then
        -- DONE
    end
end





local OBJ_TOAST = {
    [0] = { 0.00195312, 0.609375, 0.189453, 0.341797 }, -- Toast-Frame
    [1] = { 0.00195312, 0.640625, 0.00195312, 0.185547 }, -- Toast-Flash
    [2] = {}, -- Toast-IconBG
    [3] = {}, -- Bonus-ToastBanner
    [4] = { 0.480469, 0.939453, 0.345703, 0.480469 }, -- ScenarioTrackerToast-FinalFiligree
    [5] = { 0.00195312, 0.476562, 0.345703, 0.496094 }, -- ScenarioTrackerToast
    
}

local OBJ_TOAST_SZ = {
    [0] = { 311, 78 },
    [1] = { 327, 94 },
    [2] = { 47, 52 },
    [3] = { 36, 44 },
    [4] = { 235, 69 },
    [5] = { 243, 77 },
}
CompleteFrameBG = {}
CmpleteFrameBorder = {}
ToastFlash = {}
CompleteLabel = {}
function ObjectiveTracker:HideCompleteBanner()
    if ChallengeCompleteFrame then
        ChallengeCompleteFrame:Hide() 
    end
end

function ObjectiveTracker:ShowCompleteBanner()
    local CompleteFrameBG = ChallengeCompleteFrame:CreateTexture(nil,"OVERLAY",nil,-5)
    local CompleteFrameBorder = ChallengeCompleteFrame:CreateTexture(nil,"OVERLAY",nil,-2)
    local ToastFlash = ChallengeCompleteFrame:CreateTexture(nil,"OVERLAY",nil,-3)
    local CompleteLabel = ChallengeCompleteFrame:CreateFontString(nil, "OVERLAY", "QuestTitleFont")

    CompleteFrameBG:SetTexture("Interface\\OBJECTIVEFRAME\\ScenarioParts.blp")
    CompleteFrameBG:SetTexCoord(unpack(OBJ_TOAST[5]))
    CompleteFrameBG:SetSize(unpack(OBJ_TOAST_SZ[5]))
    CompleteFrameBG:SetPoint("CENTER", "ChallengeComplete",  0, 0)
    CompleteFrameBG:SetAllPoints(ChallengeCompleteFrame)
    CompleteFrameBG:SetAlpha(0)
    ChallengeCompleteFrame.texture = CompleteFrameBG
    local fadeInfo = {};
    fadeInfo.mode = "IN";
    fadeInfo.timeToFade = 0.1;
    fadeInfo.startAlpha = 0;
    fadeInfo.endAlpha = 1;
    UIFrameFade(CompleteFrameBG, fadeInfo);


    CompleteFrameBorder:SetTexture("Interface\\OBJECTIVEFRAME\\ScenarioParts.blp")
    CompleteFrameBorder:SetTexCoord(unpack(OBJ_TOAST[4]))
    CompleteFrameBorder:SetSize(unpack(OBJ_TOAST_SZ[4]))
    CompleteFrameBorder:SetPoint("LEFT", 0, 0)
    CompleteFrameBorder:SetAllPoints(ChallengeCompleteFrame)
    CompleteFrameBorder:SetAlpha(0)
    ChallengeCompleteFrame.texture = CompleteFrameBorder
    local fadeInfo = {};
    fadeInfo.mode = "IN";
    fadeInfo.timeToFade = 0.5;
    fadeInfo.startAlpha = 0;
    fadeInfo.endAlpha = 1;
    UIFrameFade(CompleteFrameBorder, fadeInfo);

    ToastFlash:SetTexture("Interface\\OBJECTIVEFRAME\\ScenarioParts.blp")
    ToastFlash:SetTexCoord(unpack(OBJ_TOAST[1]))
    ToastFlash:SetSize(340, 94)
    ToastFlash:SetPoint("BOTTOM", 0, 0)
    ToastFlash:SetBlendMode("ADD")
    ToastFlash:SetAlpha(0)
    ToastFlash:SetAllPoints(ChallengeCompleteFrame)

    ChallengeCompleteFrame.texture = ToastFlash
    local fadeInfo = {};
    fadeInfo.mode = "IN";
    fadeInfo.startDelay = 3;
    fadeInfo.timeToFade = 0.5;
    fadeInfo.startAlpha = 0;
    fadeInfo.endAlpha = 0;
    UIFrameFade(ToastFlash, fadeInfo);
    fadeInfo.mode = "OUT";
    fadeInfo.startDelay = 6;
    fadeInfo.timeToFade = 0.5;
    fadeInfo.startAlpha = 0;
    fadeInfo.endAlpha = 0;
    UIFrameFade(ToastFlash, fadeInfo);
    

    CompleteLabel:SetText("COMPLETED!")
    CompleteLabel:SetSize(172,18)
    CompleteLabel:SetVertexColor(1,0.914,0.682,0.7)
    CompleteLabel:SetPoint("LEFT", -20, 0)
    local fadeInfo = {};
    fadeInfo.mode = "IN";
    fadeInfo.timeToFade = 1.5;
    fadeInfo.startAlpha = 0;
    fadeInfo.endAlpha = 0.7;
    UIFrameFade(CompleteLabel, fadeInfo);
    ChallengeCompleteFrame.texture = CompleteLabel

    ChallengeCompleteFrame:Show() 
end


local function OnEvent(self, event, isLogin, isReload)
	SendAddonMessage("WCPM-ValidateCM-"..GetAddOnMetadata("TimeTracker", "version"), "", "WHISPER", UnitName("player"));
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", OnEvent)



waitFrame:SetScript("OnUpdate", function(self, elapsed)
	local total = #waitTable
	local i = 1

	while i <= total do
		local ticker = waitTable[i]

		if ticker._cancelled then
			tremove(waitTable, i)
			total = total - 1
		elseif ticker._delay > elapsed then
			ticker._delay = ticker._delay - elapsed
			i = i + 1
		else
			ticker._callback(ticker)

			if ticker._remainingIterations == -1 then
				ticker._delay = ticker._duration
				i = i + 1
			elseif ticker._remainingIterations > 1 then
				ticker._remainingIterations = ticker._remainingIterations - 1
				ticker._delay = ticker._duration
				i = i + 1
			elseif ticker._remainingIterations == 1 then
				tremove(waitTable, i)
				total = total - 1
			end
		end
	end

	if #waitTable == 0 then self:Hide() end
end)

local function AddDelayedCall(ticker, oldTicker)
	if oldTicker and type(oldTicker) == "table" then ticker = oldTicker end

	tinsert(waitTable, ticker)
	waitFrame:Show()
end

_G.AddDelayedCall = AddDelayedCall

local function CreateTicker(duration, callback, iterations)
	local ticker = setmetatable({}, TickerMetatable)
	ticker._remainingIterations = iterations or -1
	ticker._duration = duration
	ticker._delay = duration
	ticker._callback = callback

	AddDelayedCall(ticker)

	return ticker
end

function C_Timer.After(duration, callback) 
    AddDelayedCall({_remainingIterations = 1, _delay = duration, _callback = callback}) 
end

function C_Timer.NewTimer(duration, callback) 
    return CreateTicker(duration, callback, 1) 
end

function C_Timer.NewTicker(duration, callback, iterations) 
    return CreateTicker(duration, callback, iterations) 
end

function TickerPrototype:Cancel() 
    self._cancelled = true 
end


local function DisplayTime(tens, ones)
    timer.AnimGroup:Stop()

    if timer.seconds < 0 then
        StopTimer()
        return
    end
    timer.AnimGroup:Play()

    timer.digit1:SetSize(256, 170)
    timer.digit1.glow:SetSize(256, 170)

    timer.digit2:SetSize(256, 170)
    timer.digit2.glow:SetSize(256, 170)

    if tens > 0 then
        timer.digit1:SetTexCoord(unpack(DigitCoord[tens]))
        timer.digit1.glow:SetTexCoord(unpack(DigitCoord[tens]))
        -- set digit 1 position 
        local hw = DigitHalfWidth[tens] + DigitHalfWidth[ones]
        timer.digit1:SetPoint("CENTER", UIParent, "CENTER", -hw, 0)
        timer.digit1.glow:SetPoint("CENTER", timer.digit1)
        -- set digit 2 position
        timer.digit2:SetPoint("CENTER", UIParent, "CENTER", hw, 0)
        timer.digit2.glow:SetPoint("CENTER", timer.digit2)
    else
        timer.digit1:SetTexCoord(0, 0, 0, 0)
        timer.digit1.glow:SetTexCoord(0, 0, 0, 0)

        timer.digit1:SetPoint("CENTER", UIParent)
        timer.digit1.glow:SetPoint("CENTER", timer.digit1)

        timer.digit2:SetPoint("CENTER", UIParent)
        timer.digit2.glow:SetPoint("CENTER", timer.digit2)
    end

    if tens == 0 and ones == 0 and timer.isChallenge then
        timer.digit2:SetSize(256, 256)
        timer.digit2.glow:SetSize(256, 256)
		PlaySoundFile("sound\\interface\\ui_battlegroundcountdown_end.mp3", "SFX")
        timer.digit2:SetTexture("Interface\\Timer\\Challenges-Logo")
        timer.digit2.glow:SetTexture("Interface\\Timer\\ChallengesGlow-Logo")
        timer.digit2:SetTexCoord(0, 1, 0, 1)
        timer.digit2.glow:SetTexCoord(0, 1, 0, 1)
    else
        if timer.seconds <= SoundThreshold then
			PlaySoundFile("sound\\interface\\ui_battlegroundcountdown_timer.mp3", "SFX")
        end
        timer.digit2:SetTexCoord(unpack(DigitCoord[ones]))
        timer.digit2.glow:SetTexCoord(unpack(DigitCoord[ones]))
    end
end

local function Tick()
    local seconds = timer.seconds
    local tens = floor(seconds / 10)
    local ones = seconds % 10

    DisplayTime(tens, ones)
    timer.seconds = timer.seconds - 1
end

local function CreateDigitTexture(parent)
    local digit = parent:CreateTexture(nil, "ARTWORK")
    digit:SetTexture("Interface\\Timer\\BigTimerNumbers")
    digit:SetPoint("CENTER")
    digit.glow = parent:CreateTexture(nil, "BACKGROUND")
    digit.glow:SetTexture("Interface\\Timer\\BigTimerNumbersGlow")
    digit.glow:SetPoint("CENTER", digit)
    digit.glow:SetVertexColor(50, 50, 50, 50)

    digit:SetSize(256, 170)
    digit.glow:SetSize(256, 170)
    return digit
end

local function CreateAnimationGroup()
    local ag = timer:CreateAnimationGroup()
    ag.Scale1 = ag:CreateAnimation("Scale")
    ag.Scale2 = ag:CreateAnimation("Scale")
    ag.Alpha1 = ag:CreateAnimation("Alpha")
    ag.Alpha2 = ag:CreateAnimation("Alpha")

    ag.Scale1:SetStartDelay(0)
    ag.Scale1:SetOrder(1)
    ag.Scale1:SetDuration(0.001)

    ag.Scale2:SetStartDelay(0.01)
    ag.Scale2:SetOrder(2)
    ag.Scale2:SetDuration(0.5)

    ag.Scale1:SetScale(0, 0)
    ag.Scale2:SetScale(1000, 1000)

    ag.Alpha1:SetChange(1)
    ag.Alpha1:SetOrder(1)
    ag.Alpha1:SetDuration(0.01)
    ag.Alpha1:SetStartDelay(0)

    ag.Alpha1:SetScript("OnStop", function(self)
        self:GetParent():GetParent():SetAlpha(1)
    end)
    ag.Alpha1:SetScript("OnFinished", function(self)
        self:GetParent():GetParent():SetAlpha(1)
    end)
    ag.Alpha1:SetScript("OnPlay", function(self)
        self:GetParent():GetParent():SetAlpha(0)
    end)

    ag.Alpha2:SetChange(-1)
    ag.Alpha2:SetOrder(3)
    ag.Alpha2:SetDuration(0.5)
    ag.Alpha2:SetStartDelay(0.1)

    timer.AnimGroup = ag
end



-- same as Addon:StartTimer but displays the challenge mode logo at the end of the timer
local function StartChallengeTimer(seconds)
    
	if seconds == 0 then
		print("Value must be bigger than 0 seconds.")
		return
	end
    if seconds > 60 then
        print("Cannot start a countdown timer longer than 60 seconds")
        return
    end
    StartTimer(seconds)
    timer.isChallenge = true
end

function StartTimer(seconds)
    if seconds > 60 then
        print("Cannot start a countdown timer longer than 60 seconds")
        return
    end

    if IsTimerPlaying() then
        StopTimer()
    end

    if not timer then
        timer = CreateFrame("Frame", "BigTimer", UIParent)
        timer:SetPoint("CENTER")
        timer:SetSize(512, 512)
        timer.digit1 = CreateDigitTexture(timer)
        timer.digit2 = CreateDigitTexture(timer)
        CreateAnimationGroup()
    end

    timer.digit1:SetSize(256, 170)
    timer.digit1.glow:SetSize(256, 170)

    timer.digit2:SetSize(256, 170)
    timer.digit2.glow:SetSize(256, 170)

    timer.digit1:SetTexture("Interface\\Timer\\BigTimerNumbers")
    timer.digit2:SetTexture("Interface\\Timer\\BigTimerNumbers")

    timer.digit1.glow:SetTexture("Interface\\Timer\\BigTimerNumbersGlow")
    timer.digit2.glow:SetTexture("Interface\\Timer\\BigTimerNumbersGlow")

    local tens = floor(seconds / 10)
    local ones = seconds % 10
    timer.seconds = seconds - 1

    DisplayTime(tens, ones)
    
    if seconds <= SoundThreshold then
		PlaySoundFile("sound\\interface\\ui_battlegroundcountdown_timer.mp3", "SFX")
    end
    timer.AnimGroup:Stop()
    timer.AnimGroup:Play()
    timer.ticker = C_Timer.NewTicker(1, Tick, timer.seconds + 2)

    timer:Show()
end

function StopTimer()
    timer.ticker:Cancel()
    timer.ticker = nil
    timer.isChallenge = false
    timer:Hide()
end

function IsTimerPlaying()
    return timer and timer.ticker ~= nil
end



local pairs, ipairs, tonumber, tostring = pairs, ipairs, tonumber, tostring
local setmetatable, type, error = setmetatable, type, error
local format, gsub, strfind, strsub, strchar, strbyte, floor = format, gsub, strfind, strsub, strchar, strbyte, floor

 local _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local byteToNum = {}
  local numToChar = {}
  for i = 1, #_chars do
      numToChar[i - 1] = _chars:sub(i, i)
      byteToNum[_chars:byte(i)] = i - 1
  end
  _chars = nil
  local A_byte = ("A"):byte()
  local Z_byte = ("Z"):byte()
  local a_byte = ("a"):byte()
  local z_byte = ("z"):byte()
  local zero_byte = ("0"):byte()
  local nine_byte = ("9"):byte()
  local plus_byte = ("+"):byte()
  local slash_byte = ("/"):byte()
  local equals_byte = ("="):byte()
  local whitespace = {
      [(" "):byte()] = true,
      [("\t"):byte()] = true,
      [("\n"):byte()] = true,
      [("\r"):byte()] = true,
  }
local t = {}
local null = {} -- table ref to use for Null


local JsonWriter = {
	backslashes = {
		['\b'] = "\\b",
		['\t'] = "\\t",	
		['\n'] = "\\n", 
		['\f'] = "\\f",
		['\r'] = "\\r", 
		['"']  = "\\\"", 
		['\\'] = "\\\\", 
		['/']  = "\\/"
	}
}

function JsonWriter:New()
	local o = {buffer={}}
	setmetatable(o, self)
	self.__index = self
	return o
end

function JsonWriter:Append(s)
	self.buffer[#self.buffer+1] = s
	if #self.buffer > 1000 then
		local temp = table.concat(self.buffer)
		self.buffer = {temp}
	end
end

function JsonWriter:ToString()
	return table.concat(self.buffer)
end

function JsonWriter:Write(o)
	local t = type(o)
	if t == "nil" or o == null then
		self:Append("null")
	elseif t == "boolean" or t == "number" then
		self:Append(tostring(o))
	elseif t == "string" then
		self:ParseString(o)
	elseif t == "table" then
		self:WriteTable(o)
	else
		error(format("Encoding of %s unsupported", tostring(o)))
	end
end

function JsonWriter:ParseString(s)
	self:Append('"')
	self:Append(gsub(s, "[%z%c\\\"/]", function(n)
			local c = self.backslashes[n]
			if c then return c end
			return format("\\u%.4X", strbyte(n))
		end))
	self:Append('"')
end

function JsonWriter:IsArray(t)
	local count = 0
	local isindex = function(k) 
		if type(k) == "number" and k > 0 then
			if floor(k) == k then
				return true
			end
		end
		return false
	end
	for k,v in pairs(t) do
		if not isindex(k) then
			return false, '{', '}'
		else
			count = max(count, k)
		end
	end
	return true, '[', ']', count
end

function JsonWriter:WriteTable(t)
	local ba, st, et, n = self:IsArray(t)
	self:Append(st)	
	if ba then		
		for i = 1, n do
			self:Write(t[i])
			if i < n then
				self:Append(',')
			end
		end
	else
		local first = true;
		for k, v in pairs(t) do
			if not first then
				self:Append(',')
			end
			first = false;			
			self:ParseString(k)
			self:Append(':')
			self:Write(v)			
		end
	end
	self:Append(et)
end


local StringReader = {
	s = "",
	i = 0
}

function StringReader:New(s)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.s = s or o.s
	return o	
end

function StringReader:Peek()
	local i = self.i + 1
	if i <= #self.s then
		return strsub(self.s, i, i)
	end
	return nil
end

function StringReader:Next()
	self.i = self.i+1
	if self.i <= #self.s then
		return strsub(self.s, self.i, self.i)
	end
	return nil
end

function StringReader:All()
	return self.s
end

local JsonReader = {
	escapes = {
		['t'] = '\t',
		['n'] = '\n',
		['f'] = '\f',
		['r'] = '\r',
		['b'] = '\b',
	}
}

function JsonReader:New(s)
	local o = {}
	o.reader = StringReader:New(s)
	setmetatable(o, self)
	self.__index = self
	return o;
end

function JsonReader:Read()
	self:SkipWhiteSpace()
	local peek = self:Peek()
	if peek == nil then
        peek = 0
		-- return self:ReadNull()
        --error(format("Nil string: '%s'", self:All()))
	elseif peek == '{' then
		return self:ReadObject()
	elseif peek == '[' then
		return self:ReadArray()
	elseif peek == '"' then
		return self:ReadString()
	elseif strfind(peek, "[%+%-%d]") then
		return self:ReadNumber()
	elseif peek == 't' then
		return self:ReadTrue()
	elseif peek == 'f' then
		return self:ReadFalse()
	elseif peek == 'n' then
		return self:ReadNull()
	elseif peek == '/' then
		self:ReadComment()
		return self:Read()
	else
		error(format("Invalid input: '%s'", self:All()))
	end
end
		
function JsonReader:ReadTrue()
	self:TestReservedWord{'t','r','u','e'}
	return true
end

function JsonReader:ReadFalse()
	self:TestReservedWord{'f','a','l','s','e'}
	return false
end

function JsonReader:ReadNull()
	self:TestReservedWord{'n','u','l','l'}
	return nil
end

function JsonReader:TestReservedWord(t)
	for i, v in ipairs(t) do
		if self:Next() ~= v then
			error(format("Error reading '%s': %s", table.concat(t), self:All()))
		end
	end
end

function JsonReader:ReadNumber()
	local result = self:Next()
	local peek = self:Peek()
	while peek ~= nil and strfind(peek, "[%+%-%d%.eE]") do
		result = result .. self:Next()
		peek = self:Peek()
	end
	result = tonumber(result)
	if result == nil then
		error(format("Invalid number: '%s'", result))
	else
		return result
	end
end

function JsonReader:ReadString()
	local result = ""
	if self:Next() ~= '"' then error("Assertion error: self:Next() ~= '\"'") end
	while self:Peek() ~= '"' do
		local ch = self:Next()
		if ch == '\\' then
			ch = self:Next()
			if self.escapes[ch] then
				ch = self.escapes[ch]
			end
		end
		result = result .. ch
	end
	
	if self:Next() ~= '"' then error("Assertion error: self:Next() ~= '\"'") end
	return gsub(result, "u%x%x(%x%x)", function(m) return strchar(tonumber(m, 16)) end)
end

function JsonReader:ReadComment()
	if self:Next() ~= '/' then error("Assertion error: self:Next() ~= '/'") end
	local second = self:Next()
	if second == '/' then
		self:ReadSingleLineComment()
	elseif second == '*' then
		self:ReadBlockComment()
	else
		error(format("Invalid comment: %s", self:All()))
	end
end

function JsonReader:ReadBlockComment()
	local done = false
	while not done do
		local ch = self:Next()		
		if ch == '*' and self:Peek() == '/' then
			done = true
		end
		if not done and ch == '/' and self:Peek() == "*" then
			error(format("Invalid comment: %s, '/*' illegal.", self:All()))
		end
	end
	self:Next()
end

function JsonReader:ReadSingleLineComment()
	local ch = self:Next()
	while ch ~= '\r' and ch ~= '\n' do
		ch = self:Next()
	end
end

function JsonReader:ReadArray()
	local result = {}
	if self:Next() ~= '[' then error("Assertion error: self:Next() ~= '['") end
	local done = false
	if self:Peek() == ']' then
		done = true;
	end
	while not done do
		local item = self:Read()
		result[#result+1] = item
		self:SkipWhiteSpace()
		if self:Peek() == ']' then
			done = true
		end
		if not done then
			local ch = self:Next()
			if ch ~= ',' then
				error(format("Invalid array: '%s' due to: '%s'", self:All(), ch))
			end
		end
	end
	if self:Next() ~= ']' then error("Assertion error: self:Next() ~= ']'") end
	return result
end

function JsonReader:ReadObject()
	local result = {}
	if self:Next() ~= '{' then error("Assertion error: self:Next() ~= '{'") end
	local done = false
	if self:Peek() == '}' then
		done = true
	end
	while not done do
		local key = self:Read()
		if type(key) ~= "string" then
			error(format("Invalid non-string object key: %s", key))
		end
		self:SkipWhiteSpace()
		local ch = self:Next()
		if ch ~= ':' then
			error(format("Invalid object: '%s' due to: '%s'", self:All(), ch))
		end
		self:SkipWhiteSpace()
		local val = self:Read()
		result[key] = val
		self:SkipWhiteSpace()
		if self:Peek() == '}' then
			done = true
		end
		if not done then
			ch = self:Next()
			if ch ~= ',' then
				--error(format("Invalid array: '%s' near: '%s'", self:All(), ch))
			end
		end
	end
	if self:Next() ~= "}" then error("Assertion error: self:Next() ~= '}'") end
	return result
end

function JsonReader:SkipWhiteSpace()
	local p = self:Peek()
	while p ~= nil and strfind(p, "[%s/]") do
		if p == '/' then
			self:ReadComment()
		else
			self:Next()
		end
		p = self:Peek()
	end
end

function JsonReader:Peek()
	return self.reader:Peek()
end

function JsonReader:Next()
	return self.reader:Next()
end

function JsonReader:All()
	return self.reader:All()
end

function JSONEncode(o)
	local writer = JsonWriter:New()
	writer:Write(o)
	return writer:ToString()
end

function JSONDecode(s)
	local reader = JsonReader:New(s)
	return reader:Read()
end

function JSONNull()
	return null
end




-- ###############################################################
--                         CSV Functions
-- ###############################################################

function CSVEncode(keys, data)
	local lines = {}
	tinsert(lines, table.concat(keys, ","))
	for _, entry in ipairs(data) do
		local lineParts = {}
		for _, key in ipairs(keys) do
			tinsert(lineParts, entry[key] or "")
		end
		tinsert(lines, table.concat(lineParts, ","))
	end
	return table.concat(lines, "\n")
end

local function SafeStrSplit(str, sep)
	local parts = {}
	local s = 1
	while true do
		local e = strfind(str, sep, s)
		if not e then
			tinsert(parts, strsub(str, s))
			break
		end
		tinsert(parts, strsub(str, s, e-1))
		s = e + 1
	end
	return parts
end

function CSVDecode(str)
	local keys
	local result = {}
	local lines = SafeStrSplit(str, "\n")
	for i, line in ipairs(lines) do
		if i == 1 then
			keys = {(","):split(lines[1])}
		else
			local entry = {}
			local lineParts = {(","):split(line)}
			for j, key in ipairs(keys) do
				if lineParts[j] ~= "" then
					entry[key] = tonumber(lineParts[j]) or lineParts[j]
				end
			end
			tinsert(result, entry)
		end
	end
	return keys, result
end

  function Encode(text, maxLineLength, lineEnding)
      if type(text) ~= "string" then
          error(("Bad argument #1 to `Encode'. Expected %q, got %q"):format("string", type(text)), 2)
      end
      
      if maxLineLength == nil then
          -- do nothing
      elseif type(maxLineLength) ~= "number" then
          error(("Bad argument #2 to `Encode'. Expected %q or %q, got %q"):format("number", "nil", type(maxLineLength)), 2)
      elseif (maxLineLength % 4) ~= 0 then
          error(("Bad argument #2 to `Encode'. Expected a multiple of 4, got %s"):format(maxLineLength), 2)
      elseif maxLineLength <= 0 then
          error(("Bad argument #2 to `Encode'. Expected a number > 0, got %s"):format(maxLineLength), 2)
      end
      
      if lineEnding == nil then
          lineEnding = "\r\n"
      elseif type(lineEnding) ~= "string" then
          error(("Bad argument #3 to `Encode'. Expected %q, got %q"):format("string", type(lineEnding)), 2)
      end
      
      local currentLength = 0
      
      for i = 1, #text, 3 do
          local a, b, c = text:byte(i, i+2)
          local nilNum = 0
          if not b then
              nilNum = 2
              b = 0
              c = 0
          elseif not c then
              nilNum = 1
              c = 0
          end
          local num = a * 2^16 + b * 2^8 + c
          
          local d = num % 2^6
          num = (num - d) / 2^6
          
          local c = num % 2^6
          num = (num - c) / 2^6
          
          local b = num % 2^6
          num = (num - b) / 2^6
          
          local a = num % 2^6
          
          t[#t+1] = numToChar[a]
          
          t[#t+1] = numToChar[b]
          
          t[#t+1] = (nilNum >= 2) and "=" or numToChar[c]
          
          t[#t+1] = (nilNum >= 1) and "=" or numToChar[d]
          
          currentLength = currentLength + 4
          if maxLineLength and (currentLength % maxLineLength) == 0 then
              t[#t+1] = lineEnding
          end
      end
      
      local s = table.concat(t)
      for i = 1, #t do
          t[i] = nil
      end
      return s
  end
  
  local t2 = {}






  --- Decode a Base64-encoded string into a bytestring
-- this will raise an error if the data passed in is not a Base64-encoded string
-- this will ignore whitespace, but not invalid characters
-- @param text a Base64-encoded string
-- @usage LibBase64.Encode("SGVsbG8sIGhvdyBhcmUgeW91IGRvaW5nIHRvZGF5Pw==") == "Hello, how are you doing today?"
-- @return a bytestring
function Decode(text)
    if type(text) ~= "string" then
        error(("Bad argument #1 to `Decode'. Expected %q, got %q"):format("string", type(text)), 2)
    end
    
    for i = 1, #text do
        local byte = text:byte(i)
        if whitespace[byte] or byte == equals_byte then
            -- do nothing
        else
            local num = byteToNum[byte]
            if not num then
                for i = 1, #t2 do
                    t2[k] = nil
                end
                
                error(("Bad argument #1 to `Decode'. Received an invalid char: %q"):format(text:sub(i, i)), 2)
            end
            t2[#t2+1] = num
        end
    end
    
    for i = 1, #t2, 4 do
        local a, b, c, d = t2[i], t2[i+1], t2[i+2], t2[i+3]
        
		local nilNum = 0
		if not c then
			nilNum = 2
			c = 0
			d = 0
		elseif not d then
			nilNum = 1
			d = 0
		end
		
		local num = a * 2^18 + b * 2^12 + c * 2^6 + d
		
		local c = num % 2^8
		num = (num - c) / 2^8
		
		local b = num % 2^8
		num = (num - b) / 2^8
		
		local a = num % 2^8
		
		t[#t+1] = string.char(a)
		if nilNum < 2 then
			t[#t+1] = string.char(b)
		end
		if nilNum < 1 then
			t[#t+1] = string.char(c)
		end
	end
	
	for i = 1, #t2 do
		t2[i] = nil
	end
	
	local s = table.concat(t)
	
	for i = 1, #t do
		t[i] = nil
	end
	
	return s
end



local SendReceive = function(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" then
		if (prefix ~= "WCPM") then
			ssi = Split(prefix, "-")
			if (ssi[2] == "ChallengeTimer") then
			StartChallengeTimer(tonumber(ssi[3]));
            elseif (ssi[2] == "ObjectiveTracker") then
                if (ssi[3] == "Timer") then
                    ObjectiveTracker:UpdateTimerData(ssi[4])
                elseif(ssi[3] == "OBData") then
                    ObjectiveTracker:FillWorldStates(ssi[4])
                elseif(ssi[3] == "ECounter") then
                    ObjectiveTracker:UpdateEnemyStates(ssi[4])
                elseif(ssi[3] == "UpdateBossState") then
                    ObjectiveTracker:UpdateBossState(ssi[4])
                elseif(ssi[3] == "ChallengeComplete") then
                    ObjectiveTracker:HandleComplete(ssi[4])
                elseif(ssi[3] == "Enable") then
                    ObjectiveTracker:EnableAddon()
                end
            elseif (ssi[2] == "VerifyChallenge") then
				SendAddonMessage("WCPM", "iHaveIt", "WHISPER", UnitName("player"));
			end
		end
    end
    if event == "PLAYER_ENTERING_WORLD" then
        inInstance, instanceType = IsInInstance()
        instanceType = select(3, GetInstanceInfo())
        MinimapBannerFrame:Hide()
        
        if inInstance == 1 then
            if not instanceType == 3 then return end
            SendAddonMessage("WCPM-ObtainObjectiveData", "", "WHISPER", UnitName("player"))
            currIns = GetCurrentMapAreaID()
            

	        ObjectiveTracker:EnableAddon()
            if (TimerFrame) then
                if (timeLeft > 0) then
                    TimerFrame:Show()
                end
            end
            if GetCurrentMapAreaID() == 603 then
                if (ObjectivesFrame) then
                    ObjectivesFrame:Hide()
                end
            end
            if (ObjectivesFrame) then
                ObjectivesFrame:SetPoint("BOTTOM", "ChallengeModeTimer", 50, -20)
            end

        else
            ObjectiveTracker:DisableAddon();
            ObjectiveTracker:HideCompleteBanner()
            if (TimerFrame) then
                TimerFrame:Hide()
                timeLeft = 0;
                timeTotal = 0;
                CMTimerRunning = false;
            end

            UpdateBarClock(timeLeft, timeTotal, timerStatus, flawless)
            if(ChallengeCompleteFrame) then
                ChallengeCompleteFrame:Hide()
            end
        end
    end
    if event == "VARIABLES_LOADED" and arg1 == "ObjectiveTracker" then
        LoadVariables()
    end    
end
local CheckMessages = CreateFrame("Frame")
CheckMessages:RegisterEvent("PLAYER_ENTERING_WORLD")
CheckMessages:RegisterEvent("RAID_ROSTER_UPDATE")
CheckMessages:RegisterEvent("PARTY_MEMBERS_CHANGED")
CheckMessages:RegisterEvent("CHAT_MSG_ADDON")
CheckMessages:RegisterEvent("COMBAT_LOG_EVENT")
CheckMessages:RegisterEvent("VARIABLES_LOADED")
CheckMessages:SetScript("OnEvent", SendReceive)