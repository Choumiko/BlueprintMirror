BpMirror = {
  findBlueprintsInHotbar = function(player)
    local blueprints = {}
    if player ~= nil then
      local hotbar = player.getinventory(1)
      if hotbar ~= nil then
        local i = 1
        while (i < 30) do
          local itemStack
          if pcall(function () itemStack = hotbar[i] end) then
            if itemStack ~= nil and itemStack.type == "blueprint" then
              table.insert(blueprints, itemStack)
            end
            i = i + 1
          else
            i = 100
          end
        end
      end
    end
    return blueprints
  end,

  findSetupBlueprintInHotbar = function(player)
    local blueprints = BpMirror.findBlueprintsInHotbar(player)
    if blueprints ~= nil then
      for i, blueprint in ipairs(blueprints) do
        if blueprint.isblueprintsetup() then
          return blueprint
        end
      end
    end
  end,
}

--function debugDump(var, force)
--  if false or force then
--    for i,player in ipairs(game.players) do
--      local msg
--      if type(var) == "string" then
--        msg = var
--      else
--        msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
--      end
--      player.print(msg)
--    end
--  end
--end
--function saveVar(var, name)
--  local var = var or glob
--  local n = name or ""
--  game.makefile("bp/bp"..n..".lua", serpent.block(var, {name="glob"}))
--  --game.makefile("farl/loco"..n..".lua", serpent.block(findAllEntitiesByType("locomotive")))
--end

function mirror(bp, axis)
  local entities = bp.getblueprintentities()
  local dirs = {x ={0,4},y={2,6}}
  for _,ent in pairs(entities) do
    ent.position[axis] = -1 * ent.position[axis]
    if ent.direction and ent.direction ~= dirs[axis][1] and ent.direction ~= dirs[axis][2] then
      ent.direction = (ent.direction+4)%8
    end
  end
  return entities
end

function getPlayerID(name)
  if not name and #game.players > 1 then
    for id, player in pairs(game.players) do
      player.print("Use /c remote.call(\"bpmirror\", \"mirrorV\", \""..player.name.."\")")
    end
    return false
  end
  local id = 1
  if name then
    for pid, player in pairs(game.players) do
      if name == player.name then
        id = pid
        break
      end
    end
  end
  return id
end

remote.addinterface("bpmirror",
  {
    mirrorV = function(name)
      local id = getPlayerID(name)
      if id then
        local bp = BpMirror.findSetupBlueprintInHotbar(game.players[id])
        if bp then
          local mir = mirror(bp, "y")
          bp.setblueprintentities(mir)
        end
      end
    end,
    mirrorH = function(name)
      local id = getPlayerID(name)
      if id then
        local bp = BpMirror.findSetupBlueprintInHotbar(game.players[id])
        if bp then
          local mir = mirror(bp, "x")
          bp.setblueprintentities(mir)
        end
      end
    end
  })
