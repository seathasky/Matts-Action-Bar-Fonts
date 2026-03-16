local addonName, MABF = ...

-----------------------------------------------------------
-- Quest Tweaks (Auto Accept / Auto Turn In)
-----------------------------------------------------------
function MABF:SetupQuestTweaks()
    local db = MattActionBarFontDB
    if not db then return end

    if not self._questFrame then
        self._questFrame = CreateFrame("Frame")
    end
    local qf = self._questFrame

    qf:UnregisterAllEvents()
    qf:SetScript("OnEvent", nil)

    if not db.autoAcceptQuests and not db.autoTurnInQuests then
        return
    end

    local function CanAutoAccept()
        return db.autoAcceptQuests and not IsShiftKeyDown()
    end
    local function CanAutoTurnIn()
        return db.autoTurnInQuests and not IsShiftKeyDown()
    end

    qf:RegisterEvent("QUEST_DETAIL")
    qf:RegisterEvent("QUEST_PROGRESS")
    qf:RegisterEvent("QUEST_COMPLETE")
    qf:RegisterEvent("QUEST_GREETING")
    qf:RegisterEvent("GOSSIP_SHOW")

    qf:SetScript("OnEvent", function(_, event)
        if event == "QUEST_DETAIL" then
            if CanAutoAccept() then AcceptQuest() end
        elseif event == "QUEST_PROGRESS" then
            if CanAutoTurnIn() and IsQuestCompletable() then CompleteQuest() end
        elseif event == "QUEST_COMPLETE" then
            if CanAutoTurnIn() then
                local numChoices = GetNumQuestChoices() or 0
                if numChoices == 0 then GetQuestReward(1) end
            end
        elseif event == "QUEST_GREETING" then
            if CanAutoTurnIn() then
                local activeQuests = GetNumActiveQuests() or 0
                for index = 1, activeQuests do
                    local _, isComplete = GetActiveTitle(index)
                    if isComplete then SelectActiveQuest(index) return end
                end
            end
            if CanAutoAccept() then
                local availableQuests = GetNumAvailableQuests() or 0
                if availableQuests > 0 then SelectAvailableQuest(1) end
            end
        elseif event == "GOSSIP_SHOW" then
            if not C_GossipInfo then return end
            if CanAutoTurnIn() then
                local activeQuests = C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or nil
                if activeQuests then
                    for _, qi in ipairs(activeQuests) do
                        if qi.isComplete and qi.questID then
                            C_GossipInfo.SelectActiveQuest(qi.questID) return
                        end
                    end
                end
            end
            if CanAutoAccept() then
                local availableQuests = C_GossipInfo.GetAvailableQuests and C_GossipInfo.GetAvailableQuests() or nil
                if availableQuests then
                    for _, qi in ipairs(availableQuests) do
                        if qi.questID then C_GossipInfo.SelectAvailableQuest(qi.questID) return end
                    end
                end
            end
        end
    end)
end
