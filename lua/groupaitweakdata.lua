if Global.level_data and Global.level_data.level_id and Global.level_data.level_id:find("skm_") or not RDAI.settings.spawngroups then
	return
end

Hooks:PostHook(GroupAITweakData, "_init_unit_categories", "RDAI_init_unit_categories", function(self, difficulty_index)
	local access_type_walk_only = {
		walk = true
	}

	self.unit_categories.CS_cop_C45_R870 = {
		unit_types = {
			america = {
				Idstring("units/payday2/characters/ene_cop_1/ene_cop_1"),
				Idstring("units/payday2/characters/ene_cop_2/ene_cop_2"),
				Idstring("units/payday2/characters/ene_cop_4/ene_cop_4")
			},
			russia = {
				Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_ak47_ass/ene_akan_cs_cop_ak47_ass"),
				Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_asval_smg/ene_akan_cs_cop_asval_smg"),
				Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_r870/ene_akan_cs_cop_r870")
			},
			zombie = {
				Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_1/ene_cop_hvh_1"),
				Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_2/ene_cop_hvh_2"),
				Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_4/ene_cop_hvh_4")
			},
			federales = {
				Idstring("units/pd2_dlc_bex/characters/ene_policia_01/ene_policia_01"),
				Idstring("units/pd2_dlc_bex/characters/ene_policia_02/ene_policia_02")
			}
		},
		access = access_type_walk_only
	}
	self.unit_categories.CS_cop_C45_R870.unit_types.murkywater = self.unit_categories.CS_cop_C45_R870.unit_types.america
	self.unit_categories.CS_cop_stealth_MP5 = {
		unit_types = {
			america = {
				Idstring("units/payday2/characters/ene_cop_3/ene_cop_3")
			},
			russia = {
				Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg")
			},
			zombie = {
				Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_3/ene_cop_hvh_3")
			}
		},
		access = access_type_walk_only
	}
	self.unit_categories.CS_cop_stealth_MP5.unit_types.murkywater = self.unit_categories.CS_cop_stealth_MP5.unit_types.america
	self.unit_categories.CS_cop_stealth_MP5.unit_types.federales = self.unit_categories.CS_cop_stealth_MP5.unit_types.america
	self.unit_categories.CS_cop_MP5_R870 = {
		unit_types = {
			america = {
				Idstring("units/payday2/characters/ene_cop_3/ene_cop_3"),
				Idstring("units/payday2/characters/ene_cop_4/ene_cop_4")
			},
			russia = {
				Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_akmsu_smg/ene_akan_cs_cop_akmsu_smg"),
				Idstring("units/pd2_dlc_mad/characters/ene_akan_cs_cop_r870/ene_akan_cs_cop_r870")
			},
			zombie = {
				Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_3/ene_cop_hvh_3"),
				Idstring("units/pd2_dlc_hvh/characters/ene_cop_hvh_4/ene_cop_hvh_4")
			}
		},
		access = access_type_walk_only
	}
	self.unit_categories.CS_cop_MP5_R870.unit_types.murkywater = self.unit_categories.CS_cop_MP5_R870.unit_types.america
	self.unit_categories.CS_cop_MP5_R870.unit_types.federales = self.unit_categories.CS_cop_MP5_R870.unit_types.america
	self.unit_categories.FBI_suit_C45_M4.unit_types.murkywater = self.unit_categories.FBI_suit_C45_M4.unit_types.america
	self.unit_categories.FBI_suit_C45_M4.unit_types.federales = self.unit_categories.FBI_suit_C45_M4.unit_types.america
	self.unit_categories.FBI_suit_M4_MP5.unit_types.murkywater = self.unit_categories.FBI_suit_M4_MP5.unit_types.america
	self.unit_categories.FBI_suit_M4_MP5.unit_types.federales = self.unit_categories.FBI_suit_M4_MP5.unit_types.america

	if difficulty_index < 5 then
		self.unit_categories.FBI_tank.unit_types.federales = {
			Idstring("units/pd2_dlc_bex/characters/ene_swat_dozer_policia_federale_r870/ene_swat_dozer_policia_federale_r870")
		}
	elseif difficulty_index >= 6 and difficulty_index <= 7 then
		self.unit_categories.FBI_swat_M4.unit_types.america = {
			Idstring("units/payday2/characters/ene_city_swat_1/ene_city_swat_1"),
			Idstring("units/payday2/characters/ene_city_swat_3/ene_city_swat_3")
		}
		self.unit_categories.FBI_swat_R870.unit_types.america = {
			Idstring("units/payday2/characters/ene_city_swat_2/ene_city_swat_2")
		}
		self.unit_categories.FBI_heavy_R870.unit_types.murkywater = {
			Idstring("units/pd2_dlc_bph/characters/ene_murkywater_heavy_shotgun/ene_murkywater_heavy_shotgun")
		}
		self.unit_categories.FBI_heavy_G36_w = {
			unit_types = {
				america = {
					Idstring("units/payday2/characters/ene_city_heavy_g36/ene_city_heavy_g36")
				},
				russia = {
					Idstring("units/pd2_dlc_mad/characters/ene_akan_fbi_heavy_g36/ene_akan_fbi_heavy_g36")
				},
				zombie = {
					Idstring("units/pd2_dlc_hvh/characters/ene_fbi_heavy_hvh_1/ene_fbi_heavy_hvh_1")
				},
				murkywater = {
					Idstring("units/pd2_dlc_bph/characters/ene_murkywater_heavy_g36/ene_murkywater_heavy_g36")
				},
				federales = {
					Idstring("units/pd2_dlc_bex/characters/ene_swat_heavy_policia_federale_fbi_g36/ene_swat_heavy_policia_federale_fbi_g36")
				}
			},
			access = access_type_walk_only
		}
	elseif difficulty_index == 8 then
		self.unit_categories.FBI_tank.unit_types.zombie = {
			Idstring("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_1/ene_bulldozer_hvh_1"),
			Idstring("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_2/ene_bulldozer_hvh_2"),
			Idstring("units/pd2_dlc_hvh/characters/ene_bulldozer_hvh_3/ene_bulldozer_hvh_3"),
			Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_medic/ene_bulldozer_medic"),
			Idstring("units/pd2_dlc_drm/characters/ene_bulldozer_minigun/ene_bulldozer_minigun")
		}
	end
end)
Hooks:PostHook(GroupAITweakData, "_init_enemy_spawn_groups", "RDAI_init_enemy_spawn_groups", function(self, difficulty_index)
	self._tactics = {
		CS_cop = {
			"provide_coverfire",
			"provide_support",
			"ranged_fire"
		},
		CS_cop_stealth = {
			"flank",
			"provide_coverfire",
			"provide_support"
		},
		CS_swat_rifle = {
			"smoke_grenade",
			"charge",
			"provide_coverfire",
			"provide_support",
			"ranged_fire",
			"deathguard"
		},
		CS_swat_shotgun = {
			"smoke_grenade",
			"charge",
			"provide_coverfire",
			"provide_support",
			"shield_cover"
		},
		CS_swat_heavy = {
			"smoke_grenade",
			"charge",
			"flash_grenade",
			"provide_coverfire",
			"provide_support"
		},
		CS_shield = {
			"charge",
			"provide_coverfire",
			"provide_support",
			"shield",
			"deathguard"
		},
		CS_swat_rifle_flank = {
			"flank",
			"flash_grenade",
			"smoke_grenade",
			"charge",
			"provide_coverfire",
			"provide_support"
		},
		CS_swat_shotgun_flank = {
			"flank",
			"flash_grenade",
			"smoke_grenade",
			"charge",
			"provide_coverfire",
			"provide_support"
		},
		CS_swat_heavy_flank = {
			"flank",
			"flash_grenade",
			"smoke_grenade",
			"charge",
			"provide_coverfire",
			"provide_support",
			"shield_cover"
		},
		CS_shield_flank = {
			"flank",
			"charge",
			"flash_grenade",
			"provide_coverfire",
			"provide_support",
			"shield"
		},
		CS_tazer = {
			"flank",
			"charge",
			"flash_grenade",
			"shield_cover",
			"murder"
		},
		CS_sniper = {
			"ranged_fire",
			"provide_coverfire",
			"provide_support"
		},
		FBI_suit = {
			"flank",
			"ranged_fire",
			"flash_grenade"
		},
		FBI_suit_stealth = {
			"provide_coverfire",
			"provide_support",
			"flash_grenade",
			"flank"
		},
		FBI_swat_rifle = {
			"smoke_grenade",
			"flash_grenade",
			"provide_coverfire",
			"charge",
			"provide_support",
			"ranged_fire"
		},
		FBI_swat_shotgun = {
			"smoke_grenade",
			"flash_grenade",
			"charge",
			"provide_coverfire",
			"provide_support"
		},
		FBI_heavy = {
			"smoke_grenade",
			"flash_grenade",
			"charge",
			"provide_coverfire",
			"provide_support",
			"shield_cover",
			"deathguard"
		},
		FBI_shield = {
			"smoke_grenade",
			"charge",
			"provide_coverfire",
			"provide_support",
			"shield",
			"deathguard"
		},
		FBI_swat_rifle_flank = {
			"flank",
			"smoke_grenade",
			"flash_grenade",
			"charge",
			"provide_coverfire",
			"provide_support"
		},
		FBI_swat_shotgun_flank = {
			"flank",
			"smoke_grenade",
			"flash_grenade",
			"charge",
			"provide_coverfire",
			"provide_support"
		},
		FBI_heavy_flank = {
			"flank",
			"smoke_grenade",
			"flash_grenade",
			"charge",
			"provide_coverfire",
			"provide_support",
			"shield_cover"
		},
		FBI_shield_flank = {
			"flank",
			"smoke_grenade",
			"flash_grenade",
			"charge",
			"provide_coverfire",
			"provide_support",
			"shield"
		},
		FBI_tank = {
			"charge",
			"deathguard",
			"shield_cover",
			"smoke_grenade"
		},
		spooc = {
			"charge",
			"shield_cover",
			"smoke_grenade",
			"flash_grenade"
		},
		-- Replacing self._tactics wholesale drops vanilla's Phalanx and marshal
		-- presets; the spawn groups below still reference them, so restore them.
		Phalanx_minion = {
			"smoke_grenade",
			"charge",
			"provide_coverfire",
			"provide_support",
			"shield",
			"deathguard"
		},
		Phalanx_vip = {
			"smoke_grenade",
			"charge",
			"provide_coverfire",
			"provide_support",
			"shield",
			"deathguard"
		},
		marshal_marksman = {
			"ranged_fire",
			"flank"
		},
		marshal_shield = {
			"shield",
			"ranged_fire"
		}
	}
	self.enemy_spawn_groups = {}
	self.enemy_spawn_groups.CS_defend_a = {
		amount = {
			3,
			4
		},
		spawn = {
			{
				unit = "CS_cop_MP5_R870",
				freq = 1,
				rank = 1,
				tactics = self._tactics.CS_cop
			}
		}
	}
	self.enemy_spawn_groups.CS_defend_b = {
		amount = {
			3,
			4
		},
		spawn = {
			{
				freq = 1,
				amount_min = 1,
				rank = 1,
				unit = "CS_swat_MP5",
				tactics = self._tactics.CS_cop
			}
		}
	}
	self.enemy_spawn_groups.CS_defend_c = {
		amount = {
			3,
			4
		},
		spawn = {
			{
				freq = 1,
				amount_min = 1,
				rank = 1,
				unit = "CS_heavy_M4",
				tactics = self._tactics.CS_cop
			}
		}
	}
	self.enemy_spawn_groups.CS_cops = {
		amount = {
			3,
			4
		},
		spawn = {
			{
				freq = 1,
				amount_min = 1,
				rank = 1,
				unit = "CS_cop_C45_R870",
				tactics = self._tactics.CS_cop
			}
		}
	}
	self.enemy_spawn_groups.CS_stealth_a = {
		amount = {
			2,
			3
		},
		spawn = {
			{
				freq = 1,
				amount_min = 1,
				rank = 1,
				unit = "CS_cop_stealth_MP5",
				tactics = self._tactics.CS_cop_stealth
			}
		}
	}
	self.enemy_spawn_groups.CS_swats = {
		amount = {
			3,
			4
		},
		spawn = {
			{
				unit = "CS_swat_MP5",
				freq = 1,
				rank = 2,
				tactics = self._tactics.CS_swat_rifle
			},
			{
				rank = 1,
				freq = 0.5,
				amount_max = 2,
				unit = "CS_swat_R870",
				tactics = self._tactics.CS_swat_shotgun
			},
			{
				unit = "CS_swat_MP5",
				freq = 0.33,
				rank = 3,
				tactics = self._tactics.CS_swat_rifle_flank
			}
		}
	}
	self.enemy_spawn_groups.CS_heavys = {
		amount = {
			3,
			4
		},
		spawn = {
			{
				unit = "CS_heavy_M4",
				freq = 1,
				rank = 2,
				tactics = self._tactics.CS_swat_rifle
			},
			{
				unit = "CS_heavy_M4",
				freq = 0.35,
				rank = 3,
				tactics = self._tactics.CS_swat_rifle_flank
			}
		}
	}
	self.enemy_spawn_groups.CS_shields = {
		amount = {
			3,
			4
		},
		spawn = {
			{
				amount_min = 1,
				freq = 1,
				amount_max = 2,
				rank = 3,
				unit = "CS_shield",
				tactics = self._tactics.CS_shield
			},
			{
				rank = 1,
				freq = 0.5,
				amount_max = 1,
				unit = "CS_cop_stealth_MP5",
				tactics = self._tactics.CS_cop_stealth
			},
			{
				rank = 2,
				freq = 0.75,
				amount_max = 1,
				unit = "CS_heavy_M4_w",
				tactics = self._tactics.CS_swat_heavy
			}
		}
	}

	if difficulty_index < 6 then
		self.enemy_spawn_groups.CS_tazers = {
			amount = {
				1,
				3
			},
			spawn = {
				{
					amount_min = 1,
					freq = 1,
					amount_max = 1,
					rank = 2,
					unit = "CS_tazer",
					tactics = self._tactics.CS_tazer
				},
				{
					rank = 1,
					freq = 1,
					amount_max = 2,
					unit = "CS_swat_MP5",
					tactics = self._tactics.CS_cop_stealth
				}
			}
		}
	else
		self.enemy_spawn_groups.CS_tazers = {
			amount = {
				4,
				4
			},
			spawn = {
				{
					freq = 1,
					amount_min = 3,
					rank = 1,
					unit = "CS_tazer",
					tactics = self._tactics.CS_tazer
				},
				{
					amount_min = 2,
					freq = 1,
					amount_max = 3,
					rank = 3,
					unit = "FBI_shield",
					tactics = self._tactics.FBI_shield
				},
				{
					rank = 1,
					freq = 1,
					amount_max = 2,
					unit = "FBI_heavy_G36",
					tactics = self._tactics.FBI_swat_rifle
				}
			}
		}
	end

	self.enemy_spawn_groups.CS_tanks = {
		amount = {
			1,
			2
		},
		spawn = {
			{
				freq = 1,
				amount_min = 1,
				rank = 2,
				unit = "FBI_tank",
				tactics = self._tactics.FBI_tank
			},
			{
				rank = 1,
				freq = 0.5,
				amount_max = 1,
				unit = "CS_tazer",
				tactics = self._tactics.CS_tazer
			}
		}
	}
	self.enemy_spawn_groups.FBI_defend_a = {
		amount = {
			3,
			3
		},
		spawn = {
			{
				freq = 1,
				amount_min = 1,
				rank = 2,
				unit = "FBI_suit_C45_M4",
				tactics = self._tactics.FBI_suit
			},
			{
				unit = "CS_cop_MP5_R870",
				freq = 1,
				rank = 1,
				tactics = self._tactics.FBI_suit
			}
		}
	}
	self.enemy_spawn_groups.FBI_defend_b = {
		amount = {
			3,
			3
		},
		spawn = {
			{
				freq = 1,
				amount_min = 1,
				rank = 2,
				unit = "FBI_suit_M4_MP5",
				tactics = self._tactics.FBI_suit
			},
			{
				unit = "FBI_swat_M4",
				freq = 1,
				rank = 1,
				tactics = self._tactics.FBI_suit
			}
		}
	}
	self.enemy_spawn_groups.FBI_defend_c = {
		amount = {
			3,
			3
		},
		spawn = {
			{
				unit = "FBI_swat_M4",
				freq = 1,
				rank = 1,
				tactics = self._tactics.FBI_suit
			}
		}
	}
	self.enemy_spawn_groups.FBI_defend_d = {
		amount = {
			2,
			3
		},
		spawn = {
			{
				unit = "FBI_heavy_G36",
				freq = 1,
				rank = 1,
				tactics = self._tactics.FBI_suit
			}
		}
	}

	if difficulty_index < 6 then
		self.enemy_spawn_groups.FBI_stealth_a = {
			amount = {
				2,
				3
			},
			spawn = {
				{
					freq = 1,
					amount_min = 1,
					rank = 1,
					unit = "FBI_suit_stealth_MP5",
					tactics = self._tactics.FBI_suit_stealth
				},
				{
					rank = 2,
					freq = 1,
					amount_max = 2,
					unit = "CS_tazer",
					tactics = self._tactics.CS_tazer
				}
			}
		}
	else
		self.enemy_spawn_groups.FBI_stealth_a = {
			amount = {
				3,
				4
			},
			spawn = {
				{
					freq = 1,
					amount_min = 1,
					rank = 2,
					unit = "FBI_suit_stealth_MP5",
					tactics = self._tactics.FBI_suit_stealth
				},
				{
					rank = 1,
					freq = 1,
					amount_max = 2,
					unit = "CS_tazer",
					tactics = self._tactics.CS_tazer
				}
			}
		}
	end

	if difficulty_index < 6 then
		self.enemy_spawn_groups.FBI_stealth_b = {
			amount = {
				2,
				3
			},
			spawn = {
				{
					freq = 1,
					amount_min = 1,
					rank = 1,
					unit = "FBI_suit_stealth_MP5",
					tactics = self._tactics.FBI_suit_stealth
				},
				{
					unit = "FBI_suit_M4_MP5",
					freq = 0.75,
					rank = 2,
					tactics = self._tactics.FBI_suit
				}
			}
		}
	else
		self.enemy_spawn_groups.FBI_stealth_b = {
			amount = {
				4,
				4
			},
			spawn = {
				{
					freq = 1,
					amount_min = 1,
					rank = 1,
					unit = "FBI_suit_stealth_MP5",
					tactics = self._tactics.FBI_suit_stealth
				},
				{
					unit = "FBI_suit_M4_MP5",
					freq = 0.75,
					rank = 2,
					tactics = self._tactics.FBI_suit_stealth
				}
			}
		}
	end

	if difficulty_index < 6 then
		self.enemy_spawn_groups.FBI_swats = {
			amount = {
				3,
				4
			},
			spawn = {
				{
					freq = 1,
					amount_min = 1,
					rank = 2,
					unit = "FBI_swat_M4",
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					unit = "FBI_swat_M4",
					freq = 0.75,
					rank = 3,
					tactics = self._tactics.FBI_swat_rifle_flank
				},
				{
					rank = 1,
					freq = 0.5,
					amount_max = 2,
					unit = "FBI_swat_R870",
					tactics = self._tactics.FBI_swat_shotgun
				},
				{
					rank = 1,
					freq = 0.15,
					amount_max = 2,
					unit = "spooc",
					tactics = self._tactics.spooc
				},
				{
					rank = 1,
					freq = 0.15,
					amount_max = 1,
					unit = "medic_M4",
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					rank = 1,
					freq = 0.15,
					amount_max = 1,
					unit = "medic_R870",
					tactics = self._tactics.FBI_swat_shotgun
				}
			}
		}
	else
		self.enemy_spawn_groups.FBI_swats = {
			amount = {
				3,
				4
			},
			spawn = {
				{
					freq = 1,
					amount_min = 1,
					rank = 1,
					unit = "FBI_swat_M4",
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					unit = "FBI_suit_M4_MP5",
					freq = 1,
					rank = 2,
					tactics = self._tactics.FBI_swat_rifle_flank
				},
				{
					freq = 1,
					amount_min = 1,
					rank = 3,
					unit = "FBI_swat_R870",
					tactics = self._tactics.FBI_swat_shotgun
				},
				{
					rank = 1,
					freq = 0.3,
					amount_max = 2,
					unit = "spooc",
					tactics = self._tactics.spooc
				},
				{
					rank = 1,
					freq = 0.25,
					amount_max = 1,
					unit = "medic_M4",
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					rank = 1,
					freq = 0.25,
					amount_max = 1,
					unit = "medic_R870",
					tactics = self._tactics.FBI_swat_shotgun
				}
			}
		}
	end

	if difficulty_index < 6 then
		self.enemy_spawn_groups.FBI_heavys = {
			amount = {
				2,
				3
			},
			spawn = {
				{
					freq = 1,
					amount_min = 1,
					rank = 1,
					unit = "FBI_heavy_G36",
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					unit = "FBI_heavy_G36",
					freq = 0.75,
					rank = 2,
					tactics = self._tactics.FBI_swat_rifle_flank
				},
				{
					rank = 3,
					freq = 0.25,
					amount_max = 1,
					unit = "CS_tazer",
					tactics = self._tactics.CS_tazer
				},
				{
					unit = "medic_M4",
					freq = 0.25,
					rank = 1,
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					unit = "medic_R870",
					freq = 0.25,
					rank = 1,
					tactics = self._tactics.FBI_swat_shotgun
				}
			}
		}
	else
		self.enemy_spawn_groups.FBI_heavys = {
			amount = {
				3,
				4
			},
			spawn = {
				{
					freq = 1,
					amount_min = 3,
					rank = 1,
					unit = "FBI_heavy_G36_w",
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					unit = "FBI_swat_M4",
					freq = 1,
					rank = 2,
					tactics = self._tactics.FBI_heavy_flank
				},
				{
					unit = "medic_M4",
					freq = 0.25,
					rank = 1,
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					unit = "medic_R870",
					freq = 0.25,
					rank = 1,
					tactics = self._tactics.FBI_swat_shotgun
				}
			}
		}
	end

	if difficulty_index < 6 then
		self.enemy_spawn_groups.FBI_shields = {
			amount = {
				3,
				4
			},
			spawn = {
				{
					amount_min = 1,
					freq = 1,
					amount_max = 2,
					rank = 3,
					unit = "FBI_shield",
					tactics = self._tactics.FBI_shield_flank
				},
				{
					rank = 2,
					freq = 0.75,
					amount_max = 1,
					unit = "CS_tazer",
					tactics = self._tactics.CS_tazer
				},
				{
					rank = 1,
					freq = 0.5,
					amount_max = 1,
					unit = "FBI_heavy_G36",
					tactics = self._tactics.FBI_swat_rifle_flank
				}
			}
		}
	else
		self.enemy_spawn_groups.FBI_shields = {
			amount = {
				3,
				4
			},
			spawn = {
				{
					amount_min = 3,
					freq = 1,
					amount_max = 4,
					rank = 3,
					unit = "FBI_shield",
					tactics = self._tactics.FBI_shield
				},
				{
					freq = 1,
					amount_min = 1,
					rank = 1,
					unit = "FBI_suit_stealth_MP5",
					tactics = self._tactics.FBI_suit_stealth
				},
				{
					rank = 1,
					freq = 0.15,
					amount_max = 2,
					unit = "spooc",
					tactics = self._tactics.spooc
				},
				{
					freq = 0.75,
					amount_min = 2,
					rank = 2,
					unit = "CS_tazer",
					tactics = self._tactics.CS_swat_heavy
				}
			}
		}
	end

	if difficulty_index < 6 then
		self.enemy_spawn_groups.FBI_tanks = {
			amount = {
				3,
				4
			},
			spawn = {
				{
					amount_min = 1,
					freq = 1,
					amount_max = 2,
					rank = 1,
					unit = "FBI_tank",
					tactics = self._tactics.FBI_tank
				},
				{
					amount_min = 1,
					freq = 0.2,
					amount_max = 2,
					rank = 3,
					unit = "FBI_shield",
					tactics = self._tactics.FBI_shield_flank
				},
				{
					freq = 0.15,
					amount_min = 1,
					rank = 1,
					unit = "FBI_heavy_G36_w",
					tactics = self._tactics.FBI_heavy_flank
				},
				{
					unit = "medic_M4",
					freq = 0.075,
					rank = 1,
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					unit = "medic_R870",
					freq = 0.075,
					rank = 1,
					tactics = self._tactics.FBI_swat_shotgun
				}
			}
		}
	else
		self.enemy_spawn_groups.FBI_tanks = {
			amount = {
				4,
				4
			},
			spawn = {
				{
					amount_min = 2,
					freq = 1,
					amount_max = 2,
					rank = 3,
					unit = "FBI_tank",
					tactics = self._tactics.FBI_tank
				},
				{
					unit = "FBI_shield",
					freq = 1,
					rank = 3,
					tactics = self._tactics.FBI_shield
				},
				{
					freq = 0.75,
					amount_min = 1,
					rank = 2,
					unit = "CS_tazer",
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					unit = "medic_M4",
					freq = 0.25,
					rank = 1,
					tactics = self._tactics.FBI_swat_rifle
				},
				{
					unit = "medic_R870",
					freq = 0.25,
					rank = 1,
					tactics = self._tactics.FBI_swat_shotgun
				}
			}
		}
	end

	self.enemy_spawn_groups.single_spooc = {
		amount = {
			1,
			1
		},
		spawn = {
			{
				freq = 1,
				amount_min = 1,
				rank = 1,
				unit = "spooc",
				tactics = self._tactics.spooc
			}
		}
	}
	self.enemy_spawn_groups.FBI_spoocs = self.enemy_spawn_groups.single_spooc
	-- self.enemy_spawn_groups = {} above wipes vanilla's table, and the task data
	-- below still assigns assault/recon weights to Phalanx. _spawn_phalanx builds
	-- { Phalanx = {1,1,1} } and _choose_best_groups requires the group to exist in
	-- enemy_spawn_groups, so without this Captain Winters can never spawn.
	-- self.phalanx.minions.amount is safe to read here: _init_task_data runs before
	-- _init_enemy_spawn_groups in GroupAITweakData:init.
	self.enemy_spawn_groups.Phalanx = {
		amount = {
			self.phalanx.minions.amount + 1,
			self.phalanx.minions.amount + 1
		},
		spawn = {
			{
				amount_max = 1,
				amount_min = 1,
				freq = 1,
				rank = 2,
				unit = "Phalanx_vip",
				tactics = self._tactics.Phalanx_vip
			},
			{
				amount_min = 1,
				freq = 1,
				rank = 1,
				unit = "Phalanx_minion",
				tactics = self._tactics.Phalanx_minion
			}
		}
	}

	self.enemy_spawn_groups.marshal_squad = {
		max_nr_simultaneous_groups = 1,
		initial_spawn_delay = 90,
		spawn_cooldown = 60,
		amount = {
			2,
			2
		},
		spawn = {
			{
				respawn_cooldown = 30,
				amount_min = 2,
				freq = 1,
				rank = 1,
				unit = "marshal_marksman",
				tactics = self._tactics.marshal_marksman
			}
		},
		spawn_point_chk_ref = table.list_to_set({
			"tac_swat_rifle_flank",
			"tac_swat_rifle"
		})
	}
end)
Hooks:PostHook(GroupAITweakData, "_init_task_data", "RDAI_init_task_data", function(self, difficulty_index)
	if difficulty_index >= 6 then
		self.smoke_and_flash_grenade_timeout = {
			8,
			12
		}
		self.besiege.recurring_group_SO = {
			recurring_cloaker_spawn = {
				retire_delay = 30,
				interval = {
					20,
					40
				}
			},
			recurring_spawn_1 = {
				interval = {
					30,
					60
				}
			}
		}
	else
		self.smoke_and_flash_grenade_timeout = {
			10,
			15
		}
	end

	if difficulty_index <= 2 then
		self.besiege.assault.delay = {
			80,
			70,
			30
		}
	elseif difficulty_index == 5 then
		self.besiege.assault.delay = {
			30,
			20,
			15
		}
	end

	self.besiege.assault.force = {
		10,
		12,
		14
	}

	if difficulty_index <= 2 then
		self.besiege.assault.groups = {
			CS_swats = {
				0,
				1,
				0.7
			},
			CS_heavys = {
				0,
				0,
				0.5
			},
			CS_shields = {
				0,
				0,
				0.1
			}
		}
	elseif difficulty_index == 3 then
		self.besiege.assault.groups = {
			CS_swats = {
				0,
				1,
				0
			},
			CS_heavys = {
				0,
				0.2,
				0.7
			},
			CS_shields = {
				0,
				0.02,
				0.2
			},
			CS_tazers = {
				0,
				0.05,
				0.15
			},
			CS_tanks = {
				0,
				0.01,
				0.05
			}
		}
	elseif difficulty_index == 4 then
		self.besiege.assault.groups = {
			FBI_swats = {
				0.1,
				1,
				1
			},
			FBI_heavys = {
				0.05,
				0.25,
				0.5
			},
			FBI_shields = {
				0.1,
				0.2,
				0.2
			},
			FBI_tanks = {
				0,
				0.1,
				0.15
			},
			FBI_spoocs = {
				0,
				0.1,
				0.2
			},
			CS_tazers = {
				0.05,
				0.15,
				0.2
			}
		}
	elseif difficulty_index == 5 then
		self.besiege.assault.groups = {
			FBI_swats = {
				0.2,
				1,
				1
			},
			FBI_heavys = {
				0.1,
				0.5,
				0.75
			},
			FBI_shields = {
				0.1,
				0.3,
				0.4
			},
			FBI_tanks = {
				0,
				0.25,
				0.3
			},
			CS_tazers = {
				0.1,
				0.25,
				0.25
			}
		}
	else
		local diff_scale = (difficulty_index - 5) / 3

		self.besiege.assault.groups = {
			FBI_swats = {
				0.2,
				0.8,
				0.8
			},
			FBI_heavys = {
				0.15 * diff_scale,
				0.45 * diff_scale,
				0.6 * diff_scale
			},
			FBI_shields = {
				0.1,
				0.5,
				0.4
			},
			FBI_tanks = {
				0.1,
				0.5,
				0.5
			},
			CS_tazers = {
				0.1,
				0.5,
				0.45
			},
			FBI_spoocs = {
				0,
				0.45,
				0.45
			}
		}
	end

	self.besiege.assault.groups.single_spooc = {
		0,
		0,
		0
	}
	self.besiege.assault.groups.Phalanx = {
		0,
		0,
		0
	}
	self.besiege.assault.groups.marshal_squad = {
		0,
		0,
		0
	}
	self.besiege.reenforce.interval = {
		30,
		20,
		10
	}

	if difficulty_index <= 2 then
		self.besiege.reenforce.groups = {
			CS_defend_a = {
				1,
				0.2,
				0
			},
			CS_defend_b = {
				0,
				1,
				1
			}
		}
	elseif difficulty_index == 3 then
		self.besiege.reenforce.groups = {
			CS_defend_a = {
				1,
				0,
				0
			},
			CS_defend_b = {
				2,
				1,
				0
			},
			CS_defend_c = {
				0,
				0,
				1
			}
		}
	elseif difficulty_index == 4 then
		self.besiege.reenforce.groups = {
			CS_defend_a = {
				1,
				0,
				0
			},
			CS_defend_b = {
				2,
				1,
				0
			},
			CS_defend_c = {
				0,
				0,
				1
			},
			FBI_defend_a = {
				0,
				1,
				0
			},
			FBI_defend_b = {
				0,
				0,
				1
			}
		}
	elseif difficulty_index == 5 then
		self.besiege.reenforce.groups = {
			CS_defend_a = {
				0.1,
				0,
				0
			},
			FBI_defend_b = {
				1,
				1,
				0
			},
			FBI_defend_c = {
				0,
				1,
				0
			},
			FBI_defend_d = {
				0,
				0,
				1
			}
		}
	else
		self.besiege.reenforce.groups = {
			CS_defend_a = {
				0.1,
				0,
				0
			},
			FBI_defend_b = {
				1,
				1,
				0
			},
			FBI_defend_c = {
				0,
				1,
				0
			},
			FBI_defend_d = {
				0,
				0,
				1
			}
		}
	end

	if difficulty_index <= 2 then
		self.besiege.recon.groups = {
			CS_stealth_a = {
				1,
				1,
				0
			},
			CS_swats = {
				0,
				1,
				1
			}
		}
	elseif difficulty_index == 3 then
		self.besiege.recon.groups = {
			CS_stealth_a = {
				1,
				0,
				0
			},
			CS_swats = {
				0,
				1,
				1
			},
			CS_tazers = {
				0,
				0.1,
				0.15
			},
			FBI_stealth_b = {
				0,
				0,
				0.1
			}
		}
	elseif difficulty_index == 4 then
		self.besiege.recon.groups = {
			FBI_stealth_a = {
				1,
				0.5,
				0
			},
			FBI_stealth_b = {
				0,
				0,
				1
			}
		}
	elseif difficulty_index == 5 then
		self.besiege.recon.groups = {
			FBI_stealth_a = {
				0.5,
				1,
				1
			},
			FBI_stealth_b = {
				0.25,
				0.5,
				1
			}
		}
	else
		self.besiege.recon.groups = {
			FBI_stealth_a = {
				0.5,
				1,
				1
			},
			FBI_stealth_b = {
				0.25,
				0.5,
				1
			}
		}
	end

	self.besiege.recon.groups.single_spooc = {
		0,
		0,
		0
	}
	self.besiege.recon.groups.Phalanx = {
		0,
		0,
		0
	}
	self.besiege.recon.groups.marshal_squad = {
		0,
		0,
		0
	}
end)
