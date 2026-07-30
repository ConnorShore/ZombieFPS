local CharacterMovement = {}

CharacterMovement.WalkSpeed = 5.0
CharacterMovement.SprintSpeed = 8.0

function CharacterMovement:OnCreate(entity)
    self.Sprinting = false;

    -- Component handles are safe to cache for the entity's lifetime (they re-resolve the
    -- live component internally), so fetch them once here instead of every frame in OnUpdate.
    self.controller = entity:GetComponent("CharacterControllerComponent")
    self.transform = entity:GetComponent("TransformComponent")

    self.controller.WalkSpeed = self.WalkSpeed
end

function CharacterMovement:OnUpdate(entity, delta)
    local controller = self.controller
    local transform = self.transform

    local forward = transform:GetForward()
    local right = transform:GetRight()
    
    -- Player Controller Movement
    local moveDir = Vector3f.new(0.0, 0.0, 0.0)

    local speed = self.WalkSpeed
    if Input.IsKeyPressed(KeyCode.LeftShift) then
        self.Sprinting = true;
        speed = self.SprintSpeed;
    else
        self.Sprinting = false;
        speed = self.WalkSpeed;
    end

    -- Strafing
    if Input.IsKeyPressed(KeyCode.A) then 
        moveDir = moveDir - right
    elseif Input.IsKeyPressed(KeyCode.D) then 
        moveDir = moveDir + right
    end

    -- Forward / Backward
    if Input.IsKeyPressed(KeyCode.W) then 
        moveDir = moveDir + forward
    elseif Input.IsKeyPressed(KeyCode.S) then 
        moveDir = moveDir - forward
    end
    
    -- Normalize so diagonal movement isn't 1.4x faster!
    if Math.Length(moveDir) > 0 then
        moveDir = Math.Normalize(moveDir);
    end
    
    -- Move using the Character Controller
    controller:Move(moveDir * speed * delta)
    
    -- Jumping
    if Input.IsKeyPressed(KeyCode.Space) and controller.IsGrounded then
        controller:Jump()
    end
end

return CharacterMovement