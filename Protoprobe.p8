pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--globals
framerate = 60
bullet_color = {}
bullet_color["a"] = 12
bullet_color["b"] = 9
bullet_color["c"] = 11
bullet_color["o"] = 8
bullet_color["w"] = 8
bullet_color.complement = {}
bullet_color.complement["a"] = 13
bullet_color.complement["b"] = 4
bullet_color.complement["c"] = 3
bullet_color.complement["o"] = 2
bullet_color.complement["w"] = 8
--[[
btn (i (p))
  get button i state for player p (default 0)
  i: 0..5: left right up down button_o button_x
  p: player index 0..7

  if no parameters supplied, returns a bitfield of all 12 button states for player 0 & 1
    // p0: bits 0..5  p1: bits 8..13

  default keyboard mappings to player buttons:
    player 0: cursors, z,x / c,v / n,m
    player 1: esdf, lshift,a / tab,q,e


colours indexes:
--color
  	 0  black   1  dark_blue   2  dark_purple   3  dark_green
  	 4  brown   5  dark_gray   6  light_gray    7  white
  	 8  red     9  orange     10  yellow       11  green
  	12  blue   13  indigo     14  pink         15  peach
]]--
--helpers
function empty()
end
function ceil(_x)
  if _x % 1 == 0 then
    return _x
  end
  return flr(_x+1)
end
function sign(_x)
  return _x > 0 and 1 or _x < 0 and -1 or 0
end
function round(_x)
  if _x % 1 == 0 then
    return _x
  elseif _x % 1 >= .5 then
    return sign(_x) == 1 and ceil(_x) or flr(_x)
  else
    return sign(_x) == 1 and flr(_x) or ceil(_x)
  end
end
function bool_to_str(_bool)
  return _bool and "true" or "false"
end
function str_to_num(_str)
  return _str + 0
end
function stringify_table(_table,_tab)
  local function num_to_tab(_num)
    local ret = ""
    for i=1,_num do
      ret = ret .. "    "
    end
    return ret
  end
  _table = _table or {}
  _tab = _tab or 0
  local ret = "\n" .. num_to_tab(_tab) .. "{\n"
  for k,v in pairs(_table) do
    if type(v) == "function" then
      ret = ret .. num_to_tab(_tab) .. k .. "=" .. k .. "()" .. '\n'
    elseif type(v) == "table" then
      ret = ret .. num_to_tab(_tab) .. k .. "=" .. stringify_table(v,_tab+1) .. '\n'
    elseif type(v) == "boolean" then
      ret = ret .. num_to_tab(_tab) .. k .. "=" .. bool_to_str(v) .. '\n'
    else
      ret = ret .. num_to_tab(_tab) .. k .. "=" .. v .. '\n'
    end
  end
  return ret .. num_to_tab(_tab) .. "}\n"
end
function split(_string,_split)
  --on empty strings return empty object
  if _string == "" or not _string then
    return {}
  end
  local ret = {}
  local cur = ""
  for i=1,#_string do
    local char = sub(_string,i,i)
    if char == _split then
      add(ret,cur)
      cur = ""
    else
      cur = cur .. char
    end
  end
  add(ret,cur)
  return ret
end
function cut(_string,_cut)
  local ret = ""
  local split = split(_string,_cut)
  for i=1,#split do
    ret = ret .. split[i]
  end
  return ret
