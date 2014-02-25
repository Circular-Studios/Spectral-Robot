module Scripts.actions;

enum TargetType
{
	EnemyUnit,
	AlliedUnit,
	Ground
}

enum TargetArea
{
	Point,
	Line,
	Square,
	Circle,
}

class Ability
{
private:
	TargetType targetType;
	TargetArea targetArea;
	int range;
	int radius; // Different uses for different Areas
public:
	this ()
	{
		// Constructor
	}
}
