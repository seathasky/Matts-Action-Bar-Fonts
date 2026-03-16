local addonName, MABF = ...

-- Global click-through lock for all reminder frames.
function MABF:ApplyRemindersClickthroughLock()
    local db = MattActionBarFontDB
    local locked = db and db.remindersClickthroughLock and true or false
    local mouseEnabled = not locked

    local reminderFrames = {
        self._consumableReminderFrame,
        self._petPassiveReminderFrame,
        self._missingBuffReminderFrame,
        self._classStuffReminderFrame,
    }

    for _, frame in ipairs(reminderFrames) do
        if frame and frame.EnableMouse then
            frame:EnableMouse(mouseEnabled)
        end
    end
end