end
function print_center(str,x,y,col)
  print(str,x+((4-#str*4)/2),y,col)
end
function exists(obj,search)
  for v in all(obj) do
    if v == search then
      return true
    end
  end
  return false
end
function in_range(_x,_a,_b)
  return _x >= min(_a,_b) and _x <= max(_b,_a)
end
function clamp(_x,_a,_b)
  return _x <= _a and _a or _x >= _b and _b or _x
end
function norm(_x,_min,_max)
  return (_x-_min)/(_max-_min)
end
function center(_start,_width)
  return _start-(_width/2)
end
function cycle(_x,_min,_max)
  if _x > _max then
    return _min
  else
    return _x
  end
end
--linear interporlation
function lerp(_min,_max,_t)
  return (_max-_min)*(_t <= 1 and _t or 1)+_min
end
--intersections
function interval_intersect(_x1,_x2,_y1,_y2)
  return max(_x1,_y1) <= min(_x2,_y2)
end
function rect_intersect(_x1,_y1,_width1,_height1,_x2,_y2,_width2,_height2)
  return interval_intersect(_x1,_x1+_width1,_x2,_x2+_width2) and
  interval_intersect(_y1,_y1+_height1,_y2,_y2+_height2)
end
--concat
function concat(_a,_b)
  for elem in all(_b) do
    add(_a,elem)
  end
  return _a
end
function set_to(_tablea,_tableb)
  --test
  for k,v in pairs(_tablea) do
    if type(_tableb[k]) != "table" then
      _tablea[k] = _tableb[k]
    else
      set_to(_tablea[k],_tableb[k])
    end
  end
end
--types
--rect
function new_rect(_x,_y,_width,_height)
  return {x=_x,y=_y,width=_width,height=_height}
end
--2d vector
vector = {}
vector.metatable = {}
function new_vector(_x,_y)
  local ret = {x=_x or 0,y=_y or 0}
  setmetatable(ret,vector.metatable)
  return ret
end
vector.metatable.__index = function(_table,_key)
  return vector.metatable[_key]
end
vector.metatable.__add = function(_a,_b)
  return new_vector(_a.x+_b.x,_a.y+_b.y)
end
vector.metatable.__sub = function(_a,_b)
  return new_vector(_a.x-_b.x,_a.y-_b.y)
end
vector.metatable.copy = function(_self)
  return new_vector(_self.x,_self.y)
end
vector.metatable.set = function(_self,_x,_y)
  _self.x,_self.y = _x or 0, _y or 0
end
vector.metatable.setto = function(_self,_other)
  _self:set(_other.x,_other.y)
end
vector.metatable.towhole = function(_self)
  _self:set(round(_self.x),round(_self.y))
end
vector.metatable.ceil = function(_self)
  _self:set(ceil(_self.x),ceil(_self.y))
end
vector.metatable.lerp = function(_self,_start,_end,_t)
  --linear interporlate between two points by some fraction _t, 0==_start,.5==vector between _start,_end,1==_end
  _self:set(lerp(_start.x,_end.x,_t),lerp(_start.y,_end.y,_t))
end
vector.metatable.movetowards = function(_self,_to,_speed)
  --moves a vector _self in the direction towards _to, _speed pixels
  _speed = _speed or 1
  if vector.approxequal(_self,_to,_speed) then
    _self:setto(_to)
  else
    _self:setto(_self + vector.scalarmult(vector.unit_towards(_self,_to),_speed))
  end
end
vector.animation = {}
vector.animation.movetoinframes = function(_self,_end,_framestoreachtarget)
  --linear interporlate between two points givin some count of frames
  local start,tick = new_vector(_self.x,_self.y),0

  local function update (_offset)
    _end += _offset or zero
    while tick/_framestoreachtarget < 1 do
      tick += 1
      _self:lerp(start,_end,tick/_framestoreachtarget)
      _end += yield() or zero
    end
  end

  return cocreate(update)
end
vector.animation.circularmotion = function(_self,_center,_speed)
  --[[
  circularmotion takes a position a center and a speed,
  given the position and center, find a vector dif from center to start_vec,
  use the magnitude of dif to find the circle radius, use the angle between the components of dif to find the start location on the circle,
  set the step to the appropriate starting location
  ]]--
  local dif = _center - _self
  local radius,step = vector.magnitude(dif), atan2(dif.x,dif.y)*framerate/_speed

  local function update(_end)
    while not _end do
      step += 1
      _self:set(-cos((step/framerate)*_speed)*radius + _center.x,-sin((step/framerate)*_speed)*radius + _center.y)
      _end = yield()
    end
  end

  return cocreate(update)
end

vector.scalarmult = function(_vec,_scalar)
  return new_vector(_vec.x*_scalar,_vec.y*_scalar)
end
vector.normalize = function(_vec)
  return new_vector(_vec.x/vector.magnitude(_vec),_vec.y/vector.magnitude(_vec))
end
vector.dot = function(_a,_b)
  return _a.x*_b.x+_a.y*_b.y
end
vector.inv = function(_a)
  return vector.scalarmult(_a,-1)
end
vector.magnitude = function(_vec)
  return sqrt(_vec.x*_vec.x + _vec.y*_vec.y)
end
vector.unit_towards = function(_from,_to)
  return vector.normalize(_to-_from)
end
vector.scale = function(_veca,_vecb)
  return new_vector(_veca.x*_vecb.x,_veca.y*_vecb.y)
end
vector.distance = function(_veca,_vecb)
  return vector.magnitude(_veca-_vecb)
end
vector.approxequal = function (_a,_b,_thresh)
  _thresh = _thresh or 1
  local dif = _a-_b
  return in_range(dif.x,-_thresh,_thresh) and in_range(dif.y,-_thresh,_thresh)
end
up = new_vector(0,-1)
down = new_vector(0,1)
left = new_vector(-1,0)
right = new_vector(1,0)
zero = new_vector(0,0)
--sprite
sprite = {}
sprite.metatable = {}
sprite.metatable.draw = function (_sprite,_position)
  spr(_sprite.n,_position.x+_sprite.x,_position.y+_sprite.y,_sprite.width,_sprite.height,_sprite.flipx,_sprite.flipy)
end
sprite.metatable.__index = function (_table,_key)
  return sprite.metatable[_key]
end
function new_sprite(n,x,y,width,height,flipx,flipy)
  local ret = {n=n or 0,x=x or 0, y = y or 0, width = width or 0, height = height or 0, flipx = flipx or false, flipy = flipy or false}
  setmetatable(ret,sprite.metatable)
  return ret
end

--hitbox/body
function new_hitbox(_x,_y,_width,_height,_name,_immaterial)
  return {
    x=_x or 0,
    y=_y or 0,
    width=_width or 0,
    height=_height or 0,
    name=_name or "",
    immaterial=_immaterial or false,
    collisions={}
  }
end
body = {}
body.metatable = {}
function new_body(_hitboxes,_collision)
  local ret = {hitboxes=_hitboxes or {},collision=_collision or empty}
  setmetatable(ret,body.metatable)
  return ret
end
body.metatable.draw = function(_self,_entity)
  for hitbox in all(_self.hitboxes) do
    if hitbox.width > 0 and hitbox.height > 0 then
      rect(_entity.position.x+hitbox.x,_entity.position.y+hitbox.y,_entity.position.x+hitbox.x+hitbox.width,_entity.position.y+hitbox.y+hitbox.height,11)
    end
  end
end
body.metatable.get_collisions = function(_self)
  local ret = {}
  for hitbox in all(_self.hitboxes) do
    if #hitbox.collision > 0 then
      add(ret,hitbox)
    end
  end
  return ret
end
body.metatable.clear_collisions = function(_self)
  for hitbox in all(_self.hitboxes) do
    hitbox.collisions = {}
  end
end
body.metatable.locate_hitbox = function(_self,_name)
  local ret = {}
  for hitbox in all(_self.hitboxes) do
    if hitbox.name == _name then
      add(ret,hitbox)
    end
  end
  return ret
end
body.metatable.__index = function(_table,_key)
  return body.metatable[_key]
end
--parse animation
function parse_sprite_frames(_comp_sprite_frames)
  --sprite frame format "n,x,y,w,h,flipx,flipy|...|n,x,y,w,h,flipx,flipy" all numbers
  local sprite_frames = {}
  local comp_sprites = split(_comp_sprite_frames,"|")
  for i=1,#comp_sprites do
    local sprite = split(comp_sprites[i],",")
    add(sprite_frames,new_sprite(sprite[1],sprite[2],sprite[3],sprite[4],sprite[5],sprite[6] == "1" and true or false,sprite[7] == "1" and true or false))
  end
  return sprite_frames
end
function parse_hitbox_frames(_comp_hitbox_frames)
  --hitbox frame format "x,y,w,h,name|..|x,y,w,h,name" all numbers
  local hitbox_frames = {}
  local comp_hitboxes = split(_comp_hitbox_frames,"|")
  for i=1,#comp_hitboxes do
    local hitbox = split(comp_hitboxes[i],",")
    add(hitbox_frames,new_hitbox(hitbox[1],hitbox[2],hitbox[3],hitbox[4],hitbox[5]))
  end
  return hitbox_frames
end
function parse_displacement_frames(_comp_displacement_frames)
  --format "x,y|..|x,y"
  local displacement_frames = {}
  local comp_displacements = split(_comp_displacement_frames,"|")
  for i=1,#comp_displacements do
    local displacement = split(comp_displacements[i],",")
    add(displacement_frames,new_vector(displacement[1],displacement[2]))
  end
  return displacement_frames
end
function new_frame(_sprite,_hitbox,_displacement)
  return {sprite=_sprite,hitbox=_hitbox,displacement=_displacement}
end
function parse_compressed_frame(_compressed_string)
  --format: "compressed_sprite_frames/compressed_hitbox_frames/compressed_displacement_frames"
  local compressed_frames = split(_compressed_string,"/")
  return {parse_sprite_frames(compressed_frames[1]),parse_hitbox_frames(compressed_frames[2]),parse_displacement_frames(compressed_frames[3])}
end
function new_clip(_compressed_frames,_sample_rate,_callback,_length)
  --[[
  --clip consists of frames, who are built via parse_compressed_frame
  --and contain compressed_sprite frames, compressed_hitbox frames, and compressed displacement frames
  --a frame then contains the raw sprite,hitbox,and displacement which will be sampled
  --finally a clip may contain a _callback function that way on each sample frame a function can be called
  ]]--
  local parsed_frames = parse_compressed_frame(_compressed_frames)
  local frames,
  sprite_frames,
  hitbox_frames,
  displacement_frames =
  {},
  parsed_frames[1],
  parsed_frames[2],
  parsed_frames[3]

  local length = _length or max(max(#sprite_frames,#hitbox_frames),#displacement_frames)
  for i=1,length do
    add(frames,new_frame(sprite_frames[i],hitbox_frames[i],displacement_frames[i]))
  end
  return {frames=frames,sample_rate=_sample_rate,callback=_callback,length=length}
end
--animation
function new_animation(_clip,_sprite,_hitbox,_position,_callback_arg)
  --todo cleanup parse format, reduce tokens, make defaultable animation stuff
  local frame = _clip.sample_rate --frame must start on sample rate for animation to begin on frame 1
  local sample = 1

  local anim = function (_loop)
    while sample <= _clip.length do
      if sample % 1 == 0 then
        if _clip.frames[sample].sprite and _sprite then
          set_to(_sprite,_clip.frames[sample].sprite)
        end
        if _clip.frames[sample].hitbox and _hitbox then
          set_to(_hitbox,_clip.frames[sample].hitbox)
        end
        if _clip.frames[sample].displacement and _position then
          set_to(_position,new_vector(_position.x+_clip.frames[sample].displacement.x,_position.y+_clip.frames[sample].displacement.y))
        end
        if _clip.callback then
          _clip.callback(sample,_callback_arg)
        end
      end
      frame += 1
      sample = frame/_clip.sample_rate
      if sample >= _clip.length and _loop then
        frame = 0
      end
      yield()
    end
  end
  return cocreate(anim)
end

--entity
function new_entity(_name,_tag,_position,_update,_draw,_body,_model,_z)
  --[[an entity is a data structure meant to be used by the game to create some effect
  --an entity is defined by the following:
  --name is a string to identify the object in memory
  --vector is an object of the new_vector function to provide a spatial vector to the object
  --update is a function to be called each frame
  --draw is a function to be called each render
  --model is a table container for an entity's state
  --z is the z index to be drawn

  --if you want a 'start' function, a function to be called on the first frame of the entity's existense,
  --do a if (entity.frame == 0) check
  --]]
  return {
          name=_name or "noname",
          tag=_tag or {},
          position=_position or new_vector(),
          update=_update or empty,
          draw=_draw or empty,
          body=_body or new_body(),
          model=_model or {},
          z=_z or 0,
          frame=0
        }
end
--scene
function new_scene(_starting,_ending,_update,_draw,_late_update,_model)
--[[
--a scene is a manager for any particular segments of a game and should be used as a tool
--to control game state. each game runs an initial scene, and then from there a scene may
--transition via game.switch_scene(scene) where first the ending function of a scene will be called
--followed then by the new scene's starting() function.
-- game.active_scene is the current running scene
]]--
  return {
        starting=_starting or empty,
        ending=_ending or empty,
        update=_update or empty,
        draw=_draw  or empty,
        late_update=_late_update or empty,
        model=_model or {},
        frame=0
      }
end
--game
function new_game(_starting_scene)
    --sorry this looks bad, token saver.
    local
    active_scene, --_starting_scene
    entities, --[{},{},{}] depending on z index is array index
    entity_pool,
    game_camera, --{x=0,y=0,width=128,height=128}
    settings, --{show_hitboxes=true,entities_active=true}
    frame, --0
    started =  --false
    _starting_scene,
    {},
    {},
    {x=0,y=0,width=128,height=128},
    {show_hitboxes=false,entities_active=true,update_frame = 1},
    0,
    false

    local function entity_collision(_fentity,_sentity)
      for _fhitbox in all(_fentity.body.hitboxes) do
        for _shitbox in all(_sentity.body.hitboxes) do
          if not _fhitbox.immaterial and not _shitbox.immaterial and
          rect_intersect(_fentity.position.x+_fhitbox.x,_fentity.position.y+_fhitbox.y,_fhitbox.width,_fhitbox.height,_sentity.position.x+_shitbox.x,_sentity.position.y+_shitbox.y,_shitbox.width,_shitbox.height)
           then
            _fentity.body.collision(_fentity,_sentity,_fhitbox,_shitbox)
            _sentity.body.collision(_sentity,_fentity,_shitbox,_fhitbox)
            add(_fhitbox.collisions,{entity=_sentity,hitbox=_shitbox})
            add(_shitbox.collisions,{entity=_fentity,hitbox=_fhitbox})
          end
        end
      end
    end

    local function exists_in_camera(_vec,_thresh)
      --test
      _thresh = _thresh or 0
      return _vec.x+_thresh >= game_camera.x and _vec.x <= game_camera.x+game_camera.width+_thresh and
              _vec.y+_thresh >= game_camera.y and _vec.y <= game_camera.y+game_camera.height+_thresh
    end

    local function collision_update(_entities)
      for i=1,#_entities do
        _entities[i].body:clear_collisions()
        for j=i+1,#_entities do
          entity_collision(_entities[i],_entities[j])
        end
      end
    end

    local function rectcast(_rect)
      local ret = {}
      for entity in all(entity_pool) do
        for hitbox in all(entity.body.hitboxes) do
          if rect_intersect(_rect, new_rect(entity.position.x+hitbox.x,entity.position.y+hitbox.y,hitbox.width,hitbox.height)) then
            add(ret,entity)
          end
        end
      end
      return ret
    end

    local function get_entities_on_camera(_thresh)
      local ret = {}
      _thresh = _thresh or 0
      for entity in all(entity_pool) do
        if exists_in_camera(entity.position,_thresh) then
          add(ret,entity)
        end
      end
      return ret
    end
    --entity api
    local function get_entities()
      local ret = {}
      for ent_index in all(entities) do
        concat(ret,ent_index)
      end
      return ret
    end
    local function add_entity(_entity)
      if type(_entity) == "table" and _entity.name != nil then
        if entities[_entity.z] == nil then
          entities[_entity.z] = {}
        end
        add(entities[_entity.z],_entity)
      end
      return _entity
    end
    local function remove_entity(_entity)
      del(entities[_entity.z],_entity)
    end
    local function empty_entities()
      entities = {}
    end
    local function locate_entity_name(_name)
      local ret = {}
      for entity in all(get_entities()) do
        if entity.name == _name then
          add(ret,entity)
        end
      end
      return ret
    end
    local function locate_entity_tag(_tag)
      local ret = {}
      for entity in all(get_entities()) do
        if exists(entity.tags,_tag) then
          add(ret,entity)
        end
      end
      return ret
    end
    --frame api
    local function update()
      entity_pool = get_entities()
      --update scene
      active_scene.update(active_scene)
      active_scene.frame += 1
      if settings.entities_active and frame % settings.update_frame == 0 then
        collision_update(entity_pool)
        --update entities
        for entity in all(entity_pool) do
          entity.update(entity)
          entity.frame += 1
        end
      end
      frame += 1
    end
    local function draw ()
      if frame % settings.update_frame == 0 then
        cls()
        camera(-game_camera.x,-game_camera.y)
        active_scene.draw(active_scene)
        for entity in all(entity_pool) do
          entity.draw(entity)
          if settings.show_hitboxes == true then
            entity.body:draw(entity)
          end
        end
      end
    end
    return {
            get_frame = function()
              return frame
            end,
            start = function()
              if started == false then
                active_scene.starting()
                started = true
              end
            end,
            update=update,
            draw=draw,
            switch_scene=function(scene)
              active_scene.ending()
              active_scene = scene
              active_scene.starting()
            end,
            add_entity=add_entity,
            remove_entity=remove_entity,
            empty_entities=empty_entities,
            rectcast=rectcast,
            locate_entity_name=locate_entity_name,
            locate_entity_tag=locate_entity_tag,
            get_entities=get_entities,
            get_entities_on_camera=get_entities_on_camera,
            exists_in_camera=exists_in_camera,
            camera=game_camera,
            active_scene=active_scene,
            pause = function()
              settings.entities_active = false
            end,
            unpause = function()
              settings.entities_active = true
            end
            }
end

entity_table = {}
--bullet_manager
entity_table.bullet_manager =
function (_rails,_comp_bullet_pattern,_player)
  local bullet_pool,speed,row = {},1,1
  local sprites = {a=64,b=80,c=96,o=112,w=68}
  local rects = {a=new_rect(1,1,6,7),b=new_rect(0,1,6,7),c=new_rect(2,1,6,7),o=new_rect(0,0,8,8),w=new_rect(0,0,8,8)}
  local parsed_bullet_pattern = split(_comp_bullet_pattern,',')
  local running_distance = 0
  local endings = {new_vector(_rails[1].position.x,126),new_vector(_rails[2].position.x,126)}
  local bullet_clip = nil
  local bullet_frames = 0
  local bullet_pattern_fin = false
  local message = ""
  local gib_pool = {}
  local gib_anim = function(_position,_end_position,_color,_comp_color,_capture)
    local frame = 0
    local start = new_vector(_position.x,_position.y)
    local size = 2
    local w,h = 8,8
    local max_frame = 7
    local anim = function ()
      while frame <= max_frame do
        if _capture then
          _position:lerp(start,_end_position,frame/max_frame)
          circfill(_position.x,_position.y,size-lerp(0,size,frame/max_frame),_color)
          circfill(_position.x,_position.y,size/2-lerp(0,size/2,frame/max_frame),7)
          circ(_position.x,_position.y,size-lerp(0,size,frame/max_frame),_comp_color)
        else
          circfill(_position.x+w/2,_position.y+h/2,size+lerp(0,size,frame/max_frame),_color)
          circfill(_position.x+w/2,_position.y+h/2,size/2+lerp(0,size/2,frame/max_frame),7)
          circ(_position.x+w/2,_position.y+h/2,size+lerp(0,size,frame/max_frame),_comp_color)
        end
        frame += 1
        yield()
      end
    end

    return cocreate(anim)
  end

  return new_entity("bullet_manager",
        {},
        new_vector(),
        function (entity)
          --update
          --place bullets
          --parse bullet string to objects
          if bullet_frames % 8 == 0 and parsed_bullet_pattern[row] != nil then
            local split = split(parsed_bullet_pattern[row],"|")
            --bullet row
            for j=1, #split do
              if split[j] != "" then
                local x = 0
                local rect = rects[split[j]]
                if j == 1 then
                  add(bullet_pool,new_hitbox(_rails[1].position.x+rect.x-flr(rect.width/2),0,rect.width-1,rect.height,split[j]))
                elseif j == 2 then
                  add(bullet_pool,new_hitbox(65+rect.x-flr(rect.width/2),0,rect.width-1,rect.height,split[j]))
                elseif j == 3 then
                  add(bullet_pool,new_hitbox(_rails[2].position.x+rect.x-flr(rect.width/2),0,rect.width-1,rect.height,split[j]))
                elseif j == 4 then
                elseif j == 5 then
                  message = split[j]
                end
              end
            end
            row += 1
          end
          --move bullets
          local bullets_to_remove = {}
          for i=1,#bullet_pool do
            bullet_pool[i].y += speed * (bullet_pool[i].y >= _player.position.y+10 and 6 or bullet_pool[i].y <= 4 and bullet_pool[i].y >= 0 and 4 or 1)
            if bullet_pool[i].y >= 128 then
              add(bullets_to_remove,bullet_pool[i])
            end
          end
          for i=1,#bullets_to_remove do
            del(bullet_pool,bullets_to_remove[i])
          end
          bullets_to_remove = nil
          bullet_frames += 1
        end,
        function (entity)
          --draw
          for i=1,#gib_pool do
            if gib_pool[i] and costatus(gib_pool[i]) != "dead" then
              coresume(gib_pool[i])
            else
              del(gib_pool,gib_pool[i])
            end
          end
          for i=1,#bullet_pool do
            if bullet_pool[i].y < 16 or bullet_pool[i].y >= 110 then
              spr(sprites[bullet_pool[i].name]+1,bullet_pool[i].x,bullet_pool[i].y)
            else
              spr(sprites[bullet_pool[i].name],bullet_pool[i].x,bullet_pool[i].y)
            end
          end
          for i=1,#endings do
            spr(63,endings[i].x-3,endings[i].y-3)
            spr(63,endings[i].x-3,-3,1,1,true,true)
          end
        end,
        new_body(bullet_pool,
        function (entity,coll,e_hitbox,coll_hitbox)
          if coll.name == "player" then
            if coll_hitbox.name == "shield" and coll.model.defense_type == e_hitbox.name then
              add(gib_pool,gib_anim(new_vector(e_hitbox.x,e_hitbox.y),coll.model.energy_pools[e_hitbox.name],bullet_color[e_hitbox.name],bullet_color.complement[e_hitbox.name],true))
              del(bullet_pool,e_hitbox)
            elseif coll_hitbox.name == "chassis" and coll.model.defense_type != e_hitbox.name then
              add(gib_pool,gib_anim(new_vector(e_hitbox.x,e_hitbox.y),coll.position,bullet_color[e_hitbox.name],bullet_color.complement[e_hitbox.name],false))
              del(bullet_pool,e_hitbox)
            end
          end
        end),
        {},
        2
        )
  end
entity_table.background =
function()
  local
  ending,straight,turn,connect,
  square,
  triple_straight,triple_turn,triple_connect =
  240, 224, 192, 208,
  193,
  209, 225, 241
  --[[
  relevent spr info
  sprite id
  color type
  flipx
  flipy
  ]]--
  local background_spr_sheet = {
  }

  return new_entity("background", {},
          new_vector(),
          function (entity)

          end,
          function (entity)
          end,
          new_body(),
          {},
          1)
end
--rails
entity_table.rail =
function(_rail_count,_spatial_difference,_even)
  --[[
  
  ]]--
  local mid_point = 64
  local y_offset = 24
  local size = 128-y_offset*2
  local width = 1
  local spot = mid_point-_spatial_difference/2 + (_rail_count-1)*_spatial_difference
  if not _even then
    spot = mid_point-_spatial_difference + (_rail_count-1)*_spatial_difference
  end
  local position = new_vector(spot,y_offset)
  return new_entity("rail",
  {"rail"},
  position,
  function (entity)
  end,
  function (entity)
    local p = entity.position
    rectfill(p.x,p.y,p.x+width,p.y+size,7)
    rect(p.x-1,p.y,p.x+width+1,p.y+size,1)
  end,
  new_body(),
  {},
  1)
end

--player
entity_table.player =
function(_rails,_segments)
  local w,h = 10,13
  local sprite = new_sprite(0,0,0,2,2)
  local glow_anim = nil
  local glow_sprite = new_sprite()
  local glow_clip = new_clip("6,0,0,2,2|8,0,0,2,2//",2)
  local speed = 1
  local min_rail = 1
  local max_rail = #_rails
  local cur_rail = round(max_rail/2)
  local shield = new_hitbox(1,-1,w-1,h,"shield")
  local chassis = new_hitbox(4,6,3,1,"chassis")
  local rail_transition = nil
  local side_flame_anim = nil
  local transition_speed = 7
  local transition_offset = zero
  --segments
  local segments = split(_segments,"|")
  local cur_segment = 3
  local segment_distance = 10
  local seg_start = 104
  --position
  local position = new_vector(center(_rails[cur_rail].position.x,w),seg_start - (cur_segment*segment_distance)-h)
  --bounce
  local bounce_transition = nil
  local bounce_speed = 4
  local bounce_end = 108
  local bounce_floor = 127
  local bounce_ceil = 112
  --dying
  local dying_anim = nil


  local hitback_anim = nil
  local hitback_start = nil
  local hitback_distance = 50
  local state = "free"
  --[[
  states:
  hold
  free
  attack
  hitstun
  dying
  ]]--
  local state_free = "default"
  --[[
  state_free states:
  default
  transition,
  bounce,
  ]]--
  local last_btn = "a"
  local input = "a"
  local cur_btn = "a"
  local btn_frame = 0
  local btn_delay = 4
  local direction = ""
  --center
  local attack_platform = new_vector(65,100)
  local attack_platform_size = 8
  --energy
  local total_energy = 0
  local total_max_energy = 50
  local energy = {}
  energy.a = 0
  energy.b = 0
  energy.c = 0
  local energy_max = 3
  local energy_pools = {}
  energy_pools.a = new_vector(attack_platform.x,attack_platform.y+attack_platform_size+6)
  energy_pools.b = new_vector(attack_platform.x-attack_platform_size-2,attack_platform.y+attack_platform_size+2)
  energy_pools.c = new_vector(attack_platform.x+attack_platform_size+2,attack_platform.y+attack_platform_size+2)
  local energy_pool_size = attack_platform_size-4
  return new_entity("player",
        {},
        position,
        function (entity)
          local state = entity.model.state
          if state == "hold" then
            --nothing
          elseif state == "free" then
            --input data
            if btn(4) and not btn(5) then
              cur_btn = "b"
            elseif btn(5) and not btn(4) then
              cur_btn = "c"
            else
              cur_btn = "a"
            end

            if btnp(2) and not btn(3) then
              direction = "up"
            elseif btnp(3) and not btn(2) then
              direction = "down"
            else
              direction = ""
            end

            --[[
              if the current input is the last input, the button has been held another frame,
              if the btn_frame has reached the button delay, the input is changed.
            ]]--
            if cur_btn == last_btn and cur_btn != input then
              btn_frame += 1
            else
              btn_frame = 0
            end

            if btn_frame >= btn_delay then
              input = cur_btn
              btn_frame = 0
            end
            last_btn = cur_btn

            if input == "b" then
              sprite.n = 2
              entity.model.defense_type = "b"
            elseif input == "c" then
              sprite.n = 4
              entity.model.defense_type = "c"
            elseif input == "a" then
              sprite.n = 0
              entity.model.defense_type = "a"
            end
            --end input data
            --verticle
            --[[
            --up
            if direction == "up" and entity.position.y > 23 then
              transition_offset = new_vector(0,-speed)
            end
            --down
            if direction == "down" then
              transition_offset = new_vector(0,speed)
            end
            ]]
            --bounce animation
            if bounce_transition then
              coresume(bounce_transition,transition_offset)
              transition_offset = new_vector(0,0)
            end
            if not bounce_transition or costatus(bounce_transition) == "dead" then
              bounce_transition = nil
            end
            --free_states
            if state_free == "default" then
              if btnp(2) then
                cur_segment = clamp(cur_segment+1,0,#segments-1)
              elseif btnp(3) then
                cur_segment = clamp(cur_segment-1,0,#segments-1)
              elseif btn(0) and not btn(1) and cur_rail-1 >= min_rail then
                cur_rail -= 1
                rail_transition = vector.animation.movetoinframes(entity.position,new_vector(center(_rails[cur_rail].position.x,w),entity.position.y),transition_speed)
                side_flame_anim = new_animation(new_clip("",1,
                  function (_sample)
                    local x0,x1,y = entity.position.x-sin(_sample/20)*8+w,entity.position.x+w-2,entity.position.y
                    local c
                    if entity.model.defense_type == "a" then
                      c = _sample <= 5 and 12 or 2
                    elseif entity.model.defense_type == "b" then
                      c = _sample <= 5 and 9 or 2
                    else
                      c = _sample <= 5 and 11 or 2
                    end
                    rectfill(x0,y+1,x1,y+11,c)
                  end, 10))
                  state_free = "htransition"
              --right transition
              elseif btn(1) and not btn(0) and cur_rail+1 <= max_rail then
                cur_rail += 1
                rail_transition = vector.animation.movetoinframes(entity.position,new_vector(center(_rails[cur_rail].position.x,w),entity.position.y),transition_speed)
                side_flame_anim = new_animation(new_clip("",1,
                  function (_sample)
                    local x0,x1,y = entity.position.x+sin(_sample/20)*8,entity.position.x+2,entity.position.y
                    local c
                    if entity.model.defense_type == "a" then
                      c = _sample <= 5 and 12 or 2
                    elseif entity.model.defense_type == "b" then
                      c = _sample <= 5 and 9 or 2
                    else
                      c = _sample <= 5 and 11 or 2
                    end
                    rectfill(x0,y+1,x1,y+11,c)
                  end, 10))
                  state_free = "htransition"
              end
              entity.position.y += transition_offset.y
            end
            if state_free == "htransition" then
              --transition animation
              if rail_transition then
                coresume(rail_transition,transition_offset)
              end
              if not rail_transition or costatus(rail_transition) == "dead" then
                rail_transition = nil
                state_free = "default"
              end
            end
            if state_free == "vtransition" then
              if segment_transition then
                coresume(segment_transition)
              end
            end
            --bounce bot
            if in_range(entity.position.y,bounce_floor,bounce_ceil) then
              bounce_transition = vector.animation.movetoinframes(entity.position,new_vector(entity.position.x,bounce_end),bounce_speed)
            end
            --switch to attack
            if total_energy >= total_max_energy then
              --cur_rail = 0
              rail_transition = vector.animation.movetoinframes(entity.position,attack_platform - new_vector(w/2-2,h/2-1),transition_speed)
              entity.model.state = "attack"
            end
            transition_offset = zero
            entity.position.y = seg_start - (cur_segment * segment_distance) - h
          elseif state == "hitstun" then
            if hitback_anim then
              coresume(hitback_anim,zero)
              if entity.position.y > bounce_floor then
                hitback_anim = nil
                entity.model.state = "dying"
              elseif costatus(hitback_anim) == "dead" then
                hitback_anim = nil
                entity.model.state = "free"
              end
            end
          elseif state == "attack" then
          elseif state == "dying" then
          end
        end,
        function (entity)
          --attack_platform
          --[[
          if total_energy >= total_max_energy then
            circfill(attack_platform.x,attack_platform.y,attack_platform_size,2)
            circfill(attack_platform.x,attack_platform.y,attack_platform_size-1,15)
            rectfill(attack_platform.x-4,attack_platform.y+1,attack_platform.x-4,attack_platform.y-1,14)
            rectfill(attack_platform.x+4,attack_platform.y+1,attack_platform.x+4,attack_platform.y-1,14)
          else
            circ(attack_platform.x,attack_platform.y,attack_platform_size,2)
            circfill(attack_platform.x,attack_platform.y,lerp(0,attack_platform_size,total_energy/total_max_energy),1)
          end
          ]]
          local x,y = entity.position.x,entity.position.y
          if side_flame_anim then
            coresume(side_flame_anim)
          end
          sprite:draw(entity.position)
          --input delay feedback
          if btn_frame > 0 then
            rectfill(x+5,y+7,x+6,y+7-flr(lerp(-1,4,btn_frame/btn_delay)),bullet_color[cur_btn])
          end
          --energy pools
          circ(energy_pools.a.x,energy_pools.a.y,energy_pool_size,bullet_color.complement["a"])
          circ(energy_pools.b.x,energy_pools.b.y,energy_pool_size,bullet_color.complement["b"])
          circ(energy_pools.c.x,energy_pools.c.y,energy_pool_size,bullet_color.complement["c"])
          circfill(energy_pools.a.x,energy_pools.a.y,lerp(0,energy_pool_size-1,energy.a/energy_pool_size),bullet_color["a"])
          circfill(energy_pools.b.x,energy_pools.b.y,lerp(0,energy_pool_size-1,energy.b/energy_pool_size),bullet_color["b"])
          circfill(energy_pools.c.x,energy_pools.c.y,lerp(0,energy_pool_size-1,energy.c/energy_pool_size),bullet_color["c"])
          --glow
          if glow_anim then
            coresume(glow_anim)
            glow_sprite:draw(entity.position)
            if costatus(glow_anim) == "dead" then
              glow_anim = nil
            end
          end
        end,
        new_body({shield,chassis},
        function (entity,coll,e_hitbox,coll_hitbox)
          if coll.name == "bullet_manager" then
            if e_hitbox.name == "shield" then
              if entity.model.defense_type == coll_hitbox.name then
                energy[coll_hitbox.name] = clamp(energy[coll_hitbox.name]+1,0,energy_pool_size)
                glow_anim = new_animation(glow_clip,glow_sprite)
              end
            elseif e_hitbox.name == "chassis" then
              --hitback_anim = vector.animation.movetoinframes(entity.position,new_vector(center(_rails[cur_rail].position.x,w),entity.position.y + hitback_distance),5)
              cur_segment = clamp(cur_segment-1,0,#segments-1)
              entity.position.y = seg_start - (cur_segment * segment_distance) - h
              rail_transition = nil
            end
          end
        end),
        {defense_type="a",h=h,w=h,state=state,attack_platform=attack_platform,energy_pools=energy_pools},
        1
        )
  end
--enemy
entity_table.enemy =
function()
  local w,h = 16,16
  local sprite = new_sprite(128,0,0,2,2)
  local hands = new_sprite(160,0,0,2,1)
  local position = new_vector(center(65,w),-h/2+10)
  local hands_position = new_vector(0,h)
  local start_position = new_vector(position.x,position.y)
  local hitbox = new_hitbox(0,0,w-1,h-1)
  local bottom_sway = position.y + h/4
  local top_sway = position.y-2
  local sway_t = 0
  local sway_down = true
  return new_entity("enemy",
        {"enemy"},
        position,
        function (entity)
          if sway_down then
            position:lerp(start_position,new_vector(position.x,bottom_sway),sway_t)
          else
            position:lerp(start_position,new_vector(position.x,top_sway),sway_t)
          end
          sway_t += .01
          if sway_t >= 1 then
            sway_t = 0
            sway_down = not sway_down
            start_position = new_vector(position.x,position.y)
          end
        end,
        function (entity)
          sprite:draw(entity.position)
          hands:draw(entity.position + hands_position)
        end,
        new_body({hitbox},
        function (entity,coll,e_hitbox,coll_hitbox)
        end),
        {},
        4
        )
  end
--scenes
scene_table = {}
scene_table.init =
function ()
  return new_scene(function ()
                  
                    local bullet_pattern = 
                    'a|||,|||,|||,a|||,|||,|||,a|||,|||,|||,|||,|||,|||,|||,|||,|||,b|||,|||,|||,b|||,|||,|||,b|||,|||,|||,|||,|||,|||,|||,|||,|||,c|||,|||,|||,c|||,|||,|||,c|||,|||,|||,|||,|||,|||,|||,|||,|||,a|||,|||,|||,a|||,|||,|||,a|||,|||,|||,|||,|||,|||,|||,|||,|||,a|||,|||,|||,b|||,|||,|||,c|||'
                    --'b||,||,b||,||,a|w|,|w|,||,||,||a,||,||b,||,||c,||,c||,c||,c||,|w|,||,||,||a,||b,||c'
                    local segments = "w|w|w|w|w|w|w|w"
                    local rails = {}
                    for i=1,2 do
                      add(rails,game.add_entity(entity_table.rail(i,40,true)))
                    end
                    local player = game.add_entity(entity_table.player(rails,segments))
                    game.add_entity(entity_table.background())
                    game.add_entity(entity_table.enemy())
                    game.add_entity(entity_table.bullet_manager(rails,bullet_pattern,player))
                  end,
                  nil,
                  function (scene)
                  end,
                  function (scene)
                    local draw_ui_box = function(_x,_y,_width,_height,_c)
                      local x = _x - _width/2
                      local y = _y - _height/2
                      rect(x,y,x+_width,y+_height,7)
                      rect(x+1,y+1,x+_width-1,y+_height-1,1)
                      rect(x+-1,y+-1,x+_width+1,y+_height+1,1)
                    end
                    local ui_size = 81
                    draw_ui_box(63,63,lerp(0,ui_size,scene.frame/20),ui_size)
                    if scene.frame >= 25 then
                      print_center("protoprobe",62,31,10)
                      print_center("iteration  #0",62,42,7)
                    end
                  end,
                  {ui_frame=0})
end

extensions = {}
--pico
function _init()
  --initialize three global objects
  --data: object which contains entity, scene, and starting_scene.
  --extensions: object which contains singular services to be called on
  --new_game: object which operates the game
  game = new_game(scene_table.init())
  game.start()
end
function _update60()
  game.update()
end
function _draw()
  game.draw()
end

__gfx__
0000cccc0000000000009999000000000000bbbb0000000000007777000000000000000000000000111111111111111100000000000000000000000000000000
000cc77cc00000000009977990000000000bb77bb000000000070000700000000000777700000000117777777777777700000000000000000000000000000000
00ce7cc7ec000000009e7997e900000000be7bb7eb00000000700000070000000000700700000000177111111111111100000000000000000000000000000000
00ce2dd2ec000000009e4dd4e900000000be3dd3eb00000000700000070000000070000007000000171100000000000000000000000000000000000000000000
0ccedccdecc00000099ed99de99000000bbedbbdebb0000007000000007000000070000007000000171000000000000000000000000000000000000000000000
0c72dccd27c000000974d99d479000000b73dbbd37b0000007000000007000000070000007000000171000000000000000000000000000000000000000000000
0c7cdccdc7c000000979d99d979000000b7bdbbdb7b0000007000000007000000070000007000000171000000000000000000000000000000000000000000000
0c72dccd27c000000974d99d479000000b73dbbd37b0000007000000007000000070000007000000171000000000000000000000000000000000000000000000
0cce2dd2ecc00000099e4dd4e99000000bbe3dd3ebb0000007000000007000000070000007000000171000000000000000000000000000000000000000000000
00ce7cc7ec000000009e7997e900000000be7bb7eb00000000700000070000000070700707000000171000000000000000000000000000000000000000000000
00cec77cec000000009e9779e900000000beb77beb00000000700000070000000000777700000000171000000000000000000000000000000000000000000000
000cccccc00000000009999990000000000bbbbbb000000000077777700000000000000000000000171000000000000000000000000000000000000000000000
0000cccc0000000000009999000000000000bbbb0000000000007777000000000000000000000000171000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000171000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000171000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000171000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065177156
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065177156
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065177156
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065177156
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065177156
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065177156
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065177156
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065177156
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005577550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051111115
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051111115
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065111156
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066555566
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666
00000000000000000000000000000000812882180028820081288218000000008128821800000000812882180000000000000000000000000000000000000000
0dccd00000dd00000000000000000000188888810888888018888881000000001888888100000000188888810000000000000000000000000000000000000000
dccccd000dccd0000000000000000000288118820881188028811882000000002881188200000000288118820000000000000000000000000000000000000000
cc77cc000c77c0000000000000000000881881880818818088188188000000008818818800000000881881880000000000000000000000000000000000000000
cc77cc000c77c0000000000000000000881881880818818088188188000000008818818800000000881881880000000000000000000000000000000000000000
dccccd000dccd0000000000000000000288118820881188028811882000000002881188200000000288118820000000000000000000000000000000000000000
0dccd00000dd00000000000000000000818888180188881081888818000000008188881800000000818888180000000000000000000000000000000000000000
00000000000000000000000000000000881881880018810088188188000000008818818800000000881881880000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04994000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999400049940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99779900097790000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99779900097790000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999400049940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04994000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03bb3000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbb30003bb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb77bb000b77b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb77bb000b77b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbb30003bb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03bb3000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88211288000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
81888818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28811882000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18188181000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18188181000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28811882000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
81888818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88211288000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70075000000570070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77577777777775770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
75777771177777570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05777712217777500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77711771177117770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
57122177771221750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07711775577117700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777708807777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777522825777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07775008800577700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07775228222577700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07750008800057700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07752222822257700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05750008800057500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00577750057775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
75000000000000570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77500000000005770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000065556000505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000
00000000050005000505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066600000666000
0000000005000500050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000c0c000
000555555500050005050555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c000000c0000
0005000005000500050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000c0c000
000500000655560005055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c000000c0000
00050000005550000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066600000666000
00050000050505000555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000
00666000666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066600000666000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000b0b000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0b000000b0000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000b0b000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0b000000b0000
00666000666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066600000666000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066600000666000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009000000909000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090900000090000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009000000909000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090900000090000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066600000666000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066600000666000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000080000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080800000888000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080800000888000
00050000050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000080000
00555000555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066600000666000
00555000555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
00000000000000000000e30f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000c1cd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000cdd1cd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000cde1cd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000cdf1cdcdcd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

