class RadioactiveGoat extends GGMutator;

struct RadioactiveActorItem
{
	var Actor act;
	var int radiationCount;
	//var ParticleSystemComponent psc;
	var float totalTime;
	var RadioactiveActor radAct;
};

var ParticleSystem radParticleTemplate;

var array<RadioactiveActorItem> mRadioactiveActors;
var array<Actor> actorsToIrradiate;

var float totalTime;
var float irradiationTime;
var float irradiateRadius;

var int maxRadiationCount;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if(goat != none)
	{
		IrradiateActor(goat);
		mRadioactiveActors[GetRadioactiveActorIndex(goat)].radiationCount = -1000000000;//Make sure the goat can irradiate forever
	}
}

function int GetRadioactiveActorIndex(Actor act)
{
	return mRadioactiveActors.Find('act', act);
}

function int CreateRadioactiveActor(Actor newAct)
{
	local RadioactiveActorItem newFA;

	newFA.act=newAct;
	mRadioactiveActors.AddItem(newFA);

	return mRadioactiveActors.Length-1;
}

function RemoveRadioactiveActor(int index)
{
	mRadioactiveActors.Remove(index, 1);
}

event Tick( float deltaTime )
{
	local int index;
	local Actor actToIrradiate;
	local GGNPCMMOEnemy tmpMMOEmeny;
	local GGNpcZombieGameModeAbstract tmpZombie;

	super.Tick( deltaTime );
	// Clean irradiated actors list (remove destroyed items)
	for(index = 0 ; index < mRadioactiveActors.Length ; index = index)
	{
		if(mRadioactiveActors[index].act == none || mRadioactiveActors[index].act.bPendingDelete)
		{
			UnIrradiate(index);
		}
		else
		{
			index++;
		}
	}
	// Irradiate exploded actors
	foreach actorsToIrradiate(actToIrradiate)
	{
		IrradiateActor(actToIrradiate);
	}
	actorsToIrradiate.Length=0;
	//Irradiate nearby actors periodically and take damages
	for(index = 0 ; index < mRadioactiveActors.Length ; index++)
	{
		mRadioactiveActors[index].totalTime = mRadioactiveActors[index].totalTime + deltaTime;
		if(mRadioactiveActors[index].totalTime < irradiationTime)
			continue;
		//WorldInfo.Game.Broadcast(self, "Process radioactivity for " $ mRadioactiveActors[index].act);
		mRadioactiveActors[index].totalTime = 0.f;
		//Take radiation damages
		if(GGPawn(mRadioactiveActors[index].act) != none)
		{
			mRadioactiveActors[index].act.TakeDamage(int( RandRange( 1, 5 ) ) * 100, none, mRadioactiveActors[index].act.Location, vect(0,0,0), class'GGDamageTypeRadioactivity');
		}
		//Random chance for breakable actors to be broken
		if(GGApexDestructibleActor(mRadioactiveActors[index].act) != none && Rand(100) == 0)
		{
			mRadioactiveActors[index].act.TakeDamage(10000000, none, mRadioactiveActors[index].act.Location, vect(0, 0, 0), class'GGDamageTypeAbility');
		}
		//Random chance for explosive actors to explode/breakabke kactors to be broken
		if(GGKActor(mRadioactiveActors[index].act) != none && Rand(100) == 0)
		{
			mRadioactiveActors[index].act.TakeDamage(10000000, none, mRadioactiveActors[index].act.Location, vect(0, 0, 0), class'GGDamageTypeAbility');
		}
		tmpMMOEmeny=GGNPCMMOEnemy(mRadioactiveActors[index].act);
		if(tmpMMOEmeny != none)
		{
			tmpMMOEmeny.TakeDamageFrom( int( RandRange( 1, 5 ) ),,class'GGDamageTypeExplosiveActor' );
		}
		tmpZombie=GGNpcZombieGameModeAbstract(mRadioactiveActors[index].act);
		if(tmpZombie != none)
		{
			tmpZombie.TakeDamage( int( RandRange( 1, 5 ) ), none, tmpZombie.Location, vect(0,0,0), class'GGDamageTypeZombieSurvivalMode' );
		}

		//Irradiate nearby actors if necessary(stop after 2 actors irradiated for performance reasons)
		if(mRadioactiveActors[index].radiationCount < maxRadiationCount)
		{
			if(Rand(10) == 0)//Random chance to irradiate one nearby actor
			{
				foreach mRadioactiveActors[index].act.OverlappingActors(class'Actor', actToIrradiate, irradiateRadius, mRadioactiveActors[index].act.Location)
				{
					if(IrradiateActor(actToIrradiate))
					{
						mRadioactiveActors[index].radiationCount++;
						break;
					}
				}
			}
		}
	}
}

