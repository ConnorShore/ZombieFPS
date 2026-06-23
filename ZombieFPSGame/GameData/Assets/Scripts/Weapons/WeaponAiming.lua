local WeaponAiming = {}

WeaponAiming.ADS_Speed = 15.0
WeaponAiming.AimNodeRef = EntityRef()
WeaponAiming.CrosshairRef = EntityRef()
WeaponAiming.ADSPositionOffset = Vector3f.new(0, 0, 0)
WeaponAiming.ADSCameraViewOffset = Vector3f.new(0.0, 0.0, -0.2)
WeaponAiming.CameraSocketRef = EntityRef()
WeaponAiming.CameraSocketFallbackOffset = Vector3f.new(0.33, -0.41661298, -0.6143637)
WeaponAiming.CameraRef = EntityRef()
WeaponAiming.DebugADSLogging = false

local function ResolveWeaponPrefabRoot(entity)
    local current = entity
    while current and current:IsValid() do
        if current:ContainsComponent("PrefabComponent") then
            return current
        end

        if current:IsRootParent() then
            break
        end

        current = current:GetParent()
    end

    return entity:GetRootParent()
end

function WeaponAiming:OnCreate(entity)
    self.HipPosition = Vector3f.new(0, 0, 0)
    self.IsAiming = false
    self.RootScale = Vector3f.new(1, 1, 1)
    
    self.AimNode = Scene.GetEntityByUUID(self.AimNodeRef)
    if not self.AimNode:IsValid() then
        Log.Warn("WeaponAiming: Cannot find ADS_Node!")
    end

    self.WeaponRoot = ResolveWeaponPrefabRoot(entity)
    if self.WeaponRoot and self.WeaponRoot:IsValid() then
        local rootTransform = self.WeaponRoot:GetComponent("TransformComponent")
        if rootTransform then
            self.RootScale = rootTransform.Scale
        end
    end

    self.Crosshair = Scene.GetEntityByUUID(self.CrosshairRef)

    self.Camera = nil
    local cameraOk, cameraResolved = pcall(function()
        return Scene.GetEntityByUUID(self.CameraRef)
    end)
    if cameraOk and cameraResolved and cameraResolved:IsValid() then
        self.Camera = cameraResolved
    end

    -- CameraSocketRef can be absent or stale on some prefabs/scenes during migration.
    -- Resolve defensively so pickup never crashes runtime.
    self.CameraSocket = nil
    local ok, resolved = pcall(function()
        return Scene.GetEntityByUUID(self.CameraSocketRef)
    end)
    if ok and resolved and resolved:IsValid() then
        self.CameraSocket = resolved
    else
        Log.Warn("WeaponAiming: CameraSocketRef unresolved, using CameraSocketFallbackOffset")
    end
end

local function FormatVec3(value)
    if not value then
        return "(nil)"
    end

    return string.format("(%.4f, %.4f, %.4f)", value.x or 0.0, value.y or 0.0, value.z or 0.0)
end

function WeaponAiming:OnUpdate(entity, delta)
    local transform = entity:GetComponent("TransformComponent")
    local rootScale = self.RootScale

    self.WeaponRoot = ResolveWeaponPrefabRoot(entity)
    if self.WeaponRoot and self.WeaponRoot:IsValid() then
        local rootTransform = self.WeaponRoot:GetComponent("TransformComponent")
        if rootTransform then
            rootScale = rootTransform.Scale
            self.RootScale = rootScale
        end
    end
    
    self.IsAiming = Input.IsMouseButtonPressed(MouseButton.Right) and self.AimNode:IsValid()
    
    local targetPosition = self.HipPosition
    
    if self.IsAiming then
        local aimNodeTransform = self.AimNode:GetComponent("TransformComponent")
        local socketOffset = self.CameraSocketFallbackOffset
        if self.CameraSocket and self.CameraSocket:IsValid() then
            socketOffset = self.CameraSocket:GetComponent("TransformComponent").Position
        end

        local desiredOffset = self.ADSCameraViewOffset - aimNodeTransform.Position - socketOffset + self.ADSPositionOffset

        targetPosition = Vector3f.new(
            desiredOffset.x / (rootScale.x ~= 0 and rootScale.x or 1),
            desiredOffset.y / (rootScale.y ~= 0 and rootScale.y or 1),
            desiredOffset.z / (rootScale.z ~= 0 and rootScale.z or 1)
        )

        if self.DebugADSLogging then
            local cameraWorld = Vector3f.new(0, 0, 0)
            if self.Camera and self.Camera:IsValid() then
                cameraWorld = self.Camera:GetComponent("TransformComponent").WorldPosition
            end

            Log.Info(
                "WeaponAiming ADS Debug | CameraWorld=" .. FormatVec3(cameraWorld) ..
                " AimNodeLocal=" .. FormatVec3(aimNodeTransform.Position) ..
                " SocketOffset=" .. FormatVec3(socketOffset) ..
                " DesiredOffset=" .. FormatVec3(desiredOffset) ..
                " FinalTarget=" .. FormatVec3(targetPosition) ..
                " CurrentLocal=" .. FormatVec3(transform.Position) ..
                " RootScale=" .. FormatVec3(rootScale)
            )
        end
        
        if self.Crosshair:IsValid() then self.Crosshair:SetActive(false) end
    else
        if self.Crosshair:IsValid() then self.Crosshair:SetActive(true) end
    end
    
    transform.Position = Math.Lerp(transform.Position, targetPosition, delta * self.ADS_Speed)
end

return WeaponAiming