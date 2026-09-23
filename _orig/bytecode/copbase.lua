local id_lod = Idstring("lod") 
local id_lod1 = Idstring("lod1")
local id_ik_aim = Idstring("ik_aim")

function CopBase.set_visibility_state(self, visibility_state)
    local is_visible = visibility_state and true

    if not is_visible and not self._allow_invisible then
        is_visible = true
        visibility_state = 3
    end

    if self._lod_stage == visibility_state then
        return
    end

    local inventory = self._unit:inventory()
    local weapon = inventory and inventory.get_weapon and inventory:get_weapon()

    if weapon then
        weapon:base():set_flashlight_light_lod_enabled(visibility_state and visibility_state <= 2)
    end

    if self._visibility_state ~= is_visible then
        local unit = self._unit

        if inventory then
            inventory:set_visibility_state(is_visible)
        end

        unit:set_visible(is_visible)

        if self._headwear_unit then
            self._headwear_unit:set_visible(is_visible)
        end

        if is_visible or self._ext_anim.can_freeze and (not self._ext_anim.upper_body_active or self._ext_anim.upper_body_empty) then
            unit:set_animatable_enabled(id_lod, is_visible)
            unit:set_animatable_enabled(id_ik_aim, is_visible)
        end

        self._visibility_state = is_visible
    end

    if is_visible then
        self:set_anim_lod(visibility_state)
        if visibility_state == 1 then
            self._unit:set_animatable_enabled(id_lod1, true)
        elseif self._lod_stage == 1 then
            self._unit:set_animatable_enabled(id_lod1, false)
        end
    end

    self._lod_stage = visibility_state

    self:chk_freeze_anims()
end

function CopBase.chk_freeze_anims(self)
    if (not self._lod_stage or self._lod_stage > 1) and self._ext_anim.can_freeze and (not self._ext_anim.upper_body_active or self._ext_anim.upper_body_empty) then
        if not self._anims_frozen then
            self._anims_frozen = true

            self._unit:set_animations_enabled(false)
            self._ext_movement:on_anim_freeze(true)
        end
    elseif self._anims_frozen then
        self._anims_frozen = nil

        self._unit:set_animations_enabled(true)
        self._ext_movement:on_anim_freeze(false)
    end
end