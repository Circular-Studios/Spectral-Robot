module effect;
import game, unit;
import core, utility;

shared class IEffect 
{
	int diff;
	int duration;
	bool reset;
	int originalValue;

	void use( shared Unit unit ) { }
}

shared class Effect( string prop ) : IEffect
{
	enum Prop = prop;
	
	this( int diff, int duration = 0, bool reset = false, int originalValue = 0 )
	{
		this.diff = diff;
		this.duration = duration;
		this.reset = reset;
		this.originalValue = originalValue;
	}
	
	override void use( shared Unit unit )
	{
		logInfo("effect used");
		duration--;
		unit.reEffect!prop( diff, duration, reset, originalValue );
		
		// check if the effect has run its course
		if( duration <= 0 ) this.destroy();
	}
}

