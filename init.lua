local S = minetest.get_translator("mcl_end_crystal")

local explosion_range = 7

local directions = {
	{x = 1}, {x = -1}, {z = 1}, {z = -1}
}

local dimensions = {"x", "y", "z"}

for _, dir in pairs(directions) do
	for _, dim in pairs(dimensions) do
		dir[dim] = dir[dim] or 0
	end
end

local function crystal_explode(self, puncher)
	if self.exploded then return end
	self.exploded = true
	local radius = puncher and explosion_range or 1
	mcl_explosions.explode(self.object:get_pos(), radius, {drop_chance = 1}, puncher)
	minetest.after(0, self.object.remove, self.object)
end

local function set_crystal_animation(self)
	self.object:set_animation({x = 0, y = 60}, 30)
end

local function spawn_crystal(pos)
	local crystal = minetest.add_entity(pos, "mcl_end_crystal:end_crystal")
	if not vector.equals(pos, vector.floor(pos)) then return end
	if mcl_worlds.pos_to_dimension(pos) ~= "end" then return end
	local portal_center
	for _, dir in pairs(directions) do
		local node = minetest.get_node(vector.add(pos, vector.add(dir, {x = 0, y = -1, z = 0})))
		if node.name == "mcl_portals:portal_end" then
			portal_center = vector.add(pos, vector.multiply(dir, 3))
			break
		end
	end
	if not portal_center then return end
	local crystals = {}
	for i, dir in pairs(directions) do
		local crystal_pos = vector.add(portal_center, vector.multiply(dir, 3))
		print(minetest.pos_to_string(crystal_pos))
		local objects = minetest.get_objects_inside_radius(crystal_pos, 0)
		for _, obj in pairs(objects) do
			local luaentity = obj:get_luaentity()
			if luaentity and luaentity.name == "mcl_end_crystal:end_crystal" then
				crystals[i] = luaentity
				break
			end
		end
		if not crystals[i] then return end
	end
	for _, crystal in pairs(crystals) do
		crystal_explode(crystal)
	end
	minetest.add_entity(vector.add(portal_center, {x = 0, y = 10, z = 0}), "mobs_mc:enderdragon")
end

minetest.register_entity("mcl_end_crystal:end_crystal", {
	initial_properties = {
		physical = true,
		visual = "mesh",
		visual_size = {x = 7.5, y = 7.5, z = 7.5},
		collisionbox = {-0.75, -0.5, -0.75, 0.75, 1.25, 0.75},
		mesh = "end_crystal.b3d",
		textures = {"end_crystal_entity.png"},
		collide_with_objects = true,
	},
	exploded = false,
	on_punch = crystal_explode,
	on_activate = set_crystal_animation,
	_cmi_is_mob = true -- Ignitable by arrows
})
 
minetest.register_craftitem("mcl_end_crystal:end_crystal", {
	inventory_image = "end_crystal.png",
	description = S("End Crystal"),
	stack_max = 64,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" and pointed_thing.above.y > pointed_thing.under.y then
			local node = minetest.get_node(pointed_thing.under).name
			if node == "mcl_core:obsidian" or node == "mcl_core:bedrock" then
				itemstack:take_item()
				spawn_crystal(pointed_thing.above)
			end
		end
		return itemstack
	end,
	_tt_help = S("Ignited by a punch or a hit with an arrow").."\n"..S("Explosion radius: @1", tostring(explosion_range)),
	_doc_items_longdesc = S("End Crystals are explosive devices. They can be placed on Obsidian or Bedrock. Ignite them by a punch or a hit with an arrow. End Crystals can also be used the spawn the Ender Dragon by placing one at each side of the End Exit Portal."),
	_doc_items_usagehelp = S("Place the End Crystal on Obsidian or Bedrock, then punch it or hit it with an arrow to cause an huge and probably deadly explosion. To Spawn the Ender Dragon, place one at each side of the End Exit Portal."),

})

minetest.register_craft({
	output = "mcl_end_crystal:end_crystal",
	recipe = {
		{"mcl_core:glass", "mcl_core:glass", "mcl_core:glass"},
		{"mcl_core:glass", "mcl_end:ender_eye", "mcl_core:glass"},
		{"mcl_core:glass", "mcl_mobitems:ghast_tear", "mcl_core:glass"},
	}
})
