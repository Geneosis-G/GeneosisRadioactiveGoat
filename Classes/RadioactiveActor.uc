class RadioactiveActor extends Actor;

var ParticleSystemComponent radParticle;

function IrradiateTarget(Actor target)
{
	local Actor irradiatedActor;
	local GGPawn irradiatedPawn;
	local bool isAttached;
	//WorldInfo.Game.Broadcast(self, "elecIt(" $ target $ ")");
	irradiatedActor=target;
	irradiatedPawn=GGPawn(irradiatedActor);
	SetLocation(irradiatedActor.Location);
	SetBase(irradiatedActor);

	//WorldInfo.Game.Broadcast(self, radParticle $ " attached to " $ irradiatedActor);
	if(irradiatedPawn != none)
	{
		if(!IsZero(irradiatedPawn.mesh.GetBoneLocation('Spine_01')))
		{
			irradiatedPawn.mesh.AttachComponentToSocket(radParticle, 'Spine_01');
			isAttached=true;
		}
		else if(!IsZero(irradiatedPawn.mesh.GetBoneLocation('Root')))
		{
			irradiatedPawn.mesh.AttachComponentToSocket(radParticle, 'Root');
			isAttached=true;
		}
	}
	if(!isAttached)
	{
		AttachComponent(radParticle);
	}
	radParticle.ActivateSystem(true);
}

function StopRadiation()
{
	if( radParticle != none )
	{
		radParticle.DetachFromAny();
		radParticle.DeactivateSystem();
		radParticle.KillParticlesForced();
	}

	Destroy();
}

DefaultProperties
{
	bStatic=false
	bNoDelete=false

	Begin Object class=ParticleSystemComponent Name=ParticleSystemComponent0
        Template=ParticleSystem'Goat_Effects.Effects.Effects_Repulsive_01'
		bAutoActivate=true
		bResetOnDetach=true
	End Object
	radParticle=ParticleSystemComponent0
}