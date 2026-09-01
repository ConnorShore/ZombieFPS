local CharacterMovement = {}

CharacterMovement.WalkSpeed = 5.0
CharacterMovement.SprintSpeed = 8.0

function CharacterMovement:OnCreate(entity)
    self.Sprinting = false;
    self.LockMovement = false;

    -- Component handles are safe to cache for the entity's lifetime (they re-resolve the
    -- live component internally), so fetch them once here instead of every frame in OnUpdate.
    self.controller = entity:GetComponent("CharacterControllerComponent")
    self.transform = entity:GetComponent("TransformComponent")

    self.controller.WalkSpeed = self.WalkSpeed

    EventManager.Subscribe("OnLockMovement", function()
        self.LockMovement = true
    end)
    EventManager.Subscribe("OnUnlockMovement", function()
        self.LockMovement = false
    end)
end

function CharacterMovement:OnUpdate(entity, delta)
    if self.LockMovement then
        return
    end

    local controller = self.controller
    local transform = self.transform

    local forward = transform:GetForward()
    local right = transform:GetRight()
    
    local speed = self.WalkSpeed
    if Input.IsActionDown("Sprint") then
        self.Sprinting = true;
        speed = self.SprintSpeed;
    else
        self.Sprinting = false;
        speed = self.WalkSpeed;
    end

    -- Read the sticks as axes, the way MouseLook does: four button reads would quantise a stick
    -- to the diagonals, since pushing it "straight" forward still leaves a little on the X axis.
    -- A key still reports a full 1.0, so the keyboard is unchanged.
    local move = Input.GetAxis2D("MoveLeft", "MoveRight", "MoveBackward", "MoveForward")
    local moveDir = (right * move.x) + (forward * move.y)

    -- Only clamp when the input overshoots - keyboard diagonals, or a stick in its corner - so a
    -- gentle lean on the stick keeps its slower speed instead of snapping to a full walk.
    if Math.Length(moveDir) > 1.0 then
        moveDir = Math.Normalize(moveDir);
    end

    -- Move using the Character Controller
    controller:Move(moveDir * speed * delta)
    
    -- Jumping
    if Input.IsActionPressed("Jump") and controller.IsGrounded then
        controller:Jump()
    end
end

return CharacterMovement