function OnExplosion( Actor explodedActor )
{
	if(GetRadioactiveActorIndex(explodedActor) != INDEX_NONE && GGExplosiveActorWreckable(explodedActor) != none)
	{
		actorsToIrradiate.AddItem(explodedActor);
	}
}

function bool IsActorAllowed(Actor targetAct)
{
	return GGPawn(targetAct) != none
	|| GGKactor(targetAct) != none
	|| GGSVehicle(targetAct) != none
	|| GGSVehicle(targetAct) != none
	|| GGInterpActor(targetAct) != none
	|| GGApexDestructibleActor(targetAct) != none;
}

function bool IrradiateActor(Actor targetAct)
{
	//local bool isAttached;
	//local GGPawn irradiatedPawn;
	local int radIndex;
	//local ParticleSystemComponent radParticle;
	local RadioactiveActor radAct;

	if(targetAct == none || GetRadioactiveActorIndex(targetAct) != INDEX_NONE || !IsActorAllowed(targetAct))
	{
		return false;
	}
	radIndex = CreateRadioactiveActor(targetAct);

	/*
	irradiatedPawn = GGPawn(targetAct);
	if(irradiatedPawn != none)
	{
		if(!IsZero(irradiatedPawn.mesh.GetBoneLocation('Spine_01')))
		{
			radParticle = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(radParticleTemplate, irradiatedPawn.mesh, 'Spine_01');
			isAttached=true;
		}
		else if(!IsZero(irradiatedPawn.mesh.GetBoneLocation('Root')))
		{
			radParticle = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(radParticleTemplate, irradiatedPawn.mesh, 'Root');
			isAttached=true;
		}
	}
	if(!isAttached)
	{
		radParticle = WorldInfo.MyEmitterPool.SpawnEmitter(radParticleTemplate, targetAct.Location, targetAct.Rotation, targetAct);
	}
	mRadioactiveActors[radIndex].psc = radParticle;
	*/
	radAct = Spawn(class'RadioactiveActor');
	radAct.IrradiateTarget(targetAct);
	mRadioactiveActors[radIndex].radAct = radAct;

	return true;
}

function UnIrradiateActor(Actor targetAct)
{
	local int radioactiveActorIndex;

	radioactiveActorIndex=GetRadioactiveActorIndex(targetAct);
	if(targetAct == none || radioactiveActorIndex == INDEX_NONE)
	{
		return;
	}

	UnIrradiate(radioactiveActorIndex);
}

function UnIrradiate(int index)
{
	//local ParticleSystemComponent oldRadParticle;

	if(index == INDEX_NONE)
		return;

	/*
	oldRadParticle = mRadioactiveActors[index].psc;
	oldRadParticle.DeactivateSystem();
	oldRadParticle.KillParticlesForced();
	*/
	if(mRadioactiveActors[index].radAct != none)
		mRadioactiveActors[index].radAct.StopRadiation();

	RemoveRadioactiveActor(index);
}


DefaultProperties
{
	//radParticleTemplate = ParticleSystem'Heist_Effects_01.Effects.Effects_Glow'
	radParticleTemplate = ParticleSystem'Goat_Effects.Effects.Effects_Repulsive_01'

	irradiationTime = 1.f
	irradiateRadius = 200.f
	maxRadiationCount = 2
}