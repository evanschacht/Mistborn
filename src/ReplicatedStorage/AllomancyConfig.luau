-- Aerial defaults. Higher gravity falls faster; all forces scale with character mass.
return {
 EffectiveGravityMultiplier=0.8, -- 1 = normal gravity; lower values lengthen the arc.
 GravityTransitionTime=0.3, -- Higher = gentler transitions to/from reduced gravity.
 AirAcceleration=28, -- Higher = stronger camera-relative horizontal steering.
 AirTurnStrength=0.65, -- Higher = more control at speed; never changes velocity instantly.
 MaximumHorizontalSpeed=140, -- Steering/boost soft ceiling; existing momentum is not clamped.
 AirBoostSpeed=28, -- Horizontal velocity added by one boost.
 AirBoostUpwardSpeed=16, -- Upward velocity added by one boost.
 AirBoostCooldown=1.2, -- Minimum seconds between boosts, also enforced on the server.
 DoubleTapWindow=0.25, -- Maximum seconds between taps of the same direction.
 OneBoostPerAirtime=true, -- Set false to allow repeated boosts subject to cooldown.
 CharacterTiltAmount=10, -- Maximum visual tilt in degrees; does not tilt the physics root.
 CharacterTiltResponsiveness=8, -- Higher = faster visual lean/landing recovery.
 GroundCoastDrag=2.3, -- Higher = shorter ground slide; no drag is applied in the air.
}
