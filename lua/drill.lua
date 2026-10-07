local sabotage_access

Hooks:PostHook(Drill, "_register_sabotage_SO", "RDAI_drill_sabotage_SO", function(self)
    if not RDAI.settings.aggressive_objectives then
        return
    end

    local so = self._sabotage_SO_id and managers.groupai:state()._special_objectives[self._sabotage_SO_id]

    if not so then
        return
    end

    if not sabotage_access then
        sabotage_access = managers.navigation:convert_access_filter_to_number({
            "gangster",
            "security",
            "security_patrol",
            "cop",
            "fbi",
            "swat",
            "murky",
            "spooc",
            "tank",
            "taser"
        })
    end

    local data = so.data
    local objective = data.objective

    data.access = sabotage_access

    data.search_dis_sq = 10000 * 10000
    data.verification_clbk = function(unit)
        local brain = unit:brain()
        local logic_data = brain._logic_data
        local t = TimerManager:game():time()

        return not unit:movement():cool()
            and not (logic_data.path_fail_t and t < logic_data.path_fail_t + 6)
            and not unit:base().is_phalanx
    end

    objective.forced = true
    objective.interrupt_dis = nil
    objective.interrupt_health = nil
end)